from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from services.movimientos_services import MovimientoInventarioService


def cntlistado_movimientos():
    return listar(MovimientoInventarioService)


def cntobtener_movimiento(id_movimiento):
    return obtener(MovimientoInventarioService, id_movimiento, 'Movimiento')


def cntcrear_movimiento():
    return crear(MovimientoInventarioService, 'Movimiento')


def cntactualizar_movimiento(id_movimiento):
    return actualizar(MovimientoInventarioService, id_movimiento, 'Movimiento')


def cnteliminar_movimiento(id_movimiento):
    return eliminar(MovimientoInventarioService, id_movimiento, 'Movimiento')
