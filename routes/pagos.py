import hashlib
import os
import time

import requests as http_requests
from flask import Blueprint, current_app, g, request

from controllers.base_controller import error_response, success_response
from controllers.pagos_controllers import (
    cntactualizar_pago,
    cntcrear_pago,
    cnteliminar_pago,
    cntlistado_pagos,
    cntobtener_pago,
)
from middlewares.auth_middleware import role_required
from services.base_service import ServiceError
from services.reservas_web_services import ReservaWebService

WOMPI_SANDBOX = 'https://sandbox.wompi.co/v1'

pago_bp = Blueprint('pagos', __name__)


@pago_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_pagos()


@pago_bp.route('/<int:id_pago>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_pago):
    return cntobtener_pago(id_pago)


@pago_bp.route('/', methods=['POST'])
@role_required('admin', 'empleado')
def crear_registro():
    return cntcrear_pago()


@pago_bp.route('/<int:id_pago>', methods=['PUT'])
@role_required('admin', 'empleado')
def actualizar_registro(id_pago):
    return cntactualizar_pago(id_pago)


@pago_bp.route('/<int:id_pago>', methods=['DELETE'])
@role_required('admin', 'empleado')
def eliminar_registro(id_pago):
    return cnteliminar_pago(id_pago)


@pago_bp.route('/nequi', methods=['POST'])
@role_required('cliente')
def crear_pago_nequi():
    """POST /pagos/nequi - inicia transaccion Wompi Nequi push."""
    data = request.get_json(silent=True) or {}
    referencia = data.get('referencia', '').strip()
    amount_cents = data.get('amount_in_cents')
    telefono = str(data.get('telefono', '')).strip()

    if not referencia or not amount_cents or not telefono:
        return error_response('referencia, amount_in_cents y telefono son requeridos', 400)
    if not telefono.isdigit() or len(telefono) < 10:
        return error_response('Numero de celular invalido (minimo 10 digitos)', 400)

    cursor = current_app.mysql.connection.cursor()
    cursor.execute('SELECT usu_email FROM usuarios WHERE usu_id = %s', (g.auth_user['id_usuario'],))
    row = cursor.fetchone()
    cursor.close()
    email = row[0] if row else 'cliente@beutycore.co'

    private_key = os.getenv('WOMPI_PRIVATE_KEY', '')
    if not private_key:
        return error_response('WOMPI_PRIVATE_KEY no esta configurada en el servidor', 503)

    referencia_wompi = f"{referencia}-{int(time.time())}"

    cursor2 = current_app.mysql.connection.cursor()
    cursor2.execute(
        "UPDATE reservas_web SET res_referencia_pago = %s WHERE res_referencia_pago = %s",
        (referencia_wompi, referencia),
    )
    current_app.mysql.connection.commit()
    cursor2.close()

    public_key = os.getenv('WOMPI_PUBLIC_KEY', '')
    try:
        acc_resp = http_requests.get(f'{WOMPI_SANDBOX}/merchants/{public_key}', timeout=10)
        acceptance_token = acc_resp.json().get('data', {}).get('presigned_acceptance', {}).get('acceptance_token', '')
    except http_requests.RequestException:
        return error_response('No se pudo obtener el token de aceptacion de Wompi', 502)

    integrity_secret = os.getenv('WOMPI_INTEGRITY_SECRET', '')
    integrity_str = f"{referencia_wompi}{int(amount_cents)}COP{integrity_secret}"
    signature = hashlib.sha256(integrity_str.encode()).hexdigest()

    wompi_payload = {
        'amount_in_cents': int(amount_cents),
        'currency': 'COP',
        'customer_email': email,
        'payment_method': {'type': 'NEQUI', 'phone_number': telefono},
        'reference': referencia_wompi,
        'signature': signature,
        'acceptance_token': acceptance_token,
    }
    try:
        resp = http_requests.post(
            f'{WOMPI_SANDBOX}/transactions',
            json=wompi_payload,
            headers={'Authorization': f'Bearer {private_key}', 'Content-Type': 'application/json'},
            timeout=15,
        )
        body = resp.json()
        current_app.logger.info('Wompi Nequi response %s: %s', resp.status_code, body)
        if not resp.ok:
            error = body.get('error', {})
            reason = error.get('reason') or error.get('type', 'Error Wompi')
            messages = error.get('messages', {})
            if messages:
                detail = '; '.join(f'{k}: {", ".join(v) if isinstance(v, list) else v}' for k, v in messages.items())
                reason = f'{reason} - {detail}'
            return error_response(reason, 502)
        tx = body.get('data', {})
        return success_response('Transaccion Nequi iniciada', {
            'transaction_id': tx.get('id'),
            'status': tx.get('status'),
        })
    except http_requests.RequestException:
        current_app.logger.exception('Error conectando con Wompi Nequi API')
        return error_response('No se pudo conectar con Wompi', 502)


@pago_bp.route('/estado/<transaction_id>', methods=['GET'])
@role_required('cliente')
def estado_transaccion(transaction_id):
    """GET /pagos/estado/<transaction_id> - consulta y confirma si Wompi aprobo."""
    private_key = os.getenv('WOMPI_PRIVATE_KEY', '')
    try:
        resp = http_requests.get(
            f'{WOMPI_SANDBOX}/transactions/{transaction_id}',
            headers={'Authorization': f'Bearer {private_key}'},
            timeout=10,
        )
        body = resp.json()
        if not resp.ok:
            return error_response('No se pudo consultar el estado', 502)
        tx = body.get('data', {})
        confirmacion = None
        if tx.get('status') == 'APPROVED' and tx.get('reference') and tx.get('id'):
            try:
                confirmacion = ReservaWebService(current_app.mysql).confirmar_pago_wompi(
                    tx.get('reference'),
                    tx.get('id'),
                    g.auth_user.get('id_usuario'),
                )
            except ServiceError as exc:
                return error_response(exc.message, exc.status_code)
        return success_response('Estado de transaccion', {
            'transaction_id': tx.get('id'),
            'status': tx.get('status'),
            'reference': tx.get('reference'),
            'confirmacion': confirmacion,
        })
    except http_requests.RequestException:
        current_app.logger.exception('Error consultando estado Wompi')
        return error_response('No se pudo consultar el estado', 502)
