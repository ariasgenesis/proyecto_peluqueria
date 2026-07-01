from flask import current_app, request

from controllers.base_controller import error_response, success_response
from services.auditoria_services import AuditoriaService
from services.base_service import ServiceError


def cnt_auditoria_resumen():
    empleado_id  = request.args.get('empleado_id')
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin    = request.args.get('fecha_fin')

    # Convertir empleado_id a int si viene como string no vacio
    if empleado_id not in (None, '', 'todos'):
        try:
            empleado_id = int(empleado_id)
        except (TypeError, ValueError):
            empleado_id = None
    else:
        empleado_id = None

    try:
        data = AuditoriaService(current_app.mysql).resumen(
            empleado_id=empleado_id,
            fecha_inicio=fecha_inicio or None,
            fecha_fin=fecha_fin or None,
        )
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    except Exception as exc:
        return error_response('Error al procesar la auditoria: ' + str(exc), 500)

    return success_response('Resumen de auditoria obtenido correctamente', data)
