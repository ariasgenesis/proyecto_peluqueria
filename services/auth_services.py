from datetime import timedelta

from flask_jwt_extended import JWTManager, create_access_token


class AuthService:
    """Servicio de infraestructura para JWT."""

    def generar_access_token(self, usuario):
        return create_access_token(
            identity=str(usuario['id_usuario']),
            additional_claims={
                'username': usuario['username'],
                'rol': usuario['rol'],
                'estado': usuario['estado']
            }
        )


def configurar_auth(app):
    app.config['JWT_SECRET_KEY'] = app.config.get('JWT_SECRET_KEY') or 'change-me'
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=2)

    jwt = JWTManager(app)

    @jwt.unauthorized_loader
    def manejar_token_ausente(_reason):
        return {'success': False, 'message': 'Se requiere un token de autenticacion'}, 401

    @jwt.invalid_token_loader
    def manejar_token_invalido(_reason):
        return {'success': False, 'message': 'El token proporcionado no es valido'}, 401

    @jwt.expired_token_loader
    def manejar_token_expirado(_jwt_header, _jwt_payload):
        return {'success': False, 'message': 'El token ha expirado'}, 401

    return jwt
