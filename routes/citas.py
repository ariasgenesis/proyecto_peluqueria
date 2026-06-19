from flask import Blueprint

from controllers.citas_controllers import (
    cntactualizar_cita,
    cntcrear_cita,
    cnteditar_dinamica_cita,
    cnteliminar_cita,
    cntlistado_citas,
    cntobtener_cita,
)
from middlewares.auth_middleware import role_required


cita_bp = Blueprint('citas', __name__)


@cita_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_citas()


@cita_bp.route('/<int:id_cita>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_cita):
    return cntobtener_cita(id_cita)


@cita_bp.route('/', methods=['POST'])
@role_required('admin', 'empleado')
def crear_registro():
    return cntcrear_cita()


@cita_bp.route('/<int:id_cita>', methods=['PUT'])
@role_required('admin', 'empleado')
def actualizar_registro(id_cita):
    return cntactualizar_cita(id_cita)


@cita_bp.route('/<int:id_cita>/editar-dinamica', methods=['PUT'])
@role_required('admin', 'empleado')
def editar_dinamica(id_cita):
    return cnteditar_dinamica_cita(id_cita)


@cita_bp.route('/<int:id_cita>', methods=['DELETE'])
@role_required('admin', 'empleado')
def eliminar_registro(id_cita):
    return cnteliminar_cita(id_cita)
