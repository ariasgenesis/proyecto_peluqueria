from models.detalles_citas_model import DetalleCitaModel
from services.base_service import BaseCrudService


class DetalleCitaService(BaseCrudService):
    model = DetalleCitaModel
    schema = {'cita_id': {'type': 'int', 'required': True, 'min': 1}, 'servicio_id': {'type': 'int', 'required': True, 'min': 1}, 'precio': {'type': 'decimal', 'required': True}}
