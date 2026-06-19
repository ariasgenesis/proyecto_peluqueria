from flask import current_app

from models.login_model import LoginModel


class LoginService:
    """Capa de aplicacion para autenticacion de credenciales."""

    def __init__(self, mysql):
        self.mysql = mysql

    def autenticar(self, username, password):
        usuario = LoginModel.obtener_por_username(self.mysql, username)
        if not usuario:
            return None

        password_guardada = usuario['password'] or ''
        try:
            password_valida = current_app.bcrypt.check_password_hash(password_guardada, password)
        except ValueError:
            password_valida = False

        if not password_valida and password_guardada == password:
            nuevo_hash = current_app.bcrypt.generate_password_hash(password).decode('utf-8')
            LoginModel.actualizar_password(self.mysql, usuario['id_usuario'], nuevo_hash)
            password_valida = True

        if not password_valida:
            return None
        usuario.pop('password', None)
        return usuario
