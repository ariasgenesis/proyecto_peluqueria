from models.base_model import BaseModel


class CitaModel(BaseModel):
    table = 'citas'
    id_field = 'id_cita'
    id_column = 'cit_id'
    fields = [('id_cita', 'cit_id', 'int'), ('cliente_id', 'cit_cliente_id', 'int'), ('empleado_id', 'cit_empleado_id', 'int'), ('fecha', 'cit_fecha', 'date'), ('hora', 'cit_hora', 'time'), ('origen', 'cit_origen', 'str'), ('estado', 'cit_estado', 'str'), ('creado_por', 'cit_creado_por', 'int'), ('created_at', 'created_at', 'datetime'), ('updated_at', 'updated_at', 'datetime')]
    writable_fields = ['cliente_id', 'empleado_id', 'fecha', 'hora', 'origen', 'estado', 'creado_por']
    search_fields = []
    filter_fields = {'cliente_id': 'cit_cliente_id', 'empleado_id': 'cit_empleado_id', 'fecha': 'cit_fecha', 'origen': 'cit_origen', 'estado': 'cit_estado'}
    soft_delete_column = 'cit_estado'
    soft_delete_value = 'cancelada'
