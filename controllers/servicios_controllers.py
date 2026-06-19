from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from services.servicios_services import ServicioService


def cntlistado_servicios():
    return listar(ServicioService)


def cntobtener_servicio(id_servicio):
    return obtener(ServicioService, id_servicio, 'Servicio')


def cntcrear_servicio():
    return crear(ServicioService, 'Servicio')


def cntactualizar_servicio(id_servicio):
    return actualizar(ServicioService, id_servicio, 'Servicio')


def cnteliminar_servicio(id_servicio):
    return eliminar(ServicioService, id_servicio, 'Servicio')
