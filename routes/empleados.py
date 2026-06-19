from flask import Blueprint

from controllers.empleados_controllers import (
    cntactualizar_empleado,
    cntcrear_empleado,
    cnteliminar_empleado,
    cntlistado_empleados,
    cntobtener_empleado,
)
from middlewares.auth_middleware import admin_required, role_required


empleado_bp = Blueprint('empleados', __name__)


@empleado_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_empleados()


@empleado_bp.route('/<int:id_empleado>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_empleado):
    return cntobtener_empleado(id_empleado)


@empleado_bp.route('/', methods=['POST'])
@admin_required()
def crear_registro():
    return cntcrear_empleado()


@empleado_bp.route('/<int:id_empleado>', methods=['PUT'])
@admin_required()
def actualizar_registro(id_empleado):
    return cntactualizar_empleado(id_empleado)


@empleado_bp.route('/<int:id_empleado>', methods=['DELETE'])
@admin_required()
def eliminar_registro(id_empleado):
    return cnteliminar_empleado(id_empleado)
