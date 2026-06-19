from flask import Blueprint

from controllers.servicios_productos_controllers import (
    cntactualizar_servicio_producto,
    cntcrear_servicio_producto,
    cnteliminar_servicio_producto,
    cntlistado_servicios_productos,
    cntobtener_servicio_producto,
)
from middlewares.auth_middleware import admin_required


servicio_producto_bp = Blueprint('servicios_productos', __name__)


@servicio_producto_bp.route('/', methods=['GET'])
@admin_required()
def listado():
    return cntlistado_servicios_productos()


@servicio_producto_bp.route('/<int:id_servicio_producto>', methods=['GET'])
@admin_required()
def obtener_registro(id_servicio_producto):
    return cntobtener_servicio_producto(id_servicio_producto)


@servicio_producto_bp.route('/', methods=['POST'])
@admin_required()
def crear_registro():
    return cntcrear_servicio_producto()


@servicio_producto_bp.route('/<int:id_servicio_producto>', methods=['PUT'])
@admin_required()
def actualizar_registro(id_servicio_producto):
    return cntactualizar_servicio_producto(id_servicio_producto)


@servicio_producto_bp.route('/<int:id_servicio_producto>', methods=['DELETE'])
@admin_required()
def eliminar_registro(id_servicio_producto):
    return cnteliminar_servicio_producto(id_servicio_producto)
