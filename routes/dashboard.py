from flask import Blueprint

from controllers.dashboard_controllers import (
    cntdashboard_admin,
    cntdashboard_alertas,
    cntdashboard_empleado,
    cntdashboard_kanban,
)
from middlewares.auth_middleware import admin_required, role_required


dashboard_bp = Blueprint('dashboard', __name__)


@dashboard_bp.route('/admin', methods=['GET'])
@admin_required()
def admin():
    return cntdashboard_admin()


@dashboard_bp.route('/empleado', methods=['GET'])
@role_required('admin', 'empleado')
def empleado():
    return cntdashboard_empleado()


@dashboard_bp.route('/kanban', methods=['GET'])
@role_required('admin', 'empleado')
def kanban():
    return cntdashboard_kanban()


@dashboard_bp.route('/alertas', methods=['GET'])
@role_required('admin', 'empleado')
def alertas():
    return cntdashboard_alertas()
