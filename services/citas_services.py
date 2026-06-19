from datetime import datetime
from decimal import Decimal

from models.citas_model import CitaModel
from services.base_service import BaseCrudService, ServiceError
from services.movimientos_services import MovimientoService


class CitaService(BaseCrudService):
    model = CitaModel
    schema = {
        'cliente_id': {'type': 'int', 'required': True, 'min': 1},
        'empleado_id': {'type': 'int', 'required': True, 'min': 1},
        'fecha': {'type': 'date', 'required': True},
        'hora': {'type': 'time', 'required': True},
        'estado': {
            'type': 'str',
            'default': 'pendiente',
            'enum': ['pendiente', 'confirmada', 'cancelada', 'completada'],
            'lower': True,
        },
        'origen': {'type': 'str', 'default': 'dashboard', 'enum': ['dashboard', 'web'], 'lower': True},
        'creado_por': {'type': 'int', 'min': 1},
    }

    dias_semana = {
        0: 'lunes',
        1: 'martes',
        2: 'miercoles',
        3: 'jueves',
        4: 'viernes',
        5: 'sabado',
        6: 'domingo',
    }

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

    def _time_to_seconds(self, value):
        text = str(value)
        if 'day' in text:
            text = text.split(', ')[-1]
        parts = [int(part) for part in text.split(':')]
        if len(parts) == 2:
            parts.append(0)
        return parts[0] * 3600 + parts[1] * 60 + parts[2]

    def _obtener_duracion_servicio(self, servicio_id, cursor=None):
        close_cursor = cursor is None
        cursor = cursor or self.mysql.connection.cursor()
        cursor.execute(
            "SELECT ser_duracion FROM servicios WHERE ser_id = %s AND ser_estado = 'activo'",
            (servicio_id,),
        )
        row = cursor.fetchone()
        if close_cursor:
            cursor.close()
        if not row:
            raise ServiceError('Servicio no encontrado o inactivo', 404)
        return int(row[0])

    def _intervalos_se_solapan(self, inicio_a, fin_a, inicio_b, fin_b):
        return inicio_a < fin_b and fin_a > inicio_b

    def _validar_disponibilidad(self, empleado_id, fecha, hora, duracion_minutos=30, cita_id=None, reserva_id=None, cursor=None):
        close_cursor = cursor is None
        cursor = cursor or self.mysql.connection.cursor()

        fecha_obj = datetime.strptime(fecha, '%Y-%m-%d')
        dia_semana = self.dias_semana[fecha_obj.weekday()]
        cursor.execute("SELECT emp_id FROM empleados WHERE emp_id = %s AND emp_estado = 'activo'", (empleado_id,))
        if not cursor.fetchone():
            if close_cursor:
                cursor.close()
            raise ServiceError('Empleado no encontrado o inactivo', 404)

        cursor.execute(
            "SELECT hor_hora_inicio, hor_hora_fin FROM horarios "
            "WHERE hor_empleado_id = %s AND hor_dia_semana = %s",
            (empleado_id, dia_semana)
        )
        horario = cursor.fetchone()
        if not horario:
            if close_cursor:
                cursor.close()
            raise ServiceError('El empleado no tiene horario laboral para esa fecha')

        hora_normalizada = self._normalizar_hora(hora)
        inicio = self._time_to_seconds(hora_normalizada)
        fin = inicio + (int(duracion_minutos) * 60)
        
        # Validar horario laboral
        if self._time_to_seconds(horario[0]) > inicio or self._time_to_seconds(horario[1]) < fin:
            if close_cursor:
                cursor.close()
            raise ServiceError('La cita esta fuera del horario laboral del empleado')

        # Validar BLOQUEOS DE HORARIO
        cursor.execute(
            "SELECT blo_hora_inicio, blo_hora_fin FROM bloqueos_horarios "
            "WHERE blo_empleado_id = %s AND blo_fecha = %s",
            (empleado_id, fecha)
        )
        for bloq_inicio, bloq_fin in cursor.fetchall():
            if self._intervalos_se_solapan(inicio, fin, self._time_to_seconds(bloq_inicio), self._time_to_seconds(bloq_fin)):
                if close_cursor:
                    cursor.close()
                raise ServiceError('El horario esta bloqueado para este empleado')

        # Validar CITAS existentes
        params = [empleado_id, fecha]
        extra = ''
        if cita_id:
            extra = ' AND cit_id <> %s'
            params.append(cita_id)
        cursor.execute(
            "SELECT c.cit_id, c.cit_hora, COALESCE(SUM(s.ser_duracion), 30) AS duracion "
            "FROM citas c "
            "LEFT JOIN detalle_citas dc ON dc.dci_cita_id = c.cit_id "
            "LEFT JOIN servicios s ON s.ser_id = dc.dci_servicio_id "
            "WHERE c.cit_empleado_id = %s AND c.cit_fecha = %s AND c.cit_estado <> 'cancelada'"
            f"{extra} GROUP BY c.cit_id, c.cit_hora",
            tuple(params)
        )
        for cita_existente_id, hora_existente, duracion_existente in cursor.fetchall():
            existente_inicio = self._time_to_seconds(hora_existente)
            existente_fin = existente_inicio + int(duracion_existente) * 60
            if self._intervalos_se_solapan(inicio, fin, existente_inicio, existente_fin):
                if close_cursor:
                    cursor.close()
                raise ServiceError(f'El empleado ya tiene una cita que se cruza con ese horario')

        # Validar RESERVAS WEB existentes (Múltiples servicios)
        params = [empleado_id, fecha]
        extra = ''
        if reserva_id:
            extra = ' AND r.res_id <> %s'
            params.append(reserva_id)
        cursor.execute(
            "SELECT r.res_id, r.res_hora, SUM(s.ser_duracion) AS duracion "
            "FROM reservas_web r "
            "INNER JOIN detalle_reservas_web drv ON drv.drv_reserva_id = r.res_id "
            "INNER JOIN servicios s ON s.ser_id = drv.drv_servicio_id "
            "WHERE r.res_empleado_id = %s AND r.res_fecha = %s AND r.res_estado <> 'cancelada'"
            f"{extra} GROUP BY r.res_id, r.res_hora",
            tuple(params),
        )
        for _reserva_existente_id, hora_existente, duracion_existente in cursor.fetchall():
            existente_inicio = self._time_to_seconds(hora_existente)
            existente_fin = existente_inicio + int(duracion_existente or 30) * 60
            if self._intervalos_se_solapan(inicio, fin, existente_inicio, existente_fin):
                if close_cursor:
                    cursor.close()
                raise ServiceError('Ya existe una reserva web que se cruza con ese horario')

        if close_cursor:
            cursor.close()

    def validar_disponibilidad_publica(self, empleado_id, fecha, hora, servicio_id=None, duracion_minutos=None, cita_id=None, reserva_id=None, cursor=None, servicios_ids=None):
        duracion = duracion_minutos
        if duracion is None:
            if servicios_ids:
                duracion = 0
                for s_id in servicios_ids:
                    duracion += self._obtener_duracion_servicio(s_id, cursor)
            elif servicio_id:
                duracion = self._obtener_duracion_servicio(servicio_id, cursor)
            else:
                duracion = 30
        self._validar_disponibilidad(empleado_id, fecha, hora, duracion, cita_id, reserva_id, cursor)

    def buscar_empleado_disponible(self, servicio_id, fecha, hora, cursor=None, servicios_ids=None):
        close_cursor = cursor is None
        cursor = cursor or self.mysql.connection.cursor()
        
        duracion = 0
        if servicios_ids:
            for s_id in servicios_ids:
                duracion += self._obtener_duracion_servicio(s_id, cursor)
        else:
            duracion = self._obtener_duracion_servicio(servicio_id, cursor)

        fecha_obj = datetime.strptime(fecha, '%Y-%m-%d')
        dia_semana = self.dias_semana[fecha_obj.weekday()]
        cursor.execute(
            "SELECT e.emp_id, COUNT(c.cit_id) AS carga "
            "FROM empleados e "
            "INNER JOIN horarios h ON h.hor_empleado_id = e.emp_id AND h.hor_dia_semana = %s "
            "LEFT JOIN citas c ON c.cit_empleado_id = e.emp_id AND c.cit_fecha = %s AND c.cit_estado <> 'cancelada' "
            "WHERE e.emp_estado = 'activo' "
            "GROUP BY e.emp_id ORDER BY carga ASC, e.emp_id ASC",
            (dia_semana, fecha),
        )
        empleados = cursor.fetchall()
        for empleado_id, _carga in empleados:
            try:
                self._validar_disponibilidad(empleado_id, fecha, hora, duracion, cursor=cursor)
                if close_cursor:
                    cursor.close()
                return empleado_id
            except ServiceError:
                continue
        if close_cursor:
            cursor.close()
        raise ServiceError('No hay empleados disponibles para los servicios en el horario seleccionado', 409)

    def crear(self, data, user_id=None):
        payload = self._validar_payload(data)
        payload['creado_por'] = payload.get('creado_por') or user_id
        if not payload['creado_por']:
            raise ServiceError('No se pudo identificar el usuario creador')
        self._validar_disponibilidad(payload['empleado_id'], payload['fecha'], payload['hora'])
        cita = self.model.crear(self.mysql, **payload)
        MovimientoService(self.mysql).registrar(user_id or payload['creado_por'], 'crear_cita', f'Cita #{cita["id_cita"]} creada')
        return cita

    def actualizar(self, record_id, data, user_id=None):
        actual = self.model.obtener_por_id(self.mysql, record_id)
        if not actual:
            raise ServiceError('Cita no encontrada', 404)
        payload = self._validar_payload(data, partial=True)
        empleado_id = payload.get('empleado_id', actual['empleado_id'])
        fecha = payload.get('fecha', actual['fecha'])
        hora = payload.get('hora', actual['hora'])
        if any(key in payload for key in ('empleado_id', 'fecha', 'hora')):
            self._validar_disponibilidad(empleado_id, fecha, hora, cita_id=record_id)
        cita = self.model.actualizar(self.mysql, record_id, **payload)
        if payload.get('estado') == 'cancelada':
            MovimientoService(self.mysql).registrar(user_id, 'cancelar_cita', f'Cita #{record_id} cancelada')
        return cita

    def editar_dinamica(self, record_id, data, user_id=None):
        if not isinstance(data, dict):
            raise ServiceError('El cuerpo de la solicitud debe ser un objeto JSON')
        actual = self.model.obtener_por_id(self.mysql, record_id)
        if not actual:
            raise ServiceError('Cita no encontrada', 404)

        cita_payload = {}
        for field in ('empleado_id', 'fecha', 'hora', 'estado'):
            if field in data:
                cita_payload[field] = data[field]
        if cita_payload:
            self.actualizar(record_id, cita_payload, user_id)

        servicios = data.get('servicios')
        if servicios is not None:
            if not isinstance(servicios, list) or not servicios:
                raise ServiceError('El campo "servicios" debe ser una lista con al menos un servicio')
            cursor = self.mysql.connection.cursor()
            try:
                cursor.execute("DELETE FROM detalle_citas WHERE dci_cita_id = %s", (record_id,))
                total = Decimal('0')
                for item in servicios:
                    if not isinstance(item, dict):
                        raise ServiceError('Cada servicio debe ser un objeto')
                    servicio_id = item.get('servicio_id')
                    if isinstance(servicio_id, bool) or not isinstance(servicio_id, int) or servicio_id <= 0:
                        raise ServiceError('El campo "servicio_id" debe ser un entero mayor que cero')
                    precio = item.get('precio')
                    if precio is None:
                        cursor.execute("SELECT ser_precio FROM servicios WHERE ser_id = %s AND ser_estado = 'activo'", (servicio_id,))
                        servicio = cursor.fetchone()
                        if not servicio:
                            raise ServiceError(f'Servicio #{servicio_id} no encontrado o inactivo', 404)
                        precio = Decimal(str(servicio[0]))
                    else:
                        precio = Decimal(str(precio))
                    if precio < 0:
                        raise ServiceError('El precio del servicio no puede ser negativo')
                    cursor.execute(
                        "INSERT INTO detalle_citas (dci_cita_id, dci_servicio_id, dci_precio) VALUES (%s, %s, %s)",
                        (record_id, servicio_id, precio),
                    )
                    total += precio

                cursor.execute(
                    "SELECT fac_id, fac_anticipo FROM facturas WHERE fac_cita_id = %s AND fac_estado <> 'cancelada' ORDER BY fac_id DESC LIMIT 1",
                    (record_id,),
                )
                factura = cursor.fetchone()
                if factura:
                    factura_id, anticipo = factura
                    anticipo = Decimal(str(anticipo or 0))
                    saldo = max(total - anticipo, Decimal('0'))
                    if saldo == 0:
                        estado = 'pagada'
                    elif anticipo > 0:
                        estado = 'parcial'
                    else:
                        estado = 'pendiente'
                    cursor.execute(
                        "UPDATE facturas SET fac_total = %s, fac_saldo_pendiente = %s, fac_estado = %s, "
                        "fac_modificada_por = %s, fac_fecha_modificacion = NOW() WHERE fac_id = %s",
                        (total, saldo, estado, user_id, factura_id),
                    )
                self.mysql.connection.commit()
            except Exception:
                self.mysql.connection.rollback()
                raise
            finally:
                cursor.close()
            MovimientoService(self.mysql).registrar(user_id, 'editar_factura', f'Cita #{record_id} actualizada con servicios dinamicos')

        return self.model.obtener_por_id(self.mysql, record_id)

    def eliminar(self, record_id, user_id=None):
        if not self.model.eliminar(self.mysql, record_id):
            raise ServiceError('Cita no encontrada', 404)
        MovimientoService(self.mysql).registrar(user_id, 'cancelar_cita', f'Cita #{record_id} cancelada')
        return True
