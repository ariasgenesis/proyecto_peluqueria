from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from flask import current_app, request

from controllers.base_controller import error_response, success_response, usuario_actual_id
from services.base_service import ServiceError
from services.citas_services import CitaService


def cntlistado_citas():
    return listar(CitaService)


def cntobtener_cita(id_cita):
    return obtener(CitaService, id_cita, 'Cita')


def cntcrear_cita():
    return crear(CitaService, 'Cita')


def cntactualizar_cita(id_cita):
    return actualizar(CitaService, id_cita, 'Cita')


def cnteditar_dinamica_cita(id_cita):
    service = CitaService(current_app.mysql)
    try:
        data = service.editar_dinamica(id_cita, request.get_json(silent=True), usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Cita actualizada correctamente', data)


def cnteliminar_cita(id_cita):
    return eliminar(CitaService, id_cita, 'Cita')
