from datetime import date, datetime

from services.base_service import ServiceError


class AuditoriaPersonalService:
    def __init__(self, mysql):
        self.mysql = mysql

    def _parse_fecha(self, value, default):
        if not value:
            return default
        try:
            return datetime.strptime(value, '%Y-%m-%d').date()
        except (TypeError, ValueError):
            raise ServiceError('Las fechas deben tener formato YYYY-MM-DD')

    def _parse_empleado_id(self, value):
        if value in (None, '', 'todos'):
            return None
        try:
            empleado_id = int(value)
        except (TypeError, ValueError):
            raise ServiceError('El empleado seleccionado no es valido')
        if empleado_id <= 0:
            raise ServiceError('El empleado seleccionado no es valido')
        return empleado_id

    def _meses_en_rango(self, fecha_inicio, fecha_fin):
        cursor = date(fecha_inicio.year, fecha_inicio.month, 1)
        fin = date(fecha_fin.year, fecha_fin.month, 1)
        meses = []
        while cursor <= fin:
            meses.append(cursor.strftime('%Y-%m'))
            if cursor.month == 12:
                cursor = date(cursor.year + 1, 1, 1)
            else:
                cursor = date(cursor.year, cursor.month + 1, 1)
        return meses

    def _base_where(self, empleado_id, alias='c'):
        where = [f'{alias}.cit_fecha BETWEEN %s AND %s']
        if empleado_id:
            where.append(f'{alias}.cit_empleado_id = %s')
        return ' AND '.join(where)

    def _params(self, fecha_inicio, fecha_fin, empleado_id):
        params = [fecha_inicio, fecha_fin]
        if empleado_id:
            params.append(empleado_id)
        return tuple(params)

    def _normalizar_estado(self, estado):
        labels = {
            'pendiente': 'Pendientes',
            'confirmada': 'Confirmadas',
            'completada': 'Completadas',
            'cancelada': 'Canceladas',
        }
        return labels.get(estado, estado or 'Sin estado')

    def reporte(self, empleado_id=None, fecha_inicio=None, fecha_fin=None):
        hoy = date.today()
        inicio_default = date(hoy.year, hoy.month, 1)
        fecha_inicio = self._parse_fecha(fecha_inicio, inicio_default)
        fecha_fin = self._parse_fecha(fecha_fin, hoy)
        if fecha_inicio > fecha_fin:
            raise ServiceError('La fecha inicial no puede ser mayor que la fecha final')

        empleado_id = self._parse_empleado_id(empleado_id)
        dias_rango = (fecha_fin - fecha_inicio).days + 1
        meses_rango = self._meses_en_rango(fecha_inicio, fecha_fin)
        where = self._base_where(empleado_id)
        params = self._params(fecha_inicio, fecha_fin, empleado_id)
        completed_where = f'{where} AND c.cit_estado = %s'
        completed_params = params + ('completada',)

        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute(
                "SELECT COUNT(dc.dci_id), COUNT(DISTINCT c.cit_cliente_id), "
                "COUNT(DISTINCT c.cit_id), COALESCE(SUM(s.ser_duracion), 0) "
                "FROM citas c "
                "LEFT JOIN detalle_citas dc ON dc.dci_cita_id = c.cit_id "
                "LEFT JOIN servicios s ON s.ser_id = dc.dci_servicio_id "
                f"WHERE {completed_where}",
                completed_params,
            )
            metricas_row = cursor.fetchone()
            total_servicios = int(metricas_row[0] or 0)
            total_clientes = int(metricas_row[1] or 0)
            total_citas_completadas = int(metricas_row[2] or 0)
            total_minutos_trabajados = int(metricas_row[3] or 0)

            cursor.execute(
                "SELECT COALESCE(SUM(f.fac_total), 0) "
                "FROM citas c "
                "INNER JOIN facturas f ON f.fac_cita_id = c.cit_id "
                "  AND f.fac_tipo = 'servicio' AND f.fac_estado <> 'cancelada' "
                f"WHERE {where}",
                params,
            )
            total_ingresos = float(cursor.fetchone()[0] or 0)

            cursor.execute(
                "SELECT s.ser_nombre, COUNT(dc.dci_id) AS total "
                "FROM citas c "
                "INNER JOIN detalle_citas dc ON dc.dci_cita_id = c.cit_id "
                "INNER JOIN servicios s ON s.ser_id = dc.dci_servicio_id "
                f"WHERE {completed_where} "
                "GROUP BY s.ser_id, s.ser_nombre "
                "ORDER BY total DESC, s.ser_nombre ASC",
                completed_params,
            )
            servicios_rows = cursor.fetchall()

            cursor.execute(
                "SELECT DATE_FORMAT(c.cit_fecha, '%%Y-%%m') AS mes, COUNT(DISTINCT c.cit_cliente_id) AS total "
                "FROM citas c "
                f"WHERE {completed_where} "
                "GROUP BY mes ORDER BY mes ASC",
                completed_params,
            )
            clientes_mes_rows = {row[0]: int(row[1] or 0) for row in cursor.fetchall()}

            cursor.execute(
                "SELECT c.cit_estado, COUNT(*) "
                "FROM citas c "
                f"WHERE {where} "
                "GROUP BY c.cit_estado",
                params,
            )
            estado_rows = {row[0]: int(row[1] or 0) for row in cursor.fetchall()}

            cursor.execute(
                "SELECT DATE_FORMAT(c.cit_fecha, '%%Y-%%m') AS mes, COALESCE(SUM(f.fac_total), 0) AS total "
                "FROM citas c "
                "INNER JOIN facturas f ON f.fac_cita_id = c.cit_id "
                "  AND f.fac_tipo = 'servicio' AND f.fac_estado <> 'cancelada' "
                f"WHERE {where} "
                "GROUP BY mes ORDER BY mes ASC",
                params,
            )
            ingresos_mes_rows = {row[0]: float(row[1] or 0) for row in cursor.fetchall()}

            cursor.execute(
                "SELECT cli.cli_nombre, cli.cli_apellido, cli.cli_documento, COUNT(DISTINCT c.cit_id) AS visitas "
                "FROM citas c "
                "INNER JOIN clientes cli ON cli.cli_id = c.cit_cliente_id "
                f"WHERE {completed_where} "
                "GROUP BY cli.cli_id, cli.cli_nombre, cli.cli_apellido, cli.cli_documento "
                "ORDER BY visitas DESC, cli.cli_apellido ASC, cli.cli_nombre ASC "
                "LIMIT 5",
                completed_params,
            )
            clientes_frecuentes_rows = cursor.fetchall()

            cursor.execute(
                "SELECT WEEKDAY(c.cit_fecha) AS dia, COUNT(DISTINCT c.cit_id) AS total "
                "FROM citas c "
                f"WHERE {completed_where} "
                "GROUP BY dia ORDER BY dia ASC",
                completed_params,
            )
            productividad_rows = {int(row[0]): int(row[1] or 0) for row in cursor.fetchall()}

            cursor.execute(
                "SELECT c.cit_fecha, c.cit_hora, "
                "cli.cli_nombre, cli.cli_apellido, cli.cli_documento, cli.cli_telefono, "
                "emp.emp_nombre, emp.emp_apellido, emp.emp_documento, "
                "s.ser_nombre, dc.dci_precio, c.cit_estado, "
                "f.fac_id, f.fac_estado, f.fac_total, "
                "COALESCE(u_cita.usu_username, u_factura.usu_username) AS usuario_registro "
                "FROM citas c "
                "LEFT JOIN clientes cli ON cli.cli_id = c.cit_cliente_id "
                "LEFT JOIN empleados emp ON emp.emp_id = c.cit_empleado_id "
                "LEFT JOIN detalle_citas dc ON dc.dci_cita_id = c.cit_id "
                "LEFT JOIN servicios s ON s.ser_id = dc.dci_servicio_id "
                "LEFT JOIN facturas f ON f.fac_cita_id = c.cit_id "
                "  AND f.fac_tipo = 'servicio' AND f.fac_estado <> 'cancelada' "
                "LEFT JOIN usuarios u_cita ON u_cita.usu_id = c.cit_creado_por "
                "LEFT JOIN usuarios u_factura ON u_factura.usu_id = f.fac_generada_por "
                f"WHERE {where} "
                "ORDER BY c.cit_fecha DESC, c.cit_hora DESC, emp.emp_apellido ASC, emp.emp_nombre ASC, s.ser_nombre ASC",
                params,
            )
            historial_rows = cursor.fetchall()
        finally:
            cursor.close()

        estados_orden = ['pendiente', 'confirmada', 'completada', 'cancelada']
        return {
            'filtros': {
                'empleado_id': empleado_id,
                'fecha_inicio': fecha_inicio.isoformat(),
                'fecha_fin': fecha_fin.isoformat(),
            },
            'metricas': {
                'total_servicios': total_servicios,
                'total_clientes': total_clientes,
                'total_ingresos': total_ingresos,
                'promedio_servicios_dia': round(total_servicios / dias_rango, 2) if dias_rango else 0,
                'tiempo_total_minutos': total_minutos_trabajados,
                'duracion_promedio_cita_minutos': round(total_minutos_trabajados / total_citas_completadas, 2) if total_citas_completadas else 0,
            },
            'servicios_por_empleado': [
                {'servicio': row[0] or 'Sin servicio', 'total': int(row[1] or 0)}
                for row in servicios_rows
            ],
            'clientes_por_mes': [
                {'mes': mes, 'total': clientes_mes_rows.get(mes, 0)}
                for mes in meses_rango
            ],
            'citas_por_estado': [
                {'estado': estado, 'label': self._normalizar_estado(estado), 'total': estado_rows.get(estado, 0)}
                for estado in estados_orden
            ],
            'ingresos_por_mes': [
                {'mes': mes, 'total': ingresos_mes_rows.get(mes, 0)}
                for mes in meses_rango
            ],
            'clientes_frecuentes': [
                {
                    'cliente': f'{row[0] or ""} {row[1] or ""}'.strip(),
                    'documento': row[2] or '',
                    'visitas': int(row[3] or 0),
                }
                for row in clientes_frecuentes_rows
            ],
            'productividad_semanal': [
                {'dia': key, 'label': label, 'total': productividad_rows.get(key, 0)}
                for key, label in [
                    (0, 'Lunes'),
                    (1, 'Martes'),
                    (2, 'Miercoles'),
                    (3, 'Jueves'),
                    (4, 'Viernes'),
                    (5, 'Sabado'),
                    (6, 'Domingo'),
                ]
            ],
            'historial': [
                {
                    'fecha': str(row[0]) if row[0] else '',
                    'hora': str(row[1]) if row[1] else '',
                    'cliente': f'{row[2] or ""} {row[3] or ""}'.strip(),
                    'cliente_documento': row[4] or '',
                    'cliente_telefono': row[5] or '',
                    'empleado': f'{row[6] or ""} {row[7] or ""}'.strip(),
                    'empleado_documento': row[8] or '',
                    'servicio': row[9] or 'Sin servicio registrado',
                    'precio_servicio': float(row[10] or 0),
                    'estado_cita': row[11] or '',
                    'numero_factura': f'FAC-{int(row[12]):06d}' if row[12] else 'Sin factura',
                    'estado_factura': row[13] or 'Sin factura',
                    'total_facturado': float(row[14] or 0),
                    'usuario_registro': row[15] or 'Sin registro',
                }
                for row in historial_rows
            ],
        }
