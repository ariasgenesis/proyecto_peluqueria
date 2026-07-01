from flask import Blueprint

from controllers.servicios_controllers import (
    cntactualizar_servicio,
    cntcrear_servicio,
    cnteliminar_servicio,
    cntlistado_servicios,
    cntobtener_servicio,
    cnttoggle_estado_servicio,
)
from middlewares.auth_middleware import admin_required, role_required


servicio_bp = Blueprint('servicios', __name__)


@servicio_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_servicios()


@servicio_bp.route('/<int:id_servicio>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_servicio):
    return cntobtener_servicio(id_servicio)


@servicio_bp.route('/', methods=['POST'])
@admin_required()
def crear_registro():
    return cntcrear_servicio()


@servicio_bp.route('/<int:id_servicio>', methods=['PUT'])
@admin_required()
def actualizar_registro(id_servicio):
    return cntactualizar_servicio(id_servicio)


@servicio_bp.route('/<int:id_servicio>', methods=['DELETE'])
@admin_required()
def eliminar_registro(id_servicio):
    return cnteliminar_servicio(id_servicio)


@servicio_bp.route('/<int:id_servicio>/toggle-estado', methods=['PATCH'])
@admin_required()
def toggle_estado(id_servicio):
    return cnttoggle_estado_servicio(id_servicio)
