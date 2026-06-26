import re

from models.productos_model import ProductoModel
from services.base_service import BaseCrudService, ServiceError
from services.empleados_services import EmpleadoService
from services.movimientos_services import MovimientoService


class ProductoService(BaseCrudService):
    model = ProductoModel
    schema = {
        'nombre': {
            'type': 'str', 
            'required': True, 
            'max': 100,
            'regex': re.compile(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$'),
            'regex_error': 'El nombre del producto solo puede contener letras y espacios'
        }, 
        'precio': {'type': 'decimal', 'required': True}, 
        'stock': {'type': 'int', 'default': 0, 'min': 0, 'max': 999999}, 
        'stock_minimo': {'type': 'int', 'default': 5, 'min': 0, 'max': 999999}, 
        'tipo_control': {'type': 'str', 'default': 'manual', 'enum': ['unitario', 'manual'], 'lower': True}, 
        'estado': {'type': 'str', 'default': 'activo', 'enum': ['activo', 'inactivo'], 'lower': True}
    }

    def listar_todos(self, page, per_page, filters=None, search=None, include_deleted=False):
        return self.model.listar_todos(self.mysql, page, per_page, filters, search, True)

    def actualizar(self, record_id, data, user_id=None):
        producto = super().actualizar(record_id, data, user_id)
        if user_id:
            MovimientoService(self.mysql).registrar(user_id, 'editar_producto', f'Producto #{record_id} actualizado')
        return producto

    def _ajustar_stock(self, producto_id, cantidad, user_id, pin, tipo_movimiento, descripcion):
        empleado_id = None
        if isinstance(pin, dict):
            empleado_id = pin.get('pin_empleado_id')
            pin = pin.get('pin')
        movimiento_usuario_id = EmpleadoService(self.mysql).validar_pin_usuario(user_id, pin, empleado_id)
        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute("SELECT pro_stock FROM productos WHERE pro_id = %s FOR UPDATE", (producto_id,))
            producto = cursor.fetchone()
            if not producto:
                raise ServiceError('Producto no encontrado', 404)
            nuevo_stock = producto[0] + cantidad
            if nuevo_stock < 0:
                raise ServiceError('Stock insuficiente')
            cursor.execute("UPDATE productos SET pro_stock = %s WHERE pro_id = %s", (nuevo_stock, producto_id))
            cursor.execute(
                "INSERT INTO movimientos (mov_usuario_id, mov_tipo, mov_descripcion) VALUES (%s, %s, %s)",
                (movimiento_usuario_id, tipo_movimiento, descripcion),
            )
            cursor.execute(
                "INSERT INTO movimientos_inventario (moi_producto_id, moi_usuario_id, moi_tipo, moi_cantidad, moi_descripcion) "
                "VALUES (%s, %s, %s, %s, %s)",
                (
                    producto_id,
                    movimiento_usuario_id,
                    'entrada' if cantidad > 0 else 'salida',
                    abs(cantidad),
                    descripcion,
                ),
            )
            self.mysql.connection.commit()
        except Exception:
            self.mysql.connection.rollback()
            raise
        finally:
            cursor.close()
        return self.model.obtener_por_id(self.mysql, producto_id)

    def agregar_stock(self, producto_id, data, user_id):
        cantidad = data.get('cantidad') if isinstance(data, dict) else None
        if isinstance(cantidad, bool) or not isinstance(cantidad, int) or cantidad <= 0:
            raise ServiceError('El campo \"cantidad\" debe ser un entero mayor que cero')
        return self._ajustar_stock(producto_id, cantidad, user_id, {'pin': data.get('pin'), 'pin_empleado_id': data.get('pin_empleado_id')}, 'agregar_stock', f'Se agregaron {cantidad} unidades al producto #{producto_id}')

    def descontar_stock(self, producto_id, data, user_id):
        cantidad = data.get('cantidad') if isinstance(data, dict) else None
        if isinstance(cantidad, bool) or not isinstance(cantidad, int) or cantidad <= 0:
            raise ServiceError('El campo \"cantidad\" debe ser un entero mayor que cero')
        return self._ajustar_stock(producto_id, -cantidad, user_id, {'pin': data.get('pin'), 'pin_empleado_id': data.get('pin_empleado_id')}, 'descontar_stock', f'Se descontaron {cantidad} unidades del producto #{producto_id}')

    def editar_stock(self, producto_id, data, user_id):
        if not isinstance(data, dict):
            raise ServiceError('El cuerpo de la solicitud debe ser un objeto JSON')
        stock = data.get('stock')
        if isinstance(stock, bool) or not isinstance(stock, int) or stock < 0:
            raise ServiceError('El campo \"stock\" debe ser un entero mayor o igual a cero')
        movimiento_usuario_id = EmpleadoService(self.mysql).validar_pin_usuario(user_id, data.get('pin'), data.get('pin_empleado_id'))
        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute("SELECT pro_stock FROM productos WHERE pro_id = %s FOR UPDATE", (producto_id,))
            actual = cursor.fetchone()
            if not actual:
                raise ServiceError('Producto no encontrado', 404)
            diferencia = stock - actual[0]
            cursor.execute("UPDATE productos SET pro_stock = %s WHERE pro_id = %s", (stock, producto_id))
            cursor.execute(
                "INSERT INTO movimientos (mov_usuario_id, mov_tipo, mov_descripcion) VALUES (%s, 'editar_producto', %s)",
                (movimiento_usuario_id, f'Stock del producto #{producto_id} actualizado a {stock}'),
            )
            if diferencia != 0:
                cursor.execute(
                    "INSERT INTO movimientos_inventario (moi_producto_id, moi_usuario_id, moi_tipo, moi_cantidad, moi_descripcion) "
                    "VALUES (%s, %s, 'ajuste', %s, %s)",
                    (producto_id, movimiento_usuario_id, abs(diferencia), f'Ajuste de stock a {stock}'),
                )
            self.mysql.connection.commit()
        except Exception:
            self.mysql.connection.rollback()
            raise
        finally:
            cursor.close()
        return self.model.obtener_por_id(self.mysql, producto_id)

    def stock_bajo(self, page, per_page):
        cursor = self.mysql.connection.cursor()
        cursor.execute("SELECT COUNT(*) FROM productos WHERE pro_estado = 'activo' AND pro_stock <= pro_stock_minimo")
        total = cursor.fetchone()[0]
        offset = (page - 1) * per_page
        cursor.execute(
            "SELECT pro_id, pro_nombre, pro_precio, pro_stock, pro_stock_minimo, pro_tipo_control, pro_estado, created_at, updated_at "
            "FROM productos WHERE pro_estado = 'activo' AND pro_stock <= pro_stock_minimo "
            "ORDER BY pro_stock ASC LIMIT %s OFFSET %s",
            (per_page, offset)
        )
        rows = cursor.fetchall()
        cursor.close()
        return {
            'data': [self.model._from_row(row) for row in rows],
            'total': total,
            'page': page,
            'per_page': per_page,
            'total_pages': (total + per_page - 1) // per_page if total else 0
        }
