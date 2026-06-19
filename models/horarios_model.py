from models.base_model import BaseModel


class HorarioModel(BaseModel):
    table = 'horarios'
    id_field = 'id_horario'
    id_column = 'hor_id'
    fields = [('id_horario', 'hor_id', 'int'), ('empleado_id', 'hor_empleado_id', 'int'), ('dia_semana', 'hor_dia_semana', 'str'), ('hora_inicio', 'hor_hora_inicio', 'time'), ('hora_fin', 'hor_hora_fin', 'time'), ('created_at', 'created_at', 'datetime')]
    writable_fields = ['empleado_id', 'dia_semana', 'hora_inicio', 'hora_fin']
    search_fields = []
    filter_fields = {'empleado_id': 'hor_empleado_id', 'dia_semana': 'hor_dia_semana'}
    soft_delete_column = None
    soft_delete_value = None
