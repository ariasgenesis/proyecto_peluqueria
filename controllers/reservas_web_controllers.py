from flask import current_app, g, request

from controllers.base_controller import (
    error_response,
    listar,
    obtener,
    success_response,
    usuario_actual_id,
)
from services.base_service import ServiceError
from services.clientes_services import ClienteService
from services.reservas_web_services import ReservaWebService


def _validar_reserva_cliente(reserva):
    auth_user = getattr(g, 'auth_user', {}) or {}
    if auth_user.get('rol') != 'cliente':
        return
    cliente_id = ClienteService(current_app.mysql).obtener_cliente_id_por_usuario(auth_user.get('id_usuario'))
    if reserva.get('cliente_id') != cliente_id:
        raise ServiceError('No tienes permisos para acceder a esta reserva', 403)


def cntlistado_reservas_web():
    return listar(ReservaWebService)


def cntobtener_reserva_web(id_reserva):
    service = ReservaWebService(current_app.mysql)
    try:
        reserva = service.obtener_por_id(id_reserva)
        if not reserva:
            return error_response('Reserva web no encontrada', 404)
        _validar_reserva_cliente(reserva)
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Reserva web obtenida correctamente', reserva)


def cntcrear_reserva_web():
    service = ReservaWebService(current_app.mysql)
    try:
        data = service.crear(request.get_json(silent=True), usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Reserva creada correctamente', data, 201)


def cntactualizar_reserva_web(id_reserva):
    service = ReservaWebService(current_app.mysql)
    try:
        data = service.actualizar(id_reserva, request.get_json(silent=True), usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Reserva actualizada correctamente', data)


def cntcancelar_reserva_web(id_reserva):
    service = ReservaWebService(current_app.mysql)
    try:
        reserva = service.obtener_por_id(id_reserva)
        if not reserva:
            return error_response('Reserva web no encontrada', 404)
        _validar_reserva_cliente(reserva)
        service.cancelar(id_reserva, usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Reserva cancelada correctamente', {})
