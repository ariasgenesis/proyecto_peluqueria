from flask import Blueprint

from controllers.usuarios_controllers import (
    cntactualizar_usuario,
    cntcrear_usuario,
    cnteliminar_usuario,
    cntlistado_usuarios,
    cntobtener_usuario,
)
from middlewares.auth_middleware import admin_required


usuario_bp = Blueprint('usuarios', __name__)


@usuario_bp.route('/', methods=['GET'])
@admin_required()
def listado():
    return cntlistado_usuarios()


@usuario_bp.route('/<int:id_usuario>', methods=['GET'])
@admin_required()
def obtener_registro(id_usuario):
    return cntobtener_usuario(id_usuario)


@usuario_bp.route('/', methods=['POST'])
@admin_required()
def crear_registro():
    return cntcrear_usuario()


@usuario_bp.route('/<int:id_usuario>', methods=['PUT'])
@admin_required()
def actualizar_registro(id_usuario):
    return cntactualizar_usuario(id_usuario)


@usuario_bp.route('/<int:id_usuario>', methods=['DELETE'])
@admin_required()
def eliminar_registro(id_usuario):
    return cnteliminar_usuario(id_usuario)
