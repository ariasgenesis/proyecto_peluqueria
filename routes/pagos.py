from flask import Blueprint

from controllers.pagos_controllers import (
    cntactualizar_pago,
    cntcrear_pago,
    cnteliminar_pago,
    cntlistado_pagos,
    cntobtener_pago,
)
from middlewares.auth_middleware import role_required


pago_bp = Blueprint('pagos', __name__)


@pago_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_pagos()


@pago_bp.route('/<int:id_pago>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_pago):
    return cntobtener_pago(id_pago)


@pago_bp.route('/', methods=['POST'])
@role_required('admin', 'empleado')
def crear_registro():
    return cntcrear_pago()


@pago_bp.route('/<int:id_pago>', methods=['PUT'])
@role_required('admin', 'empleado')
def actualizar_registro(id_pago):
    return cntactualizar_pago(id_pago)


@pago_bp.route('/<int:id_pago>', methods=['DELETE'])
@role_required('admin', 'empleado')
def eliminar_registro(id_pago):
    return cnteliminar_pago(id_pago)
