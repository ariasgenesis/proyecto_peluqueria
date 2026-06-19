from models.base_model import BaseModel


class ClienteModel(BaseModel):
    table = 'clientes'
    id_field = 'id_cliente'
    id_column = 'cli_id'
    fields = [('id_cliente', 'cli_id', 'int'), ('usuario_id', 'cli_usuario_id', 'int'), ('nombre', 'cli_nombre', 'str'), ('apellido', 'cli_apellido', 'str'), ('telefono', 'cli_telefono', 'str'), ('direccion', 'cli_direccion', 'str'), ('estado', 'cli_estado', 'str'), ('created_at', 'created_at', 'datetime'), ('updated_at', 'updated_at', 'datetime')]
    writable_fields = ['usuario_id', 'nombre', 'apellido', 'telefono', 'direccion', 'estado']
    search_fields = ['cli_nombre', 'cli_apellido', 'cli_telefono', 'cli_direccion']
    filter_fields = {'usuario_id': 'cli_usuario_id', 'estado': 'cli_estado'}
    soft_delete_column = 'cli_estado'
    soft_delete_value = 'inactivo'
