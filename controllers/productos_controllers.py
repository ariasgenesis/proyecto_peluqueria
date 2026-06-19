from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from flask import current_app, request

from controllers.base_controller import error_response, obtener_paginacion, success_response, usuario_actual_id
from services.base_service import ServiceError
from services.productos_services import ProductoService


def cntlistado_productos():
    return listar(ProductoService)


def cntobtener_producto(id_producto):
    return obtener(ProductoService, id_producto, 'Producto')


def cntcrear_producto():
    return crear(ProductoService, 'Producto')


def cntactualizar_producto(id_producto):
    return actualizar(ProductoService, id_producto, 'Producto')


def cnteliminar_producto(id_producto):
    return eliminar(ProductoService, id_producto, 'Producto')


def cntagregar_stock(id_producto):
    service = ProductoService(current_app.mysql)
    try:
        data = service.agregar_stock(id_producto, request.get_json(silent=True), usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Stock agregado correctamente', data)


def cntdescontar_stock(id_producto):
    service = ProductoService(current_app.mysql)
    try:
        data = service.descontar_stock(id_producto, request.get_json(silent=True), usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Stock descontado correctamente', data)


def cnteditar_stock(id_producto):
    service = ProductoService(current_app.mysql)
    try:
        data = service.editar_stock(id_producto, request.get_json(silent=True), usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Stock actualizado correctamente', data)


def cntstock_bajo():
    paginacion, response = obtener_paginacion()
    if response is not None:
        return response
    data = ProductoService(current_app.mysql).stock_bajo(paginacion['page'], paginacion['per_page'])
    return success_response('Productos con stock bajo obtenidos correctamente', data)
