from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from flask import current_app, request

from controllers.base_controller import error_response, success_response, usuario_actual_id
from services.base_service import ServiceError
from services.facturas_services import FacturaService


def cntlistado_facturas():
    return listar(FacturaService)


def cntobtener_factura(id_factura):
    return obtener(FacturaService, id_factura, 'Factura')


def cntcrear_factura():
    return crear(FacturaService, 'Factura')


def cntactualizar_factura(id_factura):
    return actualizar(FacturaService, id_factura, 'Factura')


def cnteliminar_factura(id_factura):
    service = FacturaService(current_app.mysql)
    try:
        service.eliminar_con_pin(id_factura, request.get_json(silent=True), usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Factura eliminada correctamente', {})
