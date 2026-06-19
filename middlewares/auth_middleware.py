from functools import wraps

from flask import g, jsonify
from flask_jwt_extended import get_jwt, get_jwt_identity, jwt_required


def role_required(*roles):
    """Valida JWT y limita el acceso a los roles indicados."""
    def decorator(fn):
        @wraps(fn)
        @jwt_required()
        def wrapper(*args, **kwargs):
            claims = get_jwt()
            rol = claims.get('rol')
            estado = claims.get('estado')
            if rol not in {'admin', 'empleado', 'cliente'} or estado != 'activo':
                return jsonify({'success': False, 'message': 'Token de autenticacion no autorizado'}), 401
            if roles and rol not in roles:
                return jsonify({'success': False, 'message': 'No tienes permisos para acceder a este recurso'}), 403
            g.auth_user = {
                'id_usuario': get_jwt_identity(),
                'claims': claims,
                'rol': rol,
                'estado': estado
            }
            return fn(*args, **kwargs)

        return wrapper

    return decorator


def admin_required():
    """Atajo para endpoints exclusivos del rol admin."""
    return role_required('admin')


def jwt_auth_required():
    """Compatibilidad con rutas existentes: requiere admin o empleado."""
    return role_required('admin', 'empleado')


def staff_required():
    """Atajo para endpoints del panel administrativo (admin o empleado)."""
    return role_required('admin', 'empleado')
