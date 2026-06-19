from flask import Blueprint

from controllers.movimientos_controllers import (
    cntactualizar_movimiento,
    cntcrear_movimiento,
    cnteliminar_movimiento,
    cntlistado_movimientos,
    cntobtener_movimiento,
)
from middlewares.auth_middleware import role_required


movimiento_bp = Blueprint('movimientos', __name__)


@movimiento_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_movimientos()


@movimiento_bp.route('/<int:id_movimiento>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_movimiento):
    return cntobtener_movimiento(id_movimiento)


@movimiento_bp.route('/', methods=['POST'])
@role_required('admin', 'empleado')
def crear_registro():
    return cntcrear_movimiento()


@movimiento_bp.route('/<int:id_movimiento>', methods=['PUT'])
@role_required('admin', 'empleado')
def actualizar_registro(id_movimiento):
    return cntactualizar_movimiento(id_movimiento)


@movimiento_bp.route('/<int:id_movimiento>', methods=['DELETE'])
@role_required('admin', 'empleado')
def eliminar_registro(id_movimiento):
    return cnteliminar_movimiento(id_movimiento)
