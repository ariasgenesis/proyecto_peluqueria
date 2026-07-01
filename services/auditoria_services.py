from datetime import date, time, datetime
from decimal import Decimal


class AuditoriaService:
    def __init__(self, mysql):
        self.mysql = mysql

    # ------------------------------------------------------------------
    # Método principal: recibe filtros opcionales y retorna todo el resumen
    # ------------------------------------------------------------------
    def resumen(self, empleado_id=None, fecha_inicio=None, fecha_fin=None):
        cursor = self.mysql.connection.cursor()

        # Construir clausulas de filtro reutilizables
        cond_emp = "AND c.cit_empleado_id = %s" if empleado_id else ""
        cond_fi  = "AND c.cit_fecha >= %s"       if fecha_inicio else ""
        cond_ff  = "AND c.cit_fecha <= %s"       if fecha_fin    else ""

        # Condiciones para consultas que filtran por fecha de factura
        cond_emp_f = "AND c.cit_empleado_id = %s" if empleado_id  else ""
        cond_fi_f  = "AND f.fac_fecha >= %s"       if fecha_inicio else ""
        cond_ff_f  = "AND f.fac_fecha <= %s"       if fecha_fin    else ""

        def params_base():
            p = []
            if empleado_id:  p.append(empleado_id)
            if fecha_inicio: p.append(fecha_inicio)
            if fecha_fin:    p.append(fecha_fin)
            return tuple(p)

        # ── TARJETAS KPI ────────────────────────────────────────────────

        # 1. Total servicios realizados (detalle_citas de citas completadas)
        cursor.execute(
            "SELECT COUNT(dc.dci_id) "
            "FROM detalle_citas dc "
            "INNER JOIN citas c ON c.cit_id = dc.dci_cita_id "
            "WHERE c.cit_estado = 'completada' " + cond_emp + " " + cond_fi + " " + cond_ff,
            params_base()
        )
        total_servicios = int(cursor.fetchone()[0] or 0)

        # 2. Total clientes unicos atendidos
        cursor.execute(
            "SELECT COUNT(DISTINCT c.cit_cliente_id) "
            "FROM citas c "
            "WHERE c.cit_estado = 'completada' " + cond_emp + " " + cond_fi + " " + cond_ff,
            params_base()
        )
        total_clientes = int(cursor.fetchone()[0] or 0)

        # 3. Total ingresos (facturas de tipo servicio pagadas ligadas a citas del empleado)
        cursor.execute(
            "SELECT COALESCE(SUM(f.fac_total), 0) "
            "FROM facturas f "
            "INNER JOIN citas c ON c.cit_id = f.fac_cita_id "
            "WHERE f.fac_tipo = 'servicio' AND f.fac_estado = 'pagada' "
            + cond_emp_f + " " + cond_fi_f + " " + cond_ff_f,
            params_base()
        )
        total_ingresos = float(cursor.fetchone()[0] or 0)

        # 4. Promedio de servicios por dia
        cursor.execute(
            "SELECT COUNT(DISTINCT c.cit_fecha) "
            "FROM citas c "
            "WHERE c.cit_estado = 'completada' " + cond_emp + " " + cond_fi + " " + cond_ff,
            params_base()
        )
        dias_con_citas = int(cursor.fetchone()[0] or 0)
        promedio_dia = round(total_servicios / dias_con_citas, 2) if dias_con_citas else 0

        # ── GRAFICA 1: Servicios por tipo (barras, solo citas completadas) ──
        cursor.execute(
            "SELECT s.ser_nombre, COUNT(dc.dci_id) AS cantidad "
            "FROM detalle_citas dc "
            "INNER JOIN citas c ON c.cit_id = dc.dci_cita_id "
            "INNER JOIN servicios s ON s.ser_id = dc.dci_servicio_id "
            "WHERE c.cit_estado = 'completada' " + cond_emp + " " + cond_fi + " " + cond_ff + " "
            "GROUP BY s.ser_id, s.ser_nombre "
            "ORDER BY cantidad DESC",
            params_base()
        )
        servicios_tipo = [
            {'servicio': r[0], 'cantidad': int(r[1] or 0)}
            for r in cursor.fetchall()
        ]

        # ── GRAFICA 2: Clientes atendidos por mes (lineas) ──────────────
        cursor.execute(
            "SELECT YEAR(c.cit_fecha) AS anio, MONTH(c.cit_fecha) AS mes, "
            "COUNT(DISTINCT c.cit_cliente_id) AS clientes "
            "FROM citas c "
            "WHERE c.cit_estado = 'completada' " + cond_emp + " " + cond_fi + " " + cond_ff + " "
            "GROUP BY anio, mes "
            "ORDER BY anio ASC, mes ASC",
            params_base()
        )
        clientes_por_mes = [
            {
                'anio': int(r[0]),
                'mes': int(r[1]),
                'etiqueta': _mes_label(int(r[1]), int(r[0])),
                'clientes': int(r[2] or 0),
            }
            for r in cursor.fetchall()
        ]

        # ── GRAFICA 3: Estado de citas (pie chart) ─────────────────────
        cursor.execute(
            "SELECT c.cit_estado, COUNT(*) AS total "
            "FROM citas c "
            "WHERE 1=1 " + cond_emp + " " + cond_fi + " " + cond_ff + " "
            "GROUP BY c.cit_estado",
            params_base()
        )
        estado_citas = [
            {'estado': r[0], 'total': int(r[1] or 0)}
            for r in cursor.fetchall()
        ]

        # ── GRAFICA 4: Ingresos por mes (barras) ────────────────────────
        cursor.execute(
            "SELECT YEAR(f.fac_fecha) AS anio, MONTH(f.fac_fecha) AS mes, "
            "COALESCE(SUM(f.fac_total), 0) AS ingresos "
            "FROM facturas f "
            "INNER JOIN citas c ON c.cit_id = f.fac_cita_id "
            "WHERE f.fac_tipo = 'servicio' AND f.fac_estado = 'pagada' "
            + cond_emp_f + " " + cond_fi_f + " " + cond_ff_f + " "
            "GROUP BY anio, mes "
            "ORDER BY anio ASC, mes ASC",
            params_base()
        )
        ingresos_por_mes = [
            {
                'anio': int(r[0]),
                'mes': int(r[1]),
                'etiqueta': _mes_label(int(r[1]), int(r[0])),
                'ingresos': float(r[2] or 0),
            }
            for r in cursor.fetchall()
        ]

        # ── TABLA DE HISTORIAL (JOIN completo) ──────────────────────────
        cursor.execute(
            "SELECT "
            "  c.cit_fecha, "
            "  c.cit_hora, "
            "  CONCAT(cli.cli_nombre, ' ', cli.cli_apellido) AS cliente_nombre, "
            "  COALESCE(cli.cli_documento, '-') AS cliente_documento, "
            "  COALESCE(cli.cli_telefono, '-') AS cliente_telefono, "
            "  CONCAT(emp.emp_nombre, ' ', emp.emp_apellido) AS empleado_nombre, "
            "  COALESCE(emp.emp_documento, '-') AS empleado_documento, "
            "  COALESCE(s.ser_nombre, '-') AS servicio_nombre, "
            "  COALESCE(dc.dci_precio, 0) AS servicio_precio, "
            "  c.cit_estado, "
            "  COALESCE(CAST(f.fac_id AS CHAR), '-') AS numero_factura, "
            "  COALESCE(f.fac_estado, '-') AS factura_estado, "
            "  COALESCE(f.fac_total, 0) AS total_facturado, "
            "  COALESCE(u.usu_username, '-') AS usuario_admin "
            "FROM citas c "
            "INNER JOIN clientes cli ON cli.cli_id = c.cit_cliente_id "
            "INNER JOIN empleados emp ON emp.emp_id = c.cit_empleado_id "
            "LEFT JOIN detalle_citas dc ON dc.dci_cita_id = c.cit_id "
            "LEFT JOIN servicios s ON s.ser_id = dc.dci_servicio_id "
            "LEFT JOIN facturas f ON f.fac_cita_id = c.cit_id "
            "  AND f.fac_tipo = 'servicio' AND f.fac_estado <> 'cancelada' "
            "LEFT JOIN usuarios u ON u.usu_id = c.cit_creado_por "
            "WHERE 1=1 " + cond_emp + " " + cond_fi + " " + cond_ff + " "
            "ORDER BY c.cit_fecha DESC, c.cit_hora DESC "
            "LIMIT 500",
            params_base()
        )
        cols_historial = [
            'fecha', 'hora', 'cliente_nombre', 'cliente_documento',
            'cliente_telefono', 'empleado_nombre', 'empleado_documento',
            'servicio_nombre', 'servicio_precio', 'cita_estado',
            'numero_factura', 'factura_estado', 'total_facturado', 'usuario_admin'
        ]
        historial = []
        for r in cursor.fetchall():
            row = {}
            for i, col in enumerate(cols_historial):
                val = r[i]
                # Convertir tipos de MySQL a tipos serializables por JSON
                if isinstance(val, (date, datetime, time)):
                    val = str(val)
                elif isinstance(val, Decimal):
                    val = float(val)
                elif val is None:
                    val = '-'
                row[col] = val
            historial.append(row)

        cursor.close()

        return {
            'kpi': {
                'total_servicios': total_servicios,
                'total_clientes': total_clientes,
                'total_ingresos': total_ingresos,
                'promedio_dia': promedio_dia,
            },
            'grafica_servicios_tipo': servicios_tipo,
            'grafica_clientes_mes': clientes_por_mes,
            'grafica_estado_citas': estado_citas,
            'grafica_ingresos_mes': ingresos_por_mes,
            'historial': historial,
        }


# ── Helper ───────────────────────────────────────────────────────────────────
_MESES = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
          'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']


def _mes_label(mes: int, anio: int) -> str:
    nombre = _MESES[mes] if 1 <= mes <= 12 else '?'
    return "{} {}".format(nombre, str(anio)[2:])
