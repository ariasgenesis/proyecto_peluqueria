from flask import Blueprint

from controllers.detalles_citas_controllers import (
    cntactualizar_detalle_cita,
    cntcrear_detalle_cita,
    cnteliminar_detalle_cita,
    cntlistado_detalles_citas,
    cntobtener_detalle_cita,
)
from middlewares.auth_middleware import role_required


detalle_cita_bp = Blueprint('detalles_citas', __name__)


@detalle_cita_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_detalles_citas()


@detalle_cita_bp.route('/<int:id_detalle_cita>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_detalle_cita):
    return cntobtener_detalle_cita(id_detalle_cita)


@detalle_cita_bp.route('/', methods=['POST'])
@role_required('admin', 'empleado')
def crear_registro():
    return cntcrear_detalle_cita()


@detalle_cita_bp.route('/<int:id_detalle_cita>', methods=['PUT'])
@role_required('admin', 'empleado')
def actualizar_registro(id_detalle_cita):
    return cntactualizar_detalle_cita(id_detalle_cita)


@detalle_cita_bp.route('/<int:id_detalle_cita>', methods=['DELETE'])
@role_required('admin', 'empleado')
def eliminar_registro(id_detalle_cita):
    return cnteliminar_detalle_cita(id_detalle_cita)
