from models.base_model import BaseModel


class EmpleadoModel(BaseModel):
    table = 'empleados'
    id_field = 'id_empleado'
    id_column = 'emp_id'
    fields = [('id_empleado', 'emp_id', 'int'), ('usuario_id', 'emp_usuario_id', 'int'), ('nombre', 'emp_nombre', 'str'), ('apellido', 'emp_apellido', 'str'), ('documento', 'emp_documento', 'str'), ('telefono', 'emp_telefono', 'str'), ('cargo', 'emp_cargo', 'str'), ('pin', 'emp_pin', 'str'), ('estado', 'emp_estado', 'str'), ('created_at', 'created_at', 'datetime'), ('updated_at', 'updated_at', 'datetime')]
    writable_fields = ['usuario_id', 'nombre', 'apellido', 'documento', 'telefono', 'cargo', 'pin', 'estado']
    search_fields = ['emp_nombre', 'emp_apellido', 'emp_documento', 'emp_telefono', 'emp_cargo']
    filter_fields = {'usuario_id': 'emp_usuario_id', 'cargo': 'emp_cargo', 'estado': 'emp_estado'}
    soft_delete_column = 'emp_estado'
    soft_delete_value = 'bloqueado'

    def to_dict(self):
        data = super().to_dict()
        data.pop('pin', None)
        return data
