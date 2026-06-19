from models.base_model import BaseModel


class FacturaModel(BaseModel):
    table = 'facturas'
    id_field = 'id_factura'
    id_column = 'fac_id'
    fields = [
        ('id_factura', 'fac_id', 'int'),
        ('cita_id', 'fac_cita_id', 'int'),
        ('reserva_id', 'fac_reserva_id', 'int'),
        ('fecha', 'fac_fecha', 'date'),
        ('total', 'fac_total', 'decimal'),
        ('anticipo', 'fac_anticipo', 'decimal'),
        ('saldo_pendiente', 'fac_saldo_pendiente', 'decimal'),
        ('tipo', 'fac_tipo', 'str'),
        ('estado', 'fac_estado', 'str'),
        ('inventario_procesado', 'fac_inventario_procesado', 'int'),
        ('generada_por', 'fac_generada_por', 'int'),
        ('modificada_por', 'fac_modificada_por', 'int'),
        ('fecha_modificacion', 'fac_fecha_modificacion', 'datetime'),
        ('created_at', 'created_at', 'datetime'),
        ('updated_at', 'updated_at', 'datetime'),
    ]
    writable_fields = [
        'cita_id',
        'reserva_id',
        'fecha',
        'total',
        'anticipo',
        'saldo_pendiente',
        'tipo',
        'estado',
        'inventario_procesado',
        'generada_por',
        'modificada_por',
        'fecha_modificacion',
    ]
    search_fields = []
    filter_fields = {
        'cita_id': 'fac_cita_id',
        'reserva_id': 'fac_reserva_id',
        'estado': 'fac_estado',
        'tipo': 'fac_tipo',
        'generada_por': 'fac_generada_por',
    }
    soft_delete_column = 'fac_estado'
    soft_delete_value = 'cancelada'
