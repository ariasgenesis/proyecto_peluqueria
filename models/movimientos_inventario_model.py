from models.base_model import BaseModel


class MovimientoInventarioModel(BaseModel):
    """
    Representa un registro de entrada o salida física de productos del inventario.
    """
    table = 'movimientos_inventario'
    id_field = 'id_movimiento_inv'
    id_column = 'moi_id'
    
    # Mapeo de campos: (nombre_atributo, nombre_columna_db, tipo)
    fields = [
        ('id_movimiento_inv', 'moi_id', 'int'),
        ('producto_id', 'moi_producto_id', 'int'),
        ('usuario_id', 'moi_usuario_id', 'int'),
        ('factura_id', 'moi_factura_id', 'int'),
        ('servicio_id', 'moi_servicio_id', 'int'),
        ('tipo', 'moi_tipo', 'str'),
        ('cantidad', 'moi_cantidad', 'int'),
        ('descripcion', 'moi_descripcion', 'str'),
        ('fecha', 'created_at', 'datetime'),
    ]
    
    writable_fields = ['producto_id', 'usuario_id', 'factura_id', 'servicio_id', 'tipo', 'cantidad', 'descripcion']
    
    search_fields = ['moi_descripcion', 'moi_tipo']
    
    filter_fields = {
        'producto_id': 'moi_producto_id',
        'usuario_id': 'moi_usuario_id',
        'tipo': 'moi_tipo',
        'factura_id': 'moi_factura_id',
        'servicio_id': 'moi_servicio_id',
    }
    
    soft_delete_column = None
    soft_delete_value = None

    @classmethod
    def registrar_entrada(cls, mysql, producto_id, usuario_id, cantidad, descripcion):
        """Atajo para registrar un aumento de stock."""
        return cls.crear(
            mysql,
            producto_id=producto_id,
            usuario_id=usuario_id,
            cantidad=abs(cantidad),
            tipo='entrada',
            descripcion=descripcion,
        )

    @classmethod
    def registrar_salida(cls, mysql, producto_id, usuario_id, cantidad, descripcion):
        """Atajo para registrar una disminución de stock."""
        return cls.crear(
            mysql,
            producto_id=producto_id,
            usuario_id=usuario_id,
            cantidad=abs(cantidad),
            tipo='salida',
            descripcion=descripcion,
        )
