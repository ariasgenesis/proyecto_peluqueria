from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from services.clientes_services import ClienteService


def cntlistado_clientes():
    return listar(ClienteService)


def cntobtener_cliente(id_cliente):
    return obtener(ClienteService, id_cliente, 'Cliente')


def cntcrear_cliente():
    return crear(ClienteService, 'Cliente')


def cntactualizar_cliente(id_cliente):
    return actualizar(ClienteService, id_cliente, 'Cliente')


def cnteliminar_cliente(id_cliente):
    return eliminar(ClienteService, id_cliente, 'Cliente')
