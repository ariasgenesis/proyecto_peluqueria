import re

from models.servicios_model import ServicioModel
from services.base_service import BaseCrudService


class ServicioService(BaseCrudService):
    model = ServicioModel
    schema = {'nombre': {'type': 'str', 'required': True, 'max': 100, 'regex': re.compile(r'^[A-Za-zÀ-ÿÑñ ]+$'), 'regex_error': 'El nombre del servicio solo puede contener letras y espacios'}, 'descripcion': {'type': 'str'}, 'precio': {'type': 'decimal', 'required': True}, 'duracion': {'type': 'int', 'required': True, 'min': 1}, 'estado': {'type': 'str', 'default': 'activo', 'enum': ['activo', 'inactivo'], 'lower': True}}
