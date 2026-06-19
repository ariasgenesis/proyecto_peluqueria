from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from services.detalles_citas_services import DetalleCitaService


def cntlistado_detalles_citas():
    return listar(DetalleCitaService)


def cntobtener_detalle_cita(id_detalle_cita):
    return obtener(DetalleCitaService, id_detalle_cita, 'DetalleCita')


def cntcrear_detalle_cita():
    return crear(DetalleCitaService, 'DetalleCita')


def cntactualizar_detalle_cita(id_detalle_cita):
    return actualizar(DetalleCitaService, id_detalle_cita, 'DetalleCita')


def cnteliminar_detalle_cita(id_detalle_cita):
    return eliminar(DetalleCitaService, id_detalle_cita, 'DetalleCita')
