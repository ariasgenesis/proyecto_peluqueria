from models.servicios_productos_model import ServicioProductoModel
from services.base_service import BaseCrudService
from services.servicios_services import ServicioService


class ServicioProductoService(BaseCrudService):
    model = ServicioProductoModel
    schema = {'servicio_id': {'type': 'int', 'required': True, 'min': 1}, 'producto_id': {'type': 'int', 'required': True, 'min': 1}, 'cantidad': {'type': 'int', 'default': 1, 'min': 1}}

    def crear(self, data, user_id=None):
        payload = dict(data or {})
        payload['cantidad'] = 1
        row = super().crear(payload, user_id)
        row['servicios_actualizados'] = ServicioService(self.mysql).sincronizar_estados_por_stock(servicio_ids=[row['servicio_id']])
        return row

    def actualizar(self, record_id, data, user_id=None):
        actual = self.model.obtener_por_id(self.mysql, record_id)
        payload = dict(data or {})
        payload['cantidad'] = 1
        row = super().actualizar(record_id, payload, user_id)
        servicio_ids = [row['servicio_id']]
        if actual:
            servicio_ids.append(actual['servicio_id'])
        row['servicios_actualizados'] = ServicioService(self.mysql).sincronizar_estados_por_stock(servicio_ids=servicio_ids)
        return row

    def eliminar(self, record_id, user_id=None):
        actual = self.model.obtener_por_id(self.mysql, record_id)
        result = super().eliminar(record_id, user_id)
        if actual:
            result = {
                'eliminado': result,
                'servicios_actualizados': ServicioService(self.mysql).sincronizar_estados_por_stock(servicio_ids=[actual['servicio_id']]),
            }
        return result
