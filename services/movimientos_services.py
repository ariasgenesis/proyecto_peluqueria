from models.movimientos_model import MovimientoModel
from models.movimientos_inventario_model import MovimientoInventarioModel
from services.base_service import BaseCrudService


class MovimientoService(BaseCrudService):
    model = MovimientoModel
    schema = {'usuario_id': {'type': 'int', 'required': True, 'min': 1}, 'tipo': {'type': 'str', 'required': True, 'enum': ['crear_factura', 'editar_factura', 'eliminar_factura', 'crear_cita', 'cancelar_cita', 'completar_cita', 'crear_reserva_web', 'confirmar_pago_wompi', 'agregar_stock', 'descontar_stock', 'editar_producto'], 'lower': True}, 'descripcion': {'type': 'str'}}

    def registrar(self, usuario_id, tipo, descripcion):
        if not usuario_id:
            return None
        return self.model.crear(
            self.mysql,
            usuario_id=usuario_id,
            tipo=tipo,
            descripcion=descripcion
        )


class MovimientoInventarioService(BaseCrudService):
    model = MovimientoInventarioModel
    schema = {
        'producto_id': {'type': 'int', 'required': True, 'min': 1},
        'usuario_id': {'type': 'int', 'required': True, 'min': 1},
        'factura_id': {'type': 'int', 'min': 1},
        'servicio_id': {'type': 'int', 'min': 1},
        'tipo': {'type': 'str', 'required': True, 'enum': ['entrada', 'salida', 'ajuste'], 'lower': True},
        'cantidad': {'type': 'int', 'required': True, 'min': 1},
        'descripcion': {'type': 'str'},
    }

    def listar_todos(self, page, per_page, filters=None, search=None, include_deleted=False):
        where_sql, params = self._where_clause(filters, search)
        cursor = self.mysql.connection.cursor()
        cursor.execute(
            "SELECT COUNT(*) FROM movimientos_inventario m "
            "LEFT JOIN productos p ON p.pro_id = m.moi_producto_id "
            "LEFT JOIN usuarios u ON u.usu_id = m.moi_usuario_id "
            "LEFT JOIN empleados e ON e.emp_usuario_id = u.usu_id "
            f"{where_sql}",
            tuple(params),
        )
        total = cursor.fetchone()[0]
        offset = (page - 1) * per_page
        cursor.execute(
            self._select_movimientos_sql(where_sql) + " ORDER BY m.created_at DESC, m.moi_id DESC LIMIT %s OFFSET %s",
            tuple(params + [per_page, offset]),
        )
        rows = cursor.fetchall()
        cursor.close()
        return {
            'data': [self._row_to_dict(row) for row in rows],
            'total': total,
            'page': page,
            'per_page': per_page,
            'total_pages': (total + per_page - 1) // per_page if total else 0,
        }

    def obtener_por_id(self, record_id):
        cursor = self.mysql.connection.cursor()
        cursor.execute(self._select_movimientos_sql("WHERE m.moi_id = %s"), (record_id,))
        row = cursor.fetchone()
        cursor.close()
        return self._row_to_dict(row) if row else None

    def _where_clause(self, filters=None, search=None):
        clauses = []
        params = []
        filters = filters or {}
        field_map = {
            'producto_id': 'm.moi_producto_id',
            'usuario_id': 'm.moi_usuario_id',
            'tipo': 'm.moi_tipo',
            'factura_id': 'm.moi_factura_id',
            'servicio_id': 'm.moi_servicio_id',
        }
        for public_name, column in field_map.items():
            value = filters.get(public_name)
            if value not in (None, ''):
                clauses.append(f"{column} = %s")
                params.append(value)
        if search:
            clauses.append(
                "(m.moi_descripcion LIKE %s OR m.moi_tipo LIKE %s OR p.pro_nombre LIKE %s "
                "OR u.usu_username LIKE %s OR e.emp_nombre LIKE %s OR e.emp_apellido LIKE %s)"
            )
            params.extend([f"%{search}%"] * 6)
        return (' WHERE ' + ' AND '.join(clauses) if clauses else ''), params

    def _select_movimientos_sql(self, where_sql):
        return (
            "SELECT m.moi_id, m.moi_producto_id, m.moi_usuario_id, m.moi_factura_id, "
            "m.moi_servicio_id, m.moi_tipo, m.moi_cantidad, m.moi_descripcion, m.created_at, "
            "p.pro_nombre, u.usu_username, e.emp_nombre, e.emp_apellido "
            "FROM movimientos_inventario m "
            "LEFT JOIN productos p ON p.pro_id = m.moi_producto_id "
            "LEFT JOIN usuarios u ON u.usu_id = m.moi_usuario_id "
            "LEFT JOIN empleados e ON e.emp_usuario_id = u.usu_id "
            f"{where_sql}"
        )

    def _row_to_dict(self, row):
        usuario = f'{row[11] or ""} {row[12] or ""}'.strip() or row[10]
        return {
            'id_movimiento_inv': row[0],
            'producto_id': row[1],
            'usuario_id': row[2],
            'factura_id': row[3],
            'servicio_id': row[4],
            'tipo': row[5],
            'cantidad': row[6],
            'descripcion': row[7],
            'fecha': str(row[8]) if row[8] is not None else None,
            'producto': row[9],
            'producto_nombre': row[9],
            'usuario': usuario,
            'usuario_nombre': usuario,
        }
