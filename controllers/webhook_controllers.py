from flask import current_app, request

from controllers.base_controller import error_response, success_response
from services.base_service import ServiceError
from services.wompi_services import WompiWebhookService


def cntwebhook_wompi():
    service = WompiWebhookService(current_app.mysql)
    try:
        data = service.procesar_evento(
            request.get_json(silent=True),
            request.headers.get('X-Event-Checksum'),
        )
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Evento Wompi procesado correctamente', data)
