from flask import current_app, request

from controllers.base_controller import error_response, success_response
from services.auditoria_personal_services import AuditoriaPersonalService
from services.base_service import ServiceError


def cntauditoria_personal():
    service = AuditoriaPersonalService(current_app.mysql)
    try:
        data = service.reporte(
            empleado_id=request.args.get('empleado_id'),
            fecha_inicio=request.args.get('fecha_inicio'),
            fecha_fin=request.args.get('fecha_fin'),
        )
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Auditoria de personal obtenida correctamente', data)
