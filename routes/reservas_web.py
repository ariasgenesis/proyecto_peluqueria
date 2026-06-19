from flask import Blueprint

from controllers.reservas_web_controllers import (
    cntactualizar_reserva_web,
    cntcancelar_reserva_web,
    cntcrear_reserva_web,
    cntlistado_reservas_web,
    cntobtener_reserva_web,
)
from middlewares.auth_middleware import role_required


reserva_web_bp = Blueprint('reservas_web', __name__)


@reserva_web_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_reservas_web()


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
