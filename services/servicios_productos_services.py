from models.servicios_productos_model import ServicioProductoModel
from services.base_service import BaseCrudService


class ServicioProductoService(BaseCrudService):
    model = ServicioProductoModel
    schema = {'servicio_id': {'type': 'int', 'required': True, 'min': 1}, 'producto_id': {'type': 'int', 'required': True, 'min': 1}, 'cantidad': {'type': 'int', 'required': True, 'min': 1}}
