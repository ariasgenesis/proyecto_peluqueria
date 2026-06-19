from models.base_model import BaseModel


class PagoModel(BaseModel):
    table = 'pagos'
    id_field = 'id_pago'
    id_column = 'pag_id'
    fields = [('id_pago', 'pag_id', 'int'), ('factura_id', 'pag_factura_id', 'int'), ('metodo', 'pag_metodo', 'str'), ('estado', 'pag_estado', 'str'), ('fecha', 'pag_fecha', 'date'), ('monto', 'pag_monto', 'decimal'), ('referencia', 'pag_referencia', 'str'), ('transaccion_id', 'pag_transaccion_id', 'str'), ('created_at', 'created_at', 'datetime')]
    writable_fields = ['factura_id', 'metodo', 'estado', 'fecha', 'monto', 'referencia', 'transaccion_id']
    search_fields = []
    filter_fields = {'factura_id': 'pag_factura_id', 'metodo': 'pag_metodo', 'estado': 'pag_estado'}
    soft_delete_column = 'pag_estado'
    soft_delete_value = 'cancelado'
