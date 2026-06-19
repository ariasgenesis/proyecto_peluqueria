from flask import Blueprint

from controllers.productos_controllers import (
    cntactualizar_producto,
    cntagregar_stock,
    cntcrear_producto,
    cntdescontar_stock,
    cnteditar_stock,
    cnteliminar_producto,
    cntlistado_productos,
    cntobtener_producto,
    cntstock_bajo,
)
from middlewares.auth_middleware import role_required


producto_bp = Blueprint('productos', __name__)


@producto_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_productos()


@producto_bp.route('/<int:id_producto>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_producto):
    return cntobtener_producto(id_producto)


@producto_bp.route('/', methods=['POST'])
@role_required('admin', 'empleado')
def crear_registro():
    return cntcrear_producto()


@producto_bp.route('/<int:id_producto>', methods=['PUT'])
@role_required('admin', 'empleado')
def actualizar_registro(id_producto):
    return cntactualizar_producto(id_producto)


@producto_bp.route('/<int:id_producto>', methods=['DELETE'])
@role_required('admin', 'empleado')
def eliminar_registro(id_producto):
    return cnteliminar_producto(id_producto)


@producto_bp.route('/stock-bajo', methods=['GET'])
@role_required('admin', 'empleado')
def stock_bajo():
    return cntstock_bajo()


@producto_bp.route('/<int:id_producto>/agregar-stock', methods=['POST'])
@role_required('admin', 'empleado')
def agregar_stock(id_producto):
    return cntagregar_stock(id_producto)


@producto_bp.route('/<int:id_producto>/descontar-stock', methods=['POST'])
@role_required('admin', 'empleado')
def descontar_stock(id_producto):
    return cntdescontar_stock(id_producto)


@producto_bp.route('/<int:id_producto>/editar-stock', methods=['PUT'])
@role_required('admin', 'empleado')
def editar_stock(id_producto):
    return cnteditar_stock(id_producto)
