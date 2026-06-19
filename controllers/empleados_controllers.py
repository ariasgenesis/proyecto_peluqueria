from controllers.base_controller import actualizar, crear, eliminar, listar, obtener
from services.empleados_services import EmpleadoService


def cntlistado_empleados():
    return listar(EmpleadoService)


def cntobtener_empleado(id_empleado):
    return obtener(EmpleadoService, id_empleado, 'Empleado')


def cntcrear_empleado():
    return crear(EmpleadoService, 'Empleado')


def cntactualizar_empleado(id_empleado):
    return actualizar(EmpleadoService, id_empleado, 'Empleado')


def cnteliminar_empleado(id_empleado):
    return eliminar(EmpleadoService, id_empleado, 'Empleado')
