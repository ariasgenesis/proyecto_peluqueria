from models.base_model import BaseModel


class DetalleCitaModel(BaseModel):
    table = 'detalle_citas'
    id_field = 'id_detalle_cita'
    id_column = 'dci_id'
    fields = [('id_detalle_cita', 'dci_id', 'int'), ('cita_id', 'dci_cita_id', 'int'), ('servicio_id', 'dci_servicio_id', 'int'), ('precio', 'dci_precio', 'decimal')]
    writable_fields = ['cita_id', 'servicio_id', 'precio']
    search_fields = []
    filter_fields = {'cita_id': 'dci_cita_id', 'servicio_id': 'dci_servicio_id'}
    soft_delete_column = None
    soft_delete_value = None
