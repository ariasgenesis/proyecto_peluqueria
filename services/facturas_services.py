from models.facturas_model import FacturaModel
from datetime import datetime

from services.base_service import BaseCrudService, ServiceError
from services.empleados_services import EmpleadoService
from services.inventario_services import InventarioService
from services.movimientos_services import MovimientoService


class FacturaService(BaseCrudService):
    model = FacturaModel
    schema = {
        'cita_id': {'type': 'int', 'min': 1},
        'reserva_id': {'type': 'int', 'min': 1},
        'fecha': {'type': 'date', 'required': True},
        'total': {'type': 'decimal', 'required': True},
        'anticipo': {'type': 'decimal', 'default': 0},
        'saldo_pendiente': {'type': 'decimal'},
        'tipo': {'type': 'str', 'required': True, 'enum': ['anticipo', 'servicio']},
        'estado': {'type': 'str', 'default': 'pendiente', 'enum': ['pendiente', 'parcial', 'pagada', 'cancelada'], 'lower': True},
        'inventario_procesado': {'type': 'int', 'default': 0, 'min': 0},
        'generada_por': {'type': 'int', 'min': 1},
        'modificada_por': {'type': 'int', 'min': 1},
        'fecha_modificacion': {'type': 'datetime'}
    }

    def _normalizar_saldo(self, payload):
        anticipo = payload.get('anticipo') or 0
        total = payload.get('total') or 0
        saldo = total - anticipo
        if saldo < 0:
            raise ServiceError('El anticipo no puede superar el total de la factura')
        payload['saldo_pendiente'] = saldo
        
        # Lógica de estado automática solo si no se provee explícitamente
        if 'estado' not in payload or payload['estado'] not in ['cancelada']:
            if saldo == 0:
                payload['estado'] = 'pagada'
            elif anticipo > 0:
                payload['estado'] = 'parcial'
            else:
                payload['estado'] = 'pendiente'
        return payload

    def crear(self, data, user_id=None):
        if not isinstance(data, dict):
            raise ServiceError('El cuerpo de la solicitud debe ser un objeto JSON')
        
        EmpleadoService(self.mysql).validar_pin_usuario(user_id, data.get('pin'), data.get('pin_empleado_id'))
        
        payload = self._validar_payload(data)
        payload['generada_por'] = payload.get('generada_por') or user_id
        if not payload['generada_por']:
            raise ServiceError('No se pudo identificar el usuario generador')
            
        payload.pop('modificada_por', None)
        payload.pop('fecha_modificacion', None)
        payload = self._normalizar_saldo(payload)
        payload['inventario_procesado'] = 0

        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute(
                "INSERT INTO facturas "
                "(fac_cita_id, fac_reserva_id, fac_fecha, fac_total, fac_anticipo, fac_saldo_pendiente, "
                "fac_tipo, fac_estado, fac_generada_por, fac_inventario_procesado) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 0)",
                (
                    payload.get('cita_id'),
                    payload.get('reserva_id'),
                    payload['fecha'],
                    payload['total'],
                    payload['anticipo'],
                    payload['saldo_pendiente'],
                    payload['tipo'],
                    payload['estado'],
                    payload['generada_por'],
                ),
            )
            factura_id = cursor.lastrowid
            
            MovimientoService(self.mysql).registrar(user_id or payload['generada_por'], 'crear_factura', f'Factura #{factura_id} creada')
            
            # SOLO descontar inventario si es tipo SERVICIO y estado PAGADA
            if payload['tipo'] == 'servicio' and payload['estado'] == 'pagada':
                InventarioService(self.mysql).procesar_factura_pagada(cursor, factura_id, user_id or payload['generada_por'])
                if payload.get('cita_id'):
                    cursor.execute("UPDATE citas SET cit_estado = 'completada' WHERE cit_id = %s", (payload['cita_id'],))
            
            self.mysql.connection.commit()
        except Exception:
            self.mysql.connection.rollback()
            raise
        finally:
            cursor.close()
            
        return self.model.obtener_por_id(self.mysql, factura_id)

    def actualizar(self, record_id, data, user_id=None):
        if not isinstance(data, dict):
            raise ServiceError('El cuerpo de la solicitud debe ser un objeto JSON')
            
        actual = self.model.obtener_por_id(self.mysql, record_id)
        if not actual:
            raise ServiceError('Factura no encontrada', 404)
            
        # RESTRICCIÓN: Solo facturas PENDIENTES pueden modificarse estructuralmente (total, servicios)
        # Si está parcial o pagada, solo se deberían permitir pagos (que usualmente no pasan por aquí sino por PagosService)
        if actual['estado'] in ['pagada', 'parcial', 'cancelada']:
            # Solo permitir cambios que no afecten el total o tipo si ya está en proceso de pago
            if any(k in data for k in ('total', 'tipo', 'cita_id', 'reserva_id')):
                 raise ServiceError(f'Las facturas en estado {actual["estado"]} no permiten cambios estructurales', 409)

        EmpleadoService(self.mysql).validar_pin_usuario(user_id, data.get('pin'), data.get('pin_empleado_id'))
        
        payload = self._validar_payload(data, partial=True)
        merged = {**actual, **payload}
        normalizado = self._normalizar_saldo(merged)
        
        payload['anticipo'] = normalizado['anticipo']
        payload['saldo_pendiente'] = normalizado['saldo_pendiente']
        payload['estado'] = normalizado['estado']
        payload['modificada_por'] = user_id
        payload['fecha_modificacion'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        cursor = self.mysql.connection.cursor()
        try:
            factura = self.model.actualizar(self.mysql, record_id, **payload)
            if not factura:
                raise ServiceError('Factura no encontrada', 404)
                
            # Verificar si con el cambio pasó a PAGADA y es de tipo SERVICIO
            if actual['estado'] != 'pagada' and payload['estado'] == 'pagada' and actual['tipo'] == 'servicio':
                InventarioService(self.mysql).procesar_factura_pagada(cursor, record_id, user_id)
                if actual.get('cita_id'):
                    cursor.execute("UPDATE citas SET cit_estado = 'completada' WHERE cit_id = %s", (actual['cita_id'],))
            
            self.mysql.connection.commit()
            MovimientoService(self.mysql).registrar(user_id, 'editar_factura', f'Factura #{record_id} editada')
            return factura
        except Exception:
            self.mysql.connection.rollback()
            raise
        finally:
            cursor.close()

    def eliminar(self, record_id, user_id=None):
        cursor = self.mysql.connection.cursor()
        cursor.execute("SELECT fac_id, fac_estado FROM facturas WHERE fac_id = %s", (record_id,))
        existe = cursor.fetchone()
        cursor.close()
        
        if not existe:
            raise ServiceError('Factura no encontrada', 404)
        if existe[1] == 'pagada':
            raise ServiceError('Las facturas pagadas no pueden cancelarse', 409)
            
        if not self.model.eliminar(self.mysql, record_id):
            raise ServiceError('Factura no encontrada', 404)
            
        MovimientoService(self.mysql).registrar(user_id, 'eliminar_factura', f'Factura #{record_id} cancelada')
        return True

    def eliminar_con_pin(self, record_id, data, user_id=None):
        if not isinstance(data, dict):
            raise ServiceError('El cuerpo de la solicitud debe ser un objeto JSON')
        EmpleadoService(self.mysql).validar_pin_usuario(user_id, data.get('pin'), data.get('pin_empleado_id'))
        return self.eliminar(record_id, user_id)
