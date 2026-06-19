from flask import Blueprint, current_app, request

from controllers.base_controller import error_response, success_response
from controllers.servicios_controllers import cntlistado_servicios
from services.base_service import ServiceError
from services.citas_services import CitaService


publico_bp = Blueprint('publico', __name__)


@publico_bp.route('/servicios', methods=['GET'])
def servicios_publicos():
    """Listado de servicios activos para el sitio web publico (sin JWT)."""
    return cntlistado_servicios()


@publico_bp.route('/disponibilidad', methods=['GET'])
def disponibilidad_publica():
    try:
        servicio_id = int(request.args.get('servicio_id', ''))
    except ValueError:
        return error_response('El parametro servicio_id debe ser un numero entero', 400)

    try:
        fecha = request.args.get('fecha')
        hora = request.args.get('hora')
        if not fecha or not hora:
            return error_response('Los parametros fecha y hora son requeridos', 400)
        CitaService(current_app.mysql).buscar_empleado_disponible(servicio_id, fecha, hora)
    except ValueError:
        return error_response('La fecha o la hora no tienen un formato valido', 400)
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Horario disponible', {'disponible': True})
