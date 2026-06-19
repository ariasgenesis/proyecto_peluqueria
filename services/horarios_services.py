from models.horarios_model import HorarioModel
from services.base_service import BaseCrudService


class HorarioService(BaseCrudService):
    model = HorarioModel
    schema = {'empleado_id': {'type': 'int', 'required': True, 'min': 1}, 'dia_semana': {'type': 'str', 'required': True, 'enum': ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'], 'lower': True}, 'hora_inicio': {'type': 'time', 'required': True}, 'hora_fin': {'type': 'time', 'required': True}}
