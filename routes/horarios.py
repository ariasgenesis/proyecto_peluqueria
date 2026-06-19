from flask import Blueprint

from controllers.horarios_controllers import (
    cntactualizar_horario,
    cntcrear_horario,
    cnteliminar_horario,
    cntlistado_horarios,
    cntobtener_horario,
)
from middlewares.auth_middleware import admin_required, role_required


horario_bp = Blueprint('horarios', __name__)


@horario_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_horarios()


@horario_bp.route('/<int:id_horario>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_horario):
    return cntobtener_horario(id_horario)


@horario_bp.route('/', methods=['POST'])
@admin_required()
def crear_registro():
    return cntcrear_horario()


@horario_bp.route('/<int:id_horario>', methods=['PUT'])
@admin_required()
def actualizar_registro(id_horario):
    return cntactualizar_horario(id_horario)


@horario_bp.route('/<int:id_horario>', methods=['DELETE'])
@admin_required()
def eliminar_registro(id_horario):
    return cnteliminar_horario(id_horario)
