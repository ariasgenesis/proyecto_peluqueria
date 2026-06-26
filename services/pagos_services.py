from models.pagos_model import PagoModel
from services.base_service import BaseCrudService, ServiceError
from services.inventario_services import InventarioService, decimal_or_zero


class PagoService(BaseCrudService):
    model = PagoModel
    schema = {
        'factura_id': {'type': 'int', 'required': True, 'min': 1},
        'metodo': {'type': 'str', 'required': True, 'enum': ['efectivo', 'transferencia', 'tarjeta', 'wompi'], 'lower': True},
        'estado': {'type': 'str', 'default': 'completado', 'enum': ['pendiente', 'completado', 'cancelado'], 'lower': True},
        'fecha': {'type': 'date', 'required': True},
        'monto': {'type': 'decimal', 'required': True, 'min': 0.01},
        'referencia': {'type': 'str', 'max': 255},
        'transaccion_id': {'type': 'str', 'max': 255}
    }

    def _actualizar_factura_por_pagos(self, cursor, factura_id, user_id):
        cursor.execute(
            "SELECT fac_total, fac_estado, fac_cita_id, fac_anticipo, fac_reserva_id FROM facturas WHERE fac_id = %s FOR UPDATE",
            (factura_id,),
        )
        factura = cursor.fetchone()
        if not factura:
            raise ServiceError('Factura no encontrada', 404)
        total, estado_actual, _cita_id, anticipo, reserva_id = factura
        if estado_actual == 'cancelada':
            raise ServiceError('No se pueden registrar pagos sobre una factura cancelada', 409)
        cursor.execute(
            "SELECT COALESCE(SUM(pag_monto), 0) FROM pagos WHERE pag_factura_id = %s AND pag_estado = 'completado'",
            (factura_id,),
        )
        pagado = decimal_or_zero(anticipo) + decimal_or_zero(cursor.fetchone()[0])
        total = decimal_or_zero(total)
        if pagado > total:
            raise ServiceError('El total pagado no puede superar el total de la factura', 409)
        saldo = total - pagado
        if saldo == 0:
            cursor.execute(
                "UPDATE facturas SET fac_estado = 'pagada', fac_anticipo = %s, fac_saldo_pendiente = 0, "
                "fac_modificada_por = %s, fac_fecha_modificacion = NOW() WHERE fac_id = %s",
                (pagado, user_id, factura_id),
            )
            if reserva_id:
                cursor.execute("UPDATE reservas_web SET res_estado = 'pagada' WHERE res_id = %s", (reserva_id,))
            return 'pagada'
        nuevo_estado = 'parcial' if pagado > 0 else 'pendiente'
        cursor.execute(
            "UPDATE facturas SET fac_estado = %s, fac_anticipo = %s, fac_saldo_pendiente = %s, "
            "fac_modificada_por = %s, fac_fecha_modificacion = NOW() WHERE fac_id = %s",
            (nuevo_estado, pagado, saldo, user_id, factura_id),
        )
        return nuevo_estado

    def crear(self, data, user_id=None):
        payload = self._validar_payload(data)
        if payload['monto'] <= 0:
            raise ServiceError('El monto del pago debe ser mayor que cero')

        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute(
                "INSERT INTO pagos (pag_factura_id, pag_metodo, pag_estado, pag_fecha, pag_monto, pag_referencia, pag_transaccion_id) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s)",
                (
                    payload['factura_id'],
                    payload['metodo'],
                    payload['estado'],
                    payload['fecha'],
                    payload['monto'],
                    payload.get('referencia'),
                    payload.get('transaccion_id'),
                ),
            )
            pago_id = cursor.lastrowid
            if payload['estado'] == 'completado':
                nuevo_estado = self._actualizar_factura_por_pagos(cursor, payload['factura_id'], user_id)
                if nuevo_estado == 'pagada':
                    from services.facturas_services import FacturaService
                    FacturaService(self.mysql).asegurar_cita_para_factura_pagada(cursor, payload['factura_id'], user_id)
                    InventarioService(self.mysql).procesar_factura_pagada(cursor, payload['factura_id'], user_id)
                cursor.execute(
                    "INSERT INTO movimientos (mov_usuario_id, mov_tipo, mov_descripcion) VALUES (%s, 'editar_factura', %s)",
                    (user_id, f'Pago registrado para factura #{payload["factura_id"]}'),
                )
            self.mysql.connection.commit()
        except Exception:
            self.mysql.connection.rollback()
            raise
        finally:
            cursor.close()
        return self.model.obtener_por_id(self.mysql, pago_id)
