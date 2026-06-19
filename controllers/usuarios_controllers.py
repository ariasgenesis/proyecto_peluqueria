from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from services.usuarios_services import UsuarioService


def cntlistado_usuarios():
    return listar(UsuarioService)


def cntobtener_usuario(id_usuario):
    return obtener(UsuarioService, id_usuario, 'Usuario')


def cntcrear_usuario():
    return crear(UsuarioService, 'Usuario')


def cntactualizar_usuario(id_usuario):
    return actualizar(UsuarioService, id_usuario, 'Usuario')


def cnteliminar_usuario(id_usuario):
    return eliminar(UsuarioService, id_usuario, 'Usuario')
