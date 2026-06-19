from models.base_model import BaseModel


class MovimientoModel(BaseModel):
    table = 'movimientos'
    id_field = 'id_movimiento'
    id_column = 'mov_id'
    fields = [('id_movimiento', 'mov_id', 'int'), ('usuario_id', 'mov_usuario_id', 'int'), ('tipo', 'mov_tipo', 'str'), ('descripcion', 'mov_descripcion', 'str'), ('fecha', 'mov_fecha', 'datetime')]
    writable_fields = ['usuario_id', 'tipo', 'descripcion']
    search_fields = ['mov_tipo', 'mov_descripcion']
    filter_fields = {'usuario_id': 'mov_usuario_id', 'tipo': 'mov_tipo'}
    soft_delete_column = None
    soft_delete_value = None
