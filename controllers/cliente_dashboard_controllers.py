from flask import current_app

from controllers.base_controller import error_response, success_response, usuario_actual_id
from services.base_service import ServiceError
from services.cliente_dashboard_services import ClienteDashboardService


def cntmis_citas():
    try:
        data = ClienteDashboardService(current_app.mysql).mis_citas(usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Citas del cliente obtenidas correctamente', data)


def cntmis_facturas():
    try:
        data = ClienteDashboardService(current_app.mysql).mis_facturas(usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Facturas del cliente obtenidas correctamente', data)


def cnthistorial_basico():
    try:
        data = ClienteDashboardService(current_app.mysql).historial_basico(usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Historial del cliente obtenido correctamente', data)
