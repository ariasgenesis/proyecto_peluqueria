from models.base_model import BaseModel


class ProductoModel(BaseModel):
    table = 'productos'
    id_field = 'id_producto'
    id_column = 'pro_id'
    fields = [('id_producto', 'pro_id', 'int'), ('nombre', 'pro_nombre', 'str'), ('precio', 'pro_precio', 'decimal'), ('stock', 'pro_stock', 'int'), ('stock_minimo', 'pro_stock_minimo', 'int'), ('tipo_control', 'pro_tipo_control', 'str'), ('estado', 'pro_estado', 'str'), ('created_at', 'created_at', 'datetime'), ('updated_at', 'updated_at', 'datetime')]
    writable_fields = ['nombre', 'precio', 'stock', 'stock_minimo', 'tipo_control', 'estado']
    search_fields = ['pro_nombre']
    filter_fields = {'estado': 'pro_estado', 'tipo_control': 'pro_tipo_control'}
    soft_delete_column = 'pro_estado'
    soft_delete_value = 'inactivo'
