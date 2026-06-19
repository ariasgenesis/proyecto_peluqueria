from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from services.servicios_productos_services import ServicioProductoService


def cntlistado_servicios_productos():
    return listar(ServicioProductoService)


def cntobtener_servicio_producto(id_servicio_producto):
    return obtener(ServicioProductoService, id_servicio_producto, 'ServicioProducto')


def cntcrear_servicio_producto():
    return crear(ServicioProductoService, 'ServicioProducto')


def cntactualizar_servicio_producto(id_servicio_producto):
    return actualizar(ServicioProductoService, id_servicio_producto, 'ServicioProducto')


def cnteliminar_servicio_producto(id_servicio_producto):
    return eliminar(ServicioProductoService, id_servicio_producto, 'ServicioProducto')
