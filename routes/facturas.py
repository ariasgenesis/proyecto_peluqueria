from flask import Blueprint

from controllers.facturas_controllers import (
    cntactualizar_factura,
    cntcrear_factura,
    cnteliminar_factura,
    cntlistado_facturas,
    cntobtener_factura,
)
from middlewares.auth_middleware import role_required


factura_bp = Blueprint('facturas', __name__)


@factura_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_facturas()


@factura_bp.route('/<int:id_factura>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_factura):
    return cntobtener_factura(id_factura)


@factura_bp.route('/', methods=['POST'])
@role_required('admin', 'empleado')
def crear_registro():
    return cntcrear_factura()


@factura_bp.route('/<int:id_factura>', methods=['PUT'])
@role_required('admin', 'empleado')
def actualizar_registro(id_factura):
    return cntactualizar_factura(id_factura)


@factura_bp.route('/<int:id_factura>', methods=['DELETE'])
@role_required('admin', 'empleado')
def eliminar_registro(id_factura):
    return cnteliminar_factura(id_factura)
