from flask import current_app, jsonify, request

from services.auth_services import AuthService
from services.base_service import ServiceError
from services.clientes_services import ClienteService
from services.login_services import LoginService


def cntlogin():
    data = request.get_json(silent=True) or {}
    username = data.get('username')
    password = data.get('password')

    if not isinstance(username, str) or not username.strip():
        return jsonify({'success': False, 'message': 'El campo "username" es requerido'}), 400
    if not isinstance(password, str) or not password:
        return jsonify({'success': False, 'message': 'El campo "password" es requerido'}), 400

    login_service = LoginService(current_app.mysql)
    usuario = login_service.autenticar(username.strip(), password)
    if not usuario:
        return jsonify({'success': False, 'message': 'Credenciales invalidas'}), 401

    auth_service = AuthService()
    token = auth_service.generar_access_token(usuario)
    return jsonify({
        'success': True,
        'message': 'Login exitoso',
        'data': {
            'access_token': token,
            'usuario': usuario
        }
    })


def cntregistro_cliente():
    service = ClienteService(current_app.mysql)
    try:
        usuario = service.registrar_cliente(request.get_json(silent=True))
    except ServiceError as exc:
        return jsonify({'success': False, 'message': exc.message}), exc.status_code
    except Exception:
        current_app.logger.exception('Error registrando cliente')
        return jsonify({'success': False, 'message': 'No se pudo registrar el cliente'}), 400

    token = AuthService().generar_access_token(usuario)
    return jsonify({
        'success': True,
        'message': 'Cliente registrado correctamente',
        'data': {
            'access_token': token,
            'usuario': usuario,
        },
    }), 201
