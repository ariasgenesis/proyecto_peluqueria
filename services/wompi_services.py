import hashlib
import os

from services.base_service import ServiceError
from services.reservas_web_services import ReservaWebService


class WompiWebhookService:
    def __init__(self, mysql):
        self.mysql = mysql

    def _value_by_path(self, data, path):
        value = data
        for part in path.split('.'):
            if not isinstance(value, dict) or part not in value:
                return ''
            value = value[part]
        return value

    def _validar_checksum(self, payload, header_checksum):
        secret = os.getenv('WOMPI_EVENT_SECRET') or os.getenv('WOMPI_WEBHOOK_SECRET')
        if not secret:
            raise ServiceError('WOMPI_EVENT_SECRET no esta configurado', 500)
        signature = payload.get('signature') or {}
        properties = signature.get('properties') or []
        checksum = header_checksum or signature.get('checksum')
        if not checksum:
            raise ServiceError('Checksum Wompi ausente', 401)
        data = payload.get('data') or {}
        timestamp = payload.get('timestamp')
        base = ''.join(str(self._value_by_path(data, prop)) for prop in properties)
        base = f'{base}{timestamp}{secret}'
        calculado = hashlib.sha256(base.encode('utf-8')).hexdigest()
        if calculado != checksum:
            raise ServiceError('Checksum Wompi invalido', 401)

    def procesar_evento(self, payload, header_checksum=None):
        if not isinstance(payload, dict):
            raise ServiceError('El evento Wompi debe ser un objeto JSON')
        self._validar_checksum(payload, header_checksum)
        if payload.get('event') != 'transaction.updated':
            return {'ignored': True, 'reason': 'Evento Wompi no soportado'}
        transaction = (payload.get('data') or {}).get('transaction') or {}
        if transaction.get('status') != 'APPROVED':
            return {'ignored': True, 'status': transaction.get('status')}
        referencia = transaction.get('reference')
        transaccion_id = transaction.get('id')
        if not referencia or not transaccion_id:
            raise ServiceError('Evento Wompi sin referencia o transaccion')
        return ReservaWebService(self.mysql).confirmar_pago_wompi(referencia, transaccion_id)

