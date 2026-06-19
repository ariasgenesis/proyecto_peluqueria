from flask import current_app, g, jsonify, request

from services.base_service import ServiceError


def success_response(message, data=None, status=200):
    return jsonify({'success': True, 'message': message, 'data': data}), status


def error_response(message, status=400):
    return jsonify({'success': False, 'message': message}), status


def obtener_paginacion():
    try:
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 10))
    except (TypeError, ValueError):
        return None, error_response('Los parametros "page" y "per_page" deben ser numeros enteros', 400)
    if page <= 0 or per_page <= 0:
        return None, error_response('Los parametros "page" y "per_page" deben ser mayores que cero', 400)
    if per_page > 100:
        return None, error_response('El parametro "per_page" no puede ser mayor que 100', 400)
    return {'page': page, 'per_page': per_page}, None


def usuario_actual_id():
    auth_user = getattr(g, 'auth_user', {}) or {}
    value = auth_user.get('id_usuario')
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def filtros_request(service_class):
    filtros = {}
    for public_name in getattr(service_class.model, 'filter_fields', {}):
        value = request.args.get(public_name)
        if value not in (None, ''):
            filtros[public_name] = value
    return filtros


def listar(service_class, mensaje='Listado obtenido correctamente'):
    paginacion, response = obtener_paginacion()
    if response is not None:
        return response
    service = service_class(current_app.mysql)
    data = service.listar_todos(
        paginacion['page'],
        paginacion['per_page'],
        filters=filtros_request(service_class),
        search=request.args.get('search'),
        include_deleted=request.args.get('include_deleted') == 'true'
    )
    return success_response(mensaje, data)


def obtener(service_class, record_id, nombre):
    service = service_class(current_app.mysql)
    registro = service.obtener_por_id(record_id)
    if registro:
        return success_response(f'{nombre} obtenido correctamente', registro)
    return error_response(f'{nombre} no encontrado', 404)


def crear(service_class, nombre):
    service = service_class(current_app.mysql)
    try:
        registro = service.crear(request.get_json(silent=True), usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response(f'{nombre} creado correctamente', registro, 201)


def actualizar(service_class, record_id, nombre):
    service = service_class(current_app.mysql)
    try:
        registro = service.actualizar(record_id, request.get_json(silent=True), usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response(f'{nombre} actualizado correctamente', registro)


def eliminar(service_class, record_id, nombre):
    service = service_class(current_app.mysql)
    try:
        service.eliminar(record_id, usuario_actual_id())
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response(f'{nombre} eliminado correctamente', {})
