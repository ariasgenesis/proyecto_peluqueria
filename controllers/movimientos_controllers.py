from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from services.movimientos_services import MovimientoService


def cntlistado_movimientos():
    return listar(MovimientoService)


def cntobtener_movimiento(id_movimiento):
    return obtener(MovimientoService, id_movimiento, 'Movimiento')


def cntcrear_movimiento():
    return crear(MovimientoService, 'Movimiento')


def cntactualizar_movimiento(id_movimiento):
    return actualizar(MovimientoService, id_movimiento, 'Movimiento')


def cnteliminar_movimiento(id_movimiento):
    return eliminar(MovimientoService, id_movimiento, 'Movimiento')
