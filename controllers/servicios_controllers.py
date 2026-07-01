from flask import current_app, jsonify, request

from controllers.base_controller import actualizar, crear, eliminar, listar, obtener, obtener_paginacion, success_response
from services.servicios_services import ServicioService
from services.base_service import ServiceError, NotFoundError


def cntlistado_servicios():
    return listar(ServicioService)


def cntlistado_servicios_publicos():
    paginacion, response = obtener_paginacion()
    if response is not None:
        return response
    data = ServicioService(current_app.mysql).listar_todos(
        paginacion['page'],
        paginacion['per_page'],
        search=request.args.get('search'),
        include_deleted=True,
    )
    return success_response('Servicios activos obtenidos correctamente', data)


def cntobtener_servicio(id_servicio):
    return obtener(ServicioService, id_servicio, 'Servicio')


def cntcrear_servicio():
    return crear(ServicioService, 'Servicio')


def cntactualizar_servicio(id_servicio):
    return actualizar(ServicioService, id_servicio, 'Servicio')


def cnteliminar_servicio(id_servicio):
    return eliminar(ServicioService, id_servicio, 'Servicio')


def cnttoggle_estado_servicio(id_servicio):
    try:
        svc = ServicioService(current_app.mysql)
        result = svc.toggle_estado(id_servicio)
        return jsonify({'success': True, 'message': 'Estado del servicio actualizado', 'data': result}), 200
    except NotFoundError as e:
        return jsonify({'success': False, 'message': e.message}), 404
    except ServiceError as e:
        return jsonify({'success': False, 'message': e.message}), e.status_code
    except Exception:
        return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500
