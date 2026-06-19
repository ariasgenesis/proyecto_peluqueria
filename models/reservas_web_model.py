from models.base_model import BaseModel


class ReservaWebModel(BaseModel):
    table = 'reservas_web'
    id_field = 'id_reserva'
    id_column = 'res_id'
    fields = [
        ('id_reserva', 'res_id', 'int'),
        ('cliente_id', 'res_cliente_id', 'int'),
        ('empleado_id', 'res_empleado_id', 'int'),
        ('fecha', 'res_fecha', 'date'),
        ('hora', 'res_hora', 'time'),
        ('anticipo', 'res_anticipo', 'decimal'),
        ('estado', 'res_estado', 'str'),
        ('referencia_pago', 'res_referencia_pago', 'str'),
        ('transaccion_id', 'res_transaccion_id', 'str'),
        ('created_at', 'created_at', 'datetime'),
    ]
    writable_fields = [
        'cliente_id',
        'empleado_id',
        'fecha',
        'hora',
        'anticipo',
        'estado',
        'referencia_pago',
        'transaccion_id',
    ]
    search_fields = ['res_referencia_pago', 'res_transaccion_id']
    filter_fields = {
        'cliente_id': 'res_cliente_id',
        'empleado_id': 'res_empleado_id',
        'fecha': 'res_fecha',
        'estado': 'res_estado',
    }
    soft_delete_column = 'res_estado'
    soft_delete_value = 'cancelada'
