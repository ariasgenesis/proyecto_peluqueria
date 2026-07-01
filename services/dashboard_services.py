class DashboardService:
    def __init__(self, mysql):
        self.mysql = mysql

    def admin_resumen(self):
        cursor = self.mysql.connection.cursor()
        cursor.execute(
            "SELECT "
            "(SELECT COUNT(*) FROM citas WHERE cit_fecha = CURDATE() AND cit_estado <> 'cancelada') AS citas_hoy, "
            "(SELECT COUNT(*) FROM citas WHERE cit_fecha = CURDATE() AND cit_estado = 'pendiente') AS citas_pendientes, "
            "(SELECT COALESCE(SUM(fac_total), 0) FROM facturas WHERE fac_fecha = CURDATE() AND fac_estado = 'pagada') AS ingresos_hoy, "
            "(SELECT COUNT(*) FROM clientes) AS clientes_total, "
            "(SELECT COUNT(*) FROM servicios WHERE ser_estado = 'activo') AS servicios_activos, "
            "(SELECT COUNT(*) FROM productos WHERE pro_estado = 'activo' AND pro_stock <= pro_stock_minimo) AS stock_bajo"
        )
        metricas_row = cursor.fetchone()
        cursor.execute(
            "SELECT cit_estado, COUNT(*) FROM citas "
            "WHERE cit_fecha = CURDATE() "
            "GROUP BY cit_estado"
        )
        citas_por_estado = cursor.fetchall()
        cursor.execute(
            "SELECT fac_fecha, COALESCE(SUM(fac_total), 0) FROM facturas "
            "WHERE fac_fecha >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND fac_estado = 'pagada' "
            "GROUP BY fac_fecha ORDER BY fac_fecha ASC"
        )
        ingresos_semana = cursor.fetchall()
        cursor.execute(
            "SELECT c.cit_id, c.cit_cliente_id, c.cit_empleado_id, c.cit_fecha, c.cit_hora, c.cit_estado, "
            "cli.cli_nombre, cli.cli_apellido, emp.emp_nombre, emp.emp_apellido "
            "FROM citas c "
            "LEFT JOIN clientes cli ON cli.cli_id = c.cit_cliente_id "
            "LEFT JOIN empleados emp ON emp.emp_id = c.cit_empleado_id "
            "WHERE c.cit_fecha = CURDATE() AND c.cit_estado <> 'cancelada' "
            "ORDER BY c.cit_hora ASC LIMIT 20"
        )
        citas_hoy = cursor.fetchall()
        cursor.execute(
            "SELECT fac_id, fac_cita_id, fac_fecha, fac_total, fac_estado "
            "FROM facturas ORDER BY fac_id DESC LIMIT 10"
        )
        facturas = cursor.fetchall()
        cursor.execute(
            "SELECT pro_id, pro_nombre, pro_stock, pro_stock_minimo "
            "FROM productos WHERE pro_estado = 'activo' AND pro_stock <= pro_stock_minimo "
            "ORDER BY pro_stock ASC LIMIT 10"
        )
        stock_bajo = cursor.fetchall()
        cursor.execute(
            "SELECT mov_id, mov_usuario_id, mov_tipo, mov_descripcion, mov_fecha "
            "FROM movimientos ORDER BY mov_id DESC LIMIT 10"
        )
        movimientos = cursor.fetchall()
        cursor.close()
        return {
            'metricas': {
                'citas_hoy': int(metricas_row[0] or 0),
                'citas_pendientes': int(metricas_row[1] or 0),
                'ingresos_hoy': float(metricas_row[2] or 0),
                'clientes_total': int(metricas_row[3] or 0),
                'servicios_activos': int(metricas_row[4] or 0),
                'stock_bajo': int(metricas_row[5] or 0),
            },
            'citas_por_estado': [
                {'estado': r[0], 'total': int(r[1] or 0)}
                for r in citas_por_estado
            ],
            'ingresos_semana': [
                {'fecha': str(r[0]), 'total': float(r[1] or 0)}
                for r in ingresos_semana
            ],
            'citas_hoy': [
                {
                    'id_cita': r[0],
                    'cliente_id': r[1],
                    'empleado_id': r[2],
                    'fecha': str(r[3]),
                    'hora': str(r[4]),
                    'estado': r[5],
                    'cliente_nombre': r[6],
                    'cliente_apellido': r[7],
                    'empleado_nombre': r[8],
                    'empleado_apellido': r[9],
                }
                for r in citas_hoy
            ],
            'facturas_recientes': [
                {'id_factura': r[0], 'cita_id': r[1], 'fecha': str(r[2]), 'total': float(r[3]), 'estado': r[4]}
                for r in facturas
            ],
            'productos_stock_bajo': [
                {'id_producto': r[0], 'nombre': r[1], 'stock': r[2], 'stock_minimo': r[3]}
                for r in stock_bajo
            ],
            'movimientos_recientes': [
                {'id_movimiento': r[0], 'usuario_id': r[1], 'tipo': r[2], 'descripcion': r[3], 'fecha': str(r[4])}
                for r in movimientos
            ],
        }

    def empleado_resumen(self, usuario_id):
        cursor = self.mysql.connection.cursor()
        cursor.execute("SELECT emp_id FROM empleados WHERE emp_usuario_id = %s", (usuario_id,))
        row = cursor.fetchone()
        if not row:
            cursor.close()
            return {
                'metricas': {'citas_hoy': 0, 'citas_pendientes': 0, 'proximas_citas': 0, 'completadas_hoy': 0},
                'citas_hoy': [],
                'citas_dia': [],
                'proximas_citas': [],
                'actividad_reciente': [],
            }
        empleado_id = row[0]
        cursor.execute(
            "SELECT c.cit_id, c.cit_cliente_id, c.cit_fecha, c.cit_hora, c.cit_estado, "
            "cli.cli_nombre, cli.cli_apellido "
            "FROM citas c "
            "LEFT JOIN clientes cli ON cli.cli_id = c.cit_cliente_id "
            "WHERE c.cit_empleado_id = %s AND c.cit_fecha = CURDATE() AND c.cit_estado <> 'cancelada' "
            "ORDER BY c.cit_hora ASC",
            (empleado_id,)
        )
        citas_dia = cursor.fetchall()
        cursor.execute(
            "SELECT c.cit_id, c.cit_cliente_id, c.cit_fecha, c.cit_hora, c.cit_estado, "
            "cli.cli_nombre, cli.cli_apellido "
            "FROM citas c "
            "LEFT JOIN clientes cli ON cli.cli_id = c.cit_cliente_id "
            "WHERE c.cit_empleado_id = %s AND c.cit_fecha >= CURDATE() AND c.cit_estado <> 'cancelada' "
            "ORDER BY c.cit_fecha ASC, c.cit_hora ASC LIMIT 15",
            (empleado_id,)
        )
        proximas = cursor.fetchall()
        cursor.execute(
            "SELECT mov_id, mov_tipo, mov_descripcion, mov_fecha "
            "FROM movimientos WHERE mov_usuario_id = %s ORDER BY mov_id DESC LIMIT 10",
            (usuario_id,)
        )
        actividad = cursor.fetchall()
        metricas = {
            'citas_hoy': len(citas_dia),
            'citas_pendientes': sum(1 for r in citas_dia if r[4] == 'pendiente'),
            'proximas_citas': len(proximas),
            'completadas_hoy': sum(1 for r in citas_dia if r[4] == 'completada'),
        }
        cursor.close()
        citas_dia_data = [
            {
                'id_cita': r[0],
                'cliente_id': r[1],
                'fecha': str(r[2]),
                'hora': str(r[3]),
                'estado': r[4],
                'cliente_nombre': r[5],
                'cliente_apellido': r[6],
                'empleado_nombre': '',
                'empleado_apellido': '',
            }
            for r in citas_dia
        ]
        return {
            'metricas': metricas,
            'citas_hoy': citas_dia_data,
            'citas_dia': [
                {
                    'id_cita': r[0],
                    'cliente_id': r[1],
                    'fecha': str(r[2]),
                    'hora': str(r[3]),
                    'estado': r[4],
                    'cliente_nombre': r[5],
                    'cliente_apellido': r[6],
                }
                for r in citas_dia
            ],
            'proximas_citas': [
                {
                    'id_cita': r[0],
                    'cliente_id': r[1],
                    'fecha': str(r[2]),
                    'hora': str(r[3]),
                    'estado': r[4],
                    'cliente_nombre': r[5],
                    'cliente_apellido': r[6],
                }
                for r in proximas
            ],
            'actividad_reciente': [
                {'id_movimiento': r[0], 'tipo': r[1], 'descripcion': r[2], 'fecha': str(r[3])}
                for r in actividad
            ],
        }

    def kanban_citas(self, fecha=None):
        cursor = self.mysql.connection.cursor()
        fecha_sql = "CURDATE()"
        params = []
        if fecha:
            fecha_sql = "%s"
            params.append(fecha)
        cursor.execute(
            "SELECT c.cit_id, c.cit_fecha, c.cit_hora, c.cit_estado, "
            "cli.cli_nombre, cli.cli_apellido, cli.cli_documento, cli.cli_telefono, c.cit_cliente_id, "
            "emp.emp_nombre, emp.emp_apellido, c.cit_empleado_id, "
            "GROUP_CONCAT(s.ser_nombre ORDER BY s.ser_id SEPARATOR ', ') AS servicios, "
            "COALESCE(SUM(s.ser_duracion), 0) AS duracion, "
            "f.fac_id, f.fac_estado, "
            "COALESCE(f.fac_total, SUM(dc.dci_precio), 0) AS total, "
            "COALESCE(f.fac_anticipo, 0) AS anticipo, "
            "COALESCE(f.fac_saldo_pendiente, COALESCE(SUM(dc.dci_precio), 0), 0) AS saldo_pendiente, "
            "CASE WHEN NOW() > DATE_ADD(TIMESTAMP(c.cit_fecha, c.cit_hora), "
            "INTERVAL COALESCE(SUM(s.ser_duracion), 0) MINUTE) "
            "AND c.cit_estado NOT IN ('completada', 'cancelada') THEN 1 ELSE 0 END AS retrasada "
            "FROM citas c "
            "LEFT JOIN clientes cli ON cli.cli_id = c.cit_cliente_id "
            "LEFT JOIN empleados emp ON emp.emp_id = c.cit_empleado_id "
            "LEFT JOIN detalle_citas dc ON dc.dci_cita_id = c.cit_id "
            "LEFT JOIN servicios s ON s.ser_id = dc.dci_servicio_id "
            "LEFT JOIN facturas f ON f.fac_cita_id = c.cit_id "
            "  AND f.fac_tipo = 'servicio' AND f.fac_estado <> 'cancelada' "
            f"WHERE c.cit_estado <> 'cancelada' AND c.cit_fecha = {fecha_sql} "
            "GROUP BY c.cit_id, c.cit_fecha, c.cit_hora, c.cit_estado, "
            "cli.cli_nombre, cli.cli_apellido, cli.cli_documento, cli.cli_telefono, c.cit_cliente_id, "
            "emp.emp_nombre, emp.emp_apellido, c.cit_empleado_id, "
            "f.fac_id, f.fac_estado, f.fac_saldo_pendiente, f.fac_anticipo, f.fac_total "
            "ORDER BY c.cit_fecha ASC, c.cit_hora ASC",
            tuple(params),
        )
        rows = cursor.fetchall()
        cursor.close()
        columnas = {'pendientes': [], 'confirmadas': [], 'completadas': []}
        for r in rows:
            estado_cita = r[3]
            tarjeta = {
                'id_cita':        r[0],
                'fecha':          str(r[1]),
                'hora':           str(r[2]),
                'estado':         estado_cita,
                'cliente':        f'{r[4] or ""} {r[5] or ""}'.strip(),
                'cliente_documento': r[6],
                'cli_documento':  r[6],
                'cliente_telefono': r[7],
                'cliente_id':     r[8],
                'empleado':       f'{r[9] or ""} {r[10] or ""}'.strip(),
                'empleado_id':    r[11],
                'servicio':       r[12],
                'duracion':       int(r[13] or 0),
                'factura_id':     r[14],
                'factura_estado': r[15],
                'total':          float(r[16] or 0),
                'anticipo':       float(r[17] or 0),
                'saldo_pendiente': float(r[18] or 0),
                'retraso':        bool(r[19]),
            }
            if estado_cita == 'pendiente':
                columnas['pendientes'].append(tarjeta)
            elif estado_cita == 'confirmada':
                columnas['confirmadas'].append(tarjeta)
            elif estado_cita == 'completada':
                columnas['completadas'].append(tarjeta)
        return columnas

    def alertas(self):
        cursor = self.mysql.connection.cursor()
        cursor.execute(
            "SELECT pro_id, pro_nombre, pro_stock, pro_stock_minimo "
            "FROM productos WHERE pro_estado = 'activo' AND pro_stock <= pro_stock_minimo "
            "ORDER BY pro_stock ASC"
        )
        productos = cursor.fetchall()
        cursor.execute(
            "SELECT c.cit_id, c.cit_fecha, c.cit_hora, cli.cli_nombre, cli.cli_apellido, "
            "emp.emp_nombre, emp.emp_apellido, GROUP_CONCAT(s.ser_nombre SEPARATOR ', '), COALESCE(SUM(s.ser_duracion), 0) "
            "FROM citas c "
            "LEFT JOIN clientes cli ON cli.cli_id = c.cit_cliente_id "
            "LEFT JOIN empleados emp ON emp.emp_id = c.cit_empleado_id "
            "LEFT JOIN detalle_citas dc ON dc.dci_cita_id = c.cit_id "
            "LEFT JOIN servicios s ON s.ser_id = dc.dci_servicio_id "
            "WHERE c.cit_estado NOT IN ('completada', 'cancelada') "
            "GROUP BY c.cit_id, c.cit_fecha, c.cit_hora, cli.cli_nombre, cli.cli_apellido, emp.emp_nombre, emp.emp_apellido "
            "HAVING NOW() > DATE_ADD(TIMESTAMP(c.cit_fecha, c.cit_hora), INTERVAL COALESCE(SUM(s.ser_duracion), 0) MINUTE) "
            "ORDER BY c.cit_fecha ASC, c.cit_hora ASC"
        )
        citas = cursor.fetchall()
        cursor.execute(
            "SELECT s.ser_id, s.ser_nombre, GROUP_CONCAT(p.pro_nombre ORDER BY p.pro_nombre SEPARATOR ', ') "
            "FROM servicios s "
            "INNER JOIN servicios_productos sp ON sp.sep_servicio_id = s.ser_id "
            "INNER JOIN productos p ON p.pro_id = sp.sep_producto_id "
            "WHERE s.ser_estado = 'inactivo' "
            "AND (p.pro_estado <> 'activo' OR p.pro_stock <= p.pro_stock_minimo) "
            "GROUP BY s.ser_id, s.ser_nombre "
            "ORDER BY s.ser_nombre ASC"
        )
        servicios_stock = cursor.fetchall()
        cursor.close()
        return {
            'productos_stock_bajo': [
                {
                    'id_producto': r[0],
                    'nombre': r[1],
                    'stock': r[2],
                    'stock_minimo': r[3],
                }
                for r in productos
            ],
            'citas_retrasadas': [
                {
                    'id_cita': r[0],
                    'fecha': str(r[1]),
                    'hora': str(r[2]),
                    'cliente': f'{r[3] or ""} {r[4] or ""}'.strip(),
                    'empleado': f'{r[5] or ""} {r[6] or ""}'.strip(),
                    'servicio': r[7],
                    'duracion': int(r[8] or 0),
                    'retrasada': True,
                }
                for r in citas
            ],
            'servicios_inactivos_stock': [
                {
                    'id_servicio': r[0],
                    'nombre': r[1],
                    'productos': r[2],
                }
                for r in servicios_stock
            ],
        }
