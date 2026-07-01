from datetime import datetime
from flask import Blueprint, current_app, request

from controllers.base_controller import error_response, success_response
from controllers.servicios_controllers import cntlistado_servicios_publicos
from services.base_service import ServiceError
from services.citas_services import CitaService

_DATE_FMT = '%Y-%m-%d'


def _validar_fecha_publica(fecha):
    """Devuelve None si la fecha es válida, o un mensaje de error."""
    if not fecha:
        return 'El parámetro fecha es requerido'
    try:
        datetime.strptime(fecha, _DATE_FMT)
    except ValueError:
        return 'La fecha debe tener formato YYYY-MM-DD'
    return None


publico_bp = Blueprint('publico', __name__)

SLOTS_DIA = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00', '17:00',
]


@publico_bp.route('/servicios', methods=['GET'])
def servicios_publicos():
    return cntlistado_servicios_publicos()


@publico_bp.route('/empleados', methods=['GET'])
def empleados_publicos():
    cursor = current_app.mysql.connection.cursor()
    cursor.execute(
        "SELECT emp_id, emp_nombre, emp_apellido, emp_cargo "
        "FROM empleados WHERE emp_estado = 'activo' ORDER BY emp_nombre"
    )
    rows = cursor.fetchall()
    cursor.close()
    return success_response('Empleados activos', [
        {'id_empleado': r[0], 'nombre': r[1], 'apellido': r[2], 'cargo': r[3] or ''}
        for r in rows
    ])


@publico_bp.route('/slots', methods=['GET'])
def slots_disponibles():
    """GET /publico/slots?servicios=1,2&fecha=YYYY-MM-DD[&empleado_id=N]
    Retorna disponibilidad de cada franja horaria del día.
    """
    fecha = request.args.get('fecha', '').strip()
    error_fecha = _validar_fecha_publica(fecha)
    if error_fecha:
        return error_response(error_fecha, 400)

    servicios_str = request.args.get('servicios', '').strip()
    try:
        servicios_ids = [int(s) for s in servicios_str.split(',') if s.strip()] if servicios_str else []
    except ValueError:
        return error_response('servicios debe ser una lista de IDs separados por coma', 400)

    empleado_id = request.args.get('empleado_id')
    try:
        empleado_id = int(empleado_id) if empleado_id else None
    except ValueError:
        empleado_id = None

    cita_service = CitaService(current_app.mysql)
    resultado = []
    for hora in SLOTS_DIA:
        try:
            if empleado_id:
                cita_service.validar_disponibilidad_publica(
                    empleado_id,
                    fecha,
                    hora,
                    servicios_ids=servicios_ids or None,
                )
            else:
                cita_service.buscar_empleado_disponible(
                    None,
                    fecha,
                    hora,
                    servicios_ids=servicios_ids or None,
                )
            disponible = True
        except (ServiceError, Exception):
            disponible = False
        resultado.append({'hora': hora, 'disponible': disponible})

    return success_response('Slots del día', resultado)


@publico_bp.route('/disponibilidad', methods=['GET'])
def disponibilidad_publica():
    try:
        servicio_id = int(request.args.get('servicio_id', ''))
        if servicio_id <= 0:
            raise ValueError
    except (ValueError, TypeError):
        return error_response('El parametro servicio_id debe ser un numero entero positivo', 400)

    fecha = request.args.get('fecha', '').strip()
    error_fecha = _validar_fecha_publica(fecha)
    if error_fecha:
        return error_response(error_fecha, 400)

    hora = request.args.get('hora', '').strip()
    if not hora:
        return error_response('El parametro hora es requerido', 400)

    try:
        CitaService(current_app.mysql).buscar_empleado_disponible(servicio_id, fecha, hora)
    except ValueError:
        return error_response('La fecha o la hora no tienen un formato valido', 400)
    except ServiceError as exc:
        return error_response(exc.message, exc.status_code)
    return success_response('Horario disponible', {'disponible': True})
