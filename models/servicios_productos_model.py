from models.base_model import BaseModel


class ServicioProductoModel(BaseModel):
    table = 'servicios_productos'
    id_field = 'id_servicio_producto'
    id_column = 'sep_id'
    fields = [('id_servicio_producto', 'sep_id', 'int'), ('servicio_id', 'sep_servicio_id', 'int'), ('producto_id', 'sep_producto_id', 'int'), ('cantidad', 'sep_cantidad', 'int')]
    writable_fields = ['servicio_id', 'producto_id', 'cantidad']
    search_fields = []
    filter_fields = {'servicio_id': 'sep_servicio_id', 'producto_id': 'sep_producto_id'}
    soft_delete_column = None
    soft_delete_value = None
