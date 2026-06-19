from models.base_model import BaseModel


class UsuarioModel(BaseModel):
    table = 'usuarios'
    id_field = 'id_usuario'
    id_column = 'usu_id'
    fields = [('id_usuario', 'usu_id', 'int'), ('username', 'usu_username', 'str'), ('password', 'usu_password', 'str'), ('email', 'usu_email', 'str'), ('rol', 'usu_rol', 'str'), ('estado', 'usu_estado', 'str'), ('created_at', 'created_at', 'datetime'), ('updated_at', 'updated_at', 'datetime')]
    writable_fields = ['username', 'password', 'email', 'rol', 'estado']
    search_fields = ['usu_username', 'usu_email']
    filter_fields = {'rol': 'usu_rol', 'estado': 'usu_estado'}
    soft_delete_column = 'usu_estado'
    soft_delete_value = 'inactivo'

    def to_dict(self):
        data = super().to_dict()
        data.pop('password', None)
        return data
