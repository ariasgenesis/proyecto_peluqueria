from models.usuarios_model import UsuarioModel
from services.base_service import BaseCrudService


class UsuarioService(BaseCrudService):
    model = UsuarioModel
    schema = {'username': {'type': 'str', 'required': True, 'max': 50}, 'password': {'type': 'str', 'required': True, 'max': 255, 'password': True}, 'email': {'type': 'str', 'required': True, 'max': 100}, 'rol': {'type': 'str', 'required': True, 'enum': ['admin', 'empleado', 'cliente'], 'lower': True}, 'estado': {'type': 'str', 'default': 'activo', 'enum': ['activo', 'inactivo', 'bloqueado'], 'lower': True}}
