from flask import current_app

from controllers.base_controller import success_response, usuario_actual_id
from services.dashboard_services import DashboardService


def cntdashboard_admin():
    data = DashboardService(current_app.mysql).admin_resumen()
    return success_response('Resumen admin obtenido correctamente', data)


def cntdashboard_empleado():
    data = DashboardService(current_app.mysql).empleado_resumen(usuario_actual_id())
    return success_response('Resumen empleado obtenido correctamente', data)


def cntdashboard_kanban():
    data = DashboardService(current_app.mysql).kanban_citas()
    return success_response('Dashboard kanban obtenido correctamente', data)


def cntdashboard_alertas():
    data = DashboardService(current_app.mysql).alertas()
    return success_response('Alertas obtenidas correctamente', data)
