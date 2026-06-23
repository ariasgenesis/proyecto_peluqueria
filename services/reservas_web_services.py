from datetime import datetime
from decimal import Decimal
import hashlib
import os

from models.reservas_web_model import ReservaWebModel
from services.base_service import BaseCrudService, ServiceError
from services.citas_services import CitaService
from services.clientes_services import ClienteService
from services.inventario_services import InventarioService
from services.movimientos_services import MovimientoService


class ReservaWebService(BaseCrudService):
    model = ReservaWebModel
    schema = {
        'cliente_id': {'type': 'int', 'min': 1},
        'servicios': {'type': 'list', 'required': True}, # Cambiado de servicio_id a servicios
        'empleado_id': {'type': 'int', 'min': 1},
        'fecha': {'type': 'date', 'required': True},
        'hora': {'type': 'time', 'required': True},
        'anticipo': {'type': 'decimal', 'required': True},
        'estado': {'type': 'str', 'default': 'pendiente', 'enum': ['pendiente', 'pagada', 'cancelada'], 'lower': True},
        'referencia_pago': {'type': 'str', 'max': 255},
        'transaccion_id': {'type': 'str', 'max': 255},
    }

    def listar_admin(self, page=1, per_page=20, estado=None):
        cursor = self.mysql.connection.cursor()
        where = "WHERE 1=1"
        params = []
        if estado:
            where += " AND r.res_estado = %s"
            params.append(estado)
        offset = (page - 1) * per_page
        cursor.execute(
            f"SELECT r.res_id, r.res_fecha, r.res_hora, r.res_anticipo, r.res_estado, "
            "r.res_referencia_pago, r.created_at, "
            "c.cli_nombre, c.cli_apellido, c.cli_telefono, "
            "e.emp_nombre, e.emp_apellido, "
            "GROUP_CONCAT(DISTINCT CONCAT(s.ser_nombre, '|', CAST(COALESCE(drv.drv_precio,0) AS CHAR)) "
            "  ORDER BY s.ser_id SEPARATOR ';;') AS servicios_detalle, "
            "fac_svc.fac_id, fac_svc.fac_total, fac_svc.fac_saldo_pendiente, "
            "fac_ant.fac_id "
            "FROM reservas_web r "
            "LEFT JOIN clientes c ON c.cli_id = r.res_cliente_id "
            "LEFT JOIN empleados e ON e.emp_id = r.res_empleado_id "
            "LEFT JOIN detalle_reservas_web drv ON drv.drv_reserva_id = r.res_id "
            "LEFT JOIN servicios s ON s.ser_id = drv.drv_servicio_id "
            "LEFT JOIN facturas fac_svc ON fac_svc.fac_reserva_id = r.res_id AND fac_svc.fac_tipo = 'servicio' "
            "LEFT JOIN facturas fac_ant ON fac_ant.fac_reserva_id = r.res_id AND fac_ant.fac_tipo = 'anticipo' "
            f"{where} "
            "GROUP BY r.res_id, fac_svc.fac_id, fac_svc.fac_total, fac_svc.fac_saldo_pendiente, fac_ant.fac_id "
            "ORDER BY r.res_id DESC "
            "LIMIT %s OFFSET %s",
            params + [per_page, offset],
        )
        rows = cursor.fetchall()
        cursor.execute(f"SELECT COUNT(DISTINCT r.res_id) FROM reservas_web r {where}", params)
        total = cursor.fetchone()[0]
        cursor.close()

        def parse_servicios(raw):
            if not raw:
                return []
            result = []
            for item in raw.split(';;'):
                parts = item.split('|')
                result.append({'nombre': parts[0], 'precio': float(parts[1]) if len(parts) > 1 else 0})
            return result

        return {
            'data': [
                {
                    'id_reserva':      r[0],
                    'fecha':           str(r[1]),
                    'hora':            str(r[2]),
                    'anticipo':        float(r[3] or 0),
                    'estado':          r[4],
                    'referencia':      r[5],
                    'created_at':      str(r[6]),
                    'cliente':         f'{r[7] or ""} {r[8] or ""}'.strip(),
                    'telefono':        r[9] or '',
                    'empleado':        f'{r[10] or ""} {r[11] or ""}'.strip(),
                    'servicios':       ', '.join(s['nombre'] for s in parse_servicios(r[12])),
                    'servicios_items': parse_servicios(r[12]),
                    'fac_servicio_id': r[13],
                    'total':           float(r[14] or 0),
                    'saldo_pendiente': float(r[15] or 0),
                    'fac_anticipo_id': r[16],
                }
                for r in rows
            ],
            'total': total,
            'page': page,
            'per_page': per_page,
        }

    def obtener_por_id(self, record_id):
        reserva = self.model.obtener_por_id(self.mysql, record_id)
        if not reserva:
            return None
            
        cursor = self.mysql.connection.cursor()
        cursor.execute(
            "SELECT s.ser_id, s.ser_nombre, drv.drv_precio "
            "FROM detalle_reservas_web drv "
            "INNER JOIN servicios s ON s.ser_id = drv.drv_servicio_id "
            "WHERE drv.drv_reserva_id = %s",
            (record_id,)
        )
        servicios = cursor.fetchall()
        cursor.close()
        
        reserva['servicios'] = [
            {'id_servicio': s[0], 'nombre': s[1], 'precio': float(s[2])}
            for s in servicios
        ]
        return reserva

    def _normalizar_hora(self, hora):
        text = str(hora)
        if 'day' in text:
            text = text.split(', ')[-1]
        parts = text.split(':')
        if len(parts) == 2:
            parts.append('00')
        if len(parts) == 3:
            return f'{int(parts[0]):02d}:{int(parts[1]):02d}:{int(parts[2]):02d}'
        return text

    def _validar_servicios_activos(self, servicios_ids):
        if not servicios_ids:
            raise ServiceError('Debe seleccionar al menos un servicio')
        
        cursor = self.mysql.connection.cursor()
        ids_str = ','.join(['%s'] * len(servicios_ids))
        cursor.execute(
            f"SELECT ser_id, ser_precio, ser_duracion FROM servicios WHERE ser_id IN ({ids_str}) AND ser_estado = 'activo'",
            tuple(servicios_ids),
        )
        servicios = cursor.fetchall()
        cursor.close()
        
        if len(servicios) != len(set(servicios_ids)):
            raise ServiceError('Uno o más servicios no fueron encontrados o están inactivos', 404)
            
        resultado = []
        total_precio = Decimal('0')
        total_duracion = 0
        for s in servicios:
            resultado.append({
                'id': s[0],
                'precio': Decimal(str(s[1])),
                'duracion': int(s[2])
            })
            total_precio += Decimal(str(s[1]))
            total_duracion += int(s[2])
            
        return resultado, total_precio, total_duracion

    def _validar_reserva_disponible(self, empleado_id, fecha, hora, servicios_ids=None, reserva_id=None, cursor=None):
        if not empleado_id:
            return # Si no hay empleado asignado aún, no validamos cruces específicos de empleado
            
        CitaService(self.mysql).validar_disponibilidad_publica(
            empleado_id,
            fecha,
            hora,
            servicios_ids=servicios_ids,
            reserva_id=reserva_id,
            cursor=cursor,
        )

    def crear(self, data, user_id=None):
        # El payload original tiene 'servicios', pero el modelo no. 
        # Extraemos servicios antes de validar con el modelo (o adaptamos el validador)
        servicios_input = data.get('servicios', [])
        if not isinstance(servicios_input, list):
            raise ServiceError('El campo "servicios" debe ser una lista')
        
        payload = self._validar_payload(data)
        if not payload.get('cliente_id'):
            payload['cliente_id'] = ClienteService(self.mysql).obtener_cliente_id_por_usuario(user_id)
        
        servicios_info, total_precio, _total_duracion = self._validar_servicios_activos(servicios_input)
        
        if payload['anticipo'] > total_precio:
            raise ServiceError('El anticipo no puede superar el precio total de los servicios')
            
        # Intentar asignar empleado automáticamente si no viene
        if not payload.get('empleado_id'):
            try:
                payload['empleado_id'] = CitaService(self.mysql).buscar_empleado_disponible(
                    None,
                    payload['fecha'],
                    payload['hora'],
                    servicios_ids=servicios_input
                )
            except ServiceError:
                # Si no hay nadie disponible, se permite NULL según requerimiento
                payload['empleado_id'] = None
        else:
            # Si viene empleado_id, validar disponibilidad
            self._validar_reserva_disponible(payload['empleado_id'], payload['fecha'], payload['hora'], servicios_ids=servicios_input)

        payload['estado'] = 'pendiente'
        payload.pop('transaccion_id', None)
        
        # Crear la reserva principal
        reserva_data = payload.copy()
        reserva = self.model.crear(self.mysql, **reserva_data)
        res_id = reserva["id_reserva"]
        
        # Crear detalle de servicios
        cursor = self.mysql.connection.cursor()
        for s in servicios_info:
            cursor.execute(
                "INSERT INTO detalle_reservas_web (drv_reserva_id, drv_servicio_id, drv_precio) VALUES (%s, %s, %s)",
                (res_id, s['id'], s['precio'])
            )
        self.mysql.connection.commit()
        cursor.close()

        referencia = payload.get('referencia_pago') or f'RESERVA-{res_id}'
        if referencia != reserva.get('referencia_pago'):
            reserva = self.model.actualizar(self.mysql, res_id, referencia_pago=referencia)
            
        MovimientoService(self.mysql).registrar(user_id, 'crear_reserva_web', f'Reserva web #{res_id} creada')
        
        amount_cents = int(payload['anticipo'] * 100)
        public_key = os.getenv('WOMPI_PUBLIC_KEY', '')
        integrity_secret = os.getenv('WOMPI_INTEGRITY_SECRET', '')
        integrity_str = f"{referencia}{amount_cents}COP{integrity_secret}"
        integrity_hash = hashlib.sha256(integrity_str.encode()).hexdigest()
        reserva['wompi'] = {
            'sandbox': True,
            'public_key': public_key,
            'reference': referencia,
            'amount_in_cents': amount_cents,
            'currency': 'COP',
            'integrity_hash': integrity_hash,
        }
        return reserva

    def actualizar(self, record_id, data, user_id=None):
        actual = self.model.obtener_por_id(self.mysql, record_id)
        if not actual:
            raise ServiceError('Reserva web no encontrada', 404)
            
        payload = self._validar_payload(data, partial=True)
        
        if actual['estado'] == 'pagada' and payload.get('estado') == 'cancelada':
            raise ServiceError('No se puede cancelar una reserva web pagada desde este endpoint', 409)
            
        empleado_id = payload.get('empleado_id', actual['empleado_id'])
        fecha = payload.get('fecha', actual['fecha'])
        hora = payload.get('hora', actual['hora'])
        
        # Obtener servicios actuales
        cursor = self.mysql.connection.cursor()
        cursor.execute("SELECT drv_servicio_id FROM detalle_reservas_web WHERE drv_reserva_id = %s", (record_id,))
        servicios_ids = [r[0] for r in cursor.fetchall()]
        cursor.close()

        if any(key in payload for key in ('fecha', 'hora')) and not payload.get('empleado_id') and actual['empleado_id']:
            # Si cambia fecha/hora y tenía empleado, intentar reasignar o validar
            try:
                empleado_id = CitaService(self.mysql).buscar_empleado_disponible(None, fecha, hora, servicios_ids=servicios_ids)
                payload['empleado_id'] = empleado_id
            except ServiceError:
                payload['empleado_id'] = None # O mantener el actual y fallar en disponibilidad
        
        if any(key in payload for key in ('empleado_id', 'fecha', 'hora')):
            if empleado_id:
                self._validar_reserva_disponible(empleado_id, fecha, hora, servicios_ids=servicios_ids, reserva_id=record_id)
                
        reserva = self.model.actualizar(self.mysql, record_id, **payload)
        if not reserva:
            raise ServiceError('Reserva web no encontrada', 404)
        return reserva

    def cancelar(self, record_id, user_id=None):
        reserva = self.model.obtener_por_id(self.mysql, record_id)
        if not reserva:
            raise ServiceError('Reserva web no encontrada', 404)
        if reserva['estado'] == 'pagada':
            raise ServiceError('No se puede cancelar una reserva pagada; requiere proceso manual', 409)
        self.model.actualizar(self.mysql, record_id, estado='cancelada')
        MovimientoService(self.mysql).registrar(user_id, 'cancelar_cita', f'Reserva web #{record_id} cancelada')
        return True

    def confirmar_pago_wompi(self, referencia, transaccion_id, user_id=None):
        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute(
                "SELECT r.res_id, r.res_cliente_id, r.res_empleado_id, r.res_fecha, r.res_hora, "
                "r.res_anticipo, r.res_estado, c.cli_usuario_id "
                "FROM reservas_web r "
                "INNER JOIN clientes c ON c.cli_id = r.res_cliente_id "
                "WHERE r.res_referencia_pago = %s",
                (referencia,),
            )
            reserva = cursor.fetchone()
            if not reserva:
                raise ServiceError('Reserva web no encontrada para la referencia de pago', 404)

            (
                reserva_id,
                cliente_id,
                empleado_id,
                fecha,
                hora,
                anticipo,
                estado_reserva,
                cliente_usuario_id,
            ) = reserva
            
            movimiento_usuario_id = user_id or cliente_usuario_id
            
            if estado_reserva == 'pagada':
                cursor.execute(
                    "SELECT cit_id FROM citas WHERE cit_cliente_id = %s AND cit_fecha = %s AND cit_hora = %s AND cit_origen = 'web'",
                    (cliente_id, fecha, hora),
                )
                cita = cursor.fetchone()
                self.mysql.connection.commit()
                return {'id_reserva': reserva_id, 'id_cita': cita[0] if cita else None, 'estado': 'pagada'}

            # Obtener servicios del detalle
            cursor.execute(
                "SELECT drv_servicio_id, drv_precio FROM detalle_reservas_web WHERE drv_reserva_id = %s",
                (reserva_id,)
            )
            servicios_detalle = cursor.fetchall()
            servicios_ids = [s[0] for s in servicios_detalle]
            total_servicios = sum(Decimal(str(s[1])) for s in servicios_detalle)

            # Si no hay empleado asignado, ASIGNAR UNO AHORA
            if not empleado_id:
                empleado_id = CitaService(self.mysql).buscar_empleado_disponible(
                    None, str(fecha), str(hora), cursor=cursor, servicios_ids=servicios_ids
                )
                cursor.execute("UPDATE reservas_web SET res_empleado_id = %s WHERE res_id = %s", (empleado_id, reserva_id))
            else:
                self._validar_reserva_disponible(
                    empleado_id,
                    str(fecha),
                    str(hora),
                    servicios_ids=servicios_ids,
                    reserva_id=reserva_id,
                    cursor=cursor,
                )

            cursor.execute(
                "UPDATE reservas_web SET res_estado = 'pagada', res_transaccion_id = %s WHERE res_id = %s",
                (transaccion_id, reserva_id),
            )
            
            # Crear CITA
            cursor.execute(
                "INSERT INTO citas (cit_cliente_id, cit_empleado_id, cit_fecha, cit_hora, cit_origen, cit_estado, cit_creado_por) "
                "VALUES (%s, %s, %s, %s, 'web', 'confirmada', %s)",
                (cliente_id, empleado_id, fecha, hora, cliente_usuario_id),
            )
            cita_id = cursor.lastrowid
            
            # Crear DETALLE CITA
            for s_id, s_precio in servicios_detalle:
                cursor.execute(
                    "INSERT INTO detalle_citas (dci_cita_id, dci_servicio_id, dci_precio) VALUES (%s, %s, %s)",
                    (cita_id, s_id, s_precio),
                )

            # --- GENERACIÓN DE FACTURAS (Requerimiento: 2 facturas) ---
            fecha_actual = datetime.now().strftime('%Y-%m-%d')
            
            # 1. Factura de ANTICIPO
            cursor.execute(
                "INSERT INTO facturas (fac_cita_id, fac_reserva_id, fac_fecha, fac_total, fac_anticipo, fac_saldo_pendiente, "
                "fac_tipo, fac_estado, fac_generada_por, fac_inventario_procesado) "
                "VALUES (%s, %s, %s, %s, %s, 0, 'anticipo', 'pagada', %s, 0)",
                (cita_id, reserva_id, fecha_actual, anticipo, anticipo, cliente_usuario_id),
            )
            factura_anticipo_id = cursor.lastrowid
            
            # 2. Factura de SERVICIO
            saldo = max(total_servicios - Decimal(str(anticipo)), Decimal('0'))
            estado_factura_servicio = 'pagada' if saldo == 0 else 'pendiente'
            cursor.execute(
                "INSERT INTO facturas (fac_cita_id, fac_reserva_id, fac_fecha, fac_total, fac_anticipo, fac_saldo_pendiente, "
                "fac_tipo, fac_estado, fac_generada_por, fac_inventario_procesado) "
                "VALUES (%s, %s, %s, %s, %s, %s, 'servicio', %s, %s, 0)",
                (cita_id, reserva_id, fecha_actual, total_servicios, anticipo, saldo, estado_factura_servicio, cliente_usuario_id),
            )
            factura_servicio_id = cursor.lastrowid

            # Registrar PAGO (aplicado a la factura de anticipo)
            cursor.execute(
                "INSERT INTO pagos (pag_factura_id, pag_metodo, pag_estado, pag_fecha, pag_monto, pag_referencia, pag_transaccion_id) "
                "VALUES (%s, 'wompi', 'completado', %s, %s, %s, %s)",
                (factura_anticipo_id, fecha_actual, anticipo, referencia, transaccion_id),
            )

            cursor.execute(
                "INSERT INTO movimientos (mov_usuario_id, mov_tipo, mov_descripcion) VALUES (%s, 'crear_cita', %s)",
                (movimiento_usuario_id, f'Cita #{cita_id} creada desde reserva web #{reserva_id}'),
            )
            cursor.execute(
                "INSERT INTO movimientos (mov_usuario_id, mov_tipo, mov_descripcion) VALUES (%s, 'confirmar_pago_wompi', %s)",
                (movimiento_usuario_id, f'Pago Wompi confirmado para reserva web #{reserva_id}'),
            )

            # Si la factura de servicio quedó pagada (anticipo cubrió todo), procesar inventario
            if estado_factura_servicio == 'pagada':
                InventarioService(self.mysql).procesar_factura_pagada(cursor, factura_servicio_id, movimiento_usuario_id)
                cursor.execute("UPDATE citas SET cit_estado = 'completada' WHERE cit_id = %s", (cita_id,))

            self.mysql.connection.commit()
            return {
                'id_reserva': reserva_id,
                'id_cita': cita_id,
                'id_factura_anticipo': factura_anticipo_id,
                'id_factura_servicio': factura_servicio_id,
                'estado': 'pagada',
                'referencia_pago': referencia,
                'transaccion_id': transaccion_id,
            }
        except Exception:
            self.mysql.connection.rollback()
            raise
        finally:
            cursor.close()
