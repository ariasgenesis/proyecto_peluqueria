from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from services.pagos_services import PagoService


def cntlistado_pagos():
    return listar(PagoService)


def cntobtener_pago(id_pago):
    return obtener(PagoService, id_pago, 'Pago')


def cntcrear_pago():
    return crear(PagoService, 'Pago')


def cntactualizar_pago(id_pago):
    return actualizar(PagoService, id_pago, 'Pago')


def cnteliminar_pago(id_pago):
    return eliminar(PagoService, id_pago, 'Pago')
