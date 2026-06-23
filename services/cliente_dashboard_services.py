from services.base_service import ServiceError
from services.clientes_services import ClienteService


class ClienteDashboardService:
    def __init__(self, mysql):
        self.mysql = mysql

    def _cliente_id(self, usuario_id):
        return ClienteService(self.mysql).obtener_cliente_id_por_usuario(usuario_id)

    def mis_citas(self, usuario_id):
        cliente_id = self._cliente_id(usuario_id)
        cursor = self.mysql.connection.cursor()
        cursor.execute(
            "SELECT c.cit_id, c.cit_fecha, c.cit_hora, c.cit_origen, c.cit_estado, "
            "e.emp_nombre, e.emp_apellido, GROUP_CONCAT(s.ser_nombre SEPARATOR ', ') "
            "FROM citas c "
            "LEFT JOIN empleados e ON e.emp_id = c.cit_empleado_id "
            "LEFT JOIN detalle_citas dc ON dc.dci_cita_id = c.cit_id "
            "LEFT JOIN servicios s ON s.ser_id = dc.dci_servicio_id "
            "WHERE c.cit_cliente_id = %s "
            "GROUP BY c.cit_id, c.cit_fecha, c.cit_hora, c.cit_origen, c.cit_estado, e.emp_nombre, e.emp_apellido "
            "ORDER BY c.cit_fecha DESC, c.cit_hora DESC",
            (cliente_id,),
        )
        rows = cursor.fetchall()
        cursor.close()
        return [
            {
                'id_cita': r[0],
                'fecha': str(r[1]),
                'hora': str(r[2]),
                'origen': r[3],
                'estado': r[4],
                'empleado': f'{r[5] or ""} {r[6] or ""}'.strip(),
                'servicio': r[7],
            }
            for r in rows
        ]

    def mis_facturas(self, usuario_id):
        cliente_id = self._cliente_id(usuario_id)
        cursor = self.mysql.connection.cursor()
        # Se ajusta para buscar facturas tanto por cita como por reserva
        cursor.execute(
            "SELECT f.fac_id, f.fac_cita_id, f.fac_fecha, f.fac_total, f.fac_anticipo, "
            "f.fac_saldo_pendiente, f.fac_estado, f.fac_tipo, f.fac_reserva_id "
            "FROM facturas f "
            "LEFT JOIN citas c ON c.cit_id = f.fac_cita_id "
            "LEFT JOIN reservas_web r ON r.res_id = f.fac_reserva_id "
            "WHERE c.cit_cliente_id = %s OR r.res_cliente_id = %s "
            "ORDER BY f.fac_id DESC",
            (cliente_id, cliente_id),
        )
        rows = cursor.fetchall()
        cursor.close()
        return [
            {
                'id_factura': r[0],
                'cita_id': r[1],
                'fecha': str(r[2]),
                'total': float(r[3]),
                'anticipo': float(r[4] or 0),
                'saldo_pendiente': float(r[5] or 0),
                'estado': r[6],
                'tipo': r[7],
                'reserva_id': r[8]
            }
            for r in rows
        ]

    def mis_reservas(self, usuario_id):
        cliente_id = self._cliente_id(usuario_id)
        cursor = self.mysql.connection.cursor()
        cursor.execute(
            "SELECT r.res_id, r.res_fecha, r.res_hora, r.res_anticipo, r.res_estado, "
            "e.emp_nombre, e.emp_apellido, GROUP_CONCAT(s.ser_nombre SEPARATOR ', ') "
            "FROM reservas_web r "
            "LEFT JOIN empleados e ON e.emp_id = r.res_empleado_id "
            "LEFT JOIN detalle_reservas_web drv ON drv.drv_reserva_id = r.res_id "
            "LEFT JOIN servicios s ON s.ser_id = drv.drv_servicio_id "
            "WHERE r.res_cliente_id = %s "
            "GROUP BY r.res_id, r.res_fecha, r.res_hora, r.res_anticipo, r.res_estado, e.emp_nombre, e.emp_apellido "
            "ORDER BY r.res_fecha DESC, r.res_hora DESC",
            (cliente_id,),
        )
        rows = cursor.fetchall()
        cursor.close()
        return [
            {
                'id_reserva': r[0],
                'fecha': str(r[1]),
                'hora': str(r[2]),
                'anticipo': float(r[3] or 0),
                'estado': r[4],
                'empleado': f'{r[5] or ""} {r[6] or ""}'.strip(),
                'servicio': r[7],
            }
            for r in rows
        ]

    def historial_basico(self, usuario_id):
        return {
            'citas': self.mis_citas(usuario_id),
            'facturas': self.mis_facturas(usuario_id),
            'reservas': self.mis_reservas(usuario_id),
        }
