from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from services.horarios_services import HorarioService


def cntlistado_horarios():
    return listar(HorarioService)


def cntobtener_horario(id_horario):
    return obtener(HorarioService, id_horario, 'Horario')


def cntcrear_horario():
    return crear(HorarioService, 'Horario')


def cntactualizar_horario(id_horario):
    return actualizar(HorarioService, id_horario, 'Horario')


def cnteliminar_horario(id_horario):
    return eliminar(HorarioService, id_horario, 'Horario')
