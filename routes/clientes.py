from flask import Blueprint

from controllers.clientes_controllers import (
    cntactualizar_cliente,
    cntcrear_cliente,
    cnteliminar_cliente,
    cntlistado_clientes,
    cntobtener_cliente,
)
from middlewares.auth_middleware import role_required


cliente_bp = Blueprint('clientes', __name__)


@cliente_bp.route('/', methods=['GET'])
@role_required('admin', 'empleado')
def listado():
    return cntlistado_clientes()


@cliente_bp.route('/<int:id_cliente>', methods=['GET'])
@role_required('admin', 'empleado')
def obtener_registro(id_cliente):
    return cntobtener_cliente(id_cliente)


@cliente_bp.route('/', methods=['POST'])
@role_required('admin', 'empleado')
def crear_registro():
    return cntcrear_cliente()


@cliente_bp.route('/<int:id_cliente>', methods=['PUT'])
@role_required('admin', 'empleado')
def actualizar_registro(id_cliente):
    return cntactualizar_cliente(id_cliente)


@cliente_bp.route('/<int:id_cliente>', methods=['DELETE'])
@role_required('admin', 'empleado')
def eliminar_registro(id_cliente):
    return cnteliminar_cliente(id_cliente)
