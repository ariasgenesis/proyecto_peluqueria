from flask import Blueprint, current_app, request

from controllers.base_controller import error_response, success_response
from controllers.reservas_web_controllers import (
    cntactualizar_reserva_web,
    cntcancelar_reserva_web,
    cntcrear_reserva_web,
    cntlistado_reservas_web,
    cntobtener_reserva_web,
)
from middlewares.auth_middleware import role_required
from services.reservas_web_services import ReservaWebService

_ESTADOS_VALIDOS = {'pendiente', 'pagada', 'cancelada'}

reserva_web_bp = Blueprint('reservas_web', __name__)


@reserva_web_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    try:
        page     = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 20))
    except (TypeError, ValueError):
        return error_response('Los parámetros "page" y "per_page" deben ser números enteros', 400)
    if page <= 0 or per_page <= 0:
        return error_response('Los parámetros "page" y "per_page" deben ser mayores que cero', 400)
    if per_page > 100:
        return error_response('El parámetro "per_page" no puede ser mayor que 100', 400)

    estado_raw = (request.args.get('estado') or '').strip().lower() or None
    if estado_raw and estado_raw not in _ESTADOS_VALIDOS:
        return error_response(f'El estado debe ser uno de: {", ".join(sorted(_ESTADOS_VALIDOS))}', 400)

    data = ReservaWebService(current_app.mysql).listar_admin(page, per_page, estado_raw)
    return success_response('Reservas web obtenidas', data)


@reserva_web_bp.route('/<int:id_reserva>', methods=['GET'])
@role_required('admin', 'empleado', 'cliente')
def obtener_registro(id_reserva):
    return cntobtener_reserva_web(id_reserva)


@reserva_web_bp.route('/', methods=['POST'])
@role_required('cliente')
def crear_registro():
    return cntcrear_reserva_web()


@reserva_web_bp.route('/<int:id_reserva>', methods=['PUT'])
@role_required('admin', 'empleado')
def actualizar_registro(id_reserva):
    return cntactualizar_reserva_web(id_reserva)


@reserva_web_bp.route('/<int:id_reserva>/cancelar', methods=['POST'])
@role_required('admin', 'empleado', 'cliente')
def cancelar_registro(id_reserva):
    return cntcancelar_reserva_web(id_reserva)
