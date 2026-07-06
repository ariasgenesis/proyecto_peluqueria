from flask import Blueprint

from controllers.auditoria_personal_controllers import cntauditoria_personal
from middlewares.auth_middleware import admin_required


auditoria_personal_bp = Blueprint('auditoria_personal', __name__)


@auditoria_personal_bp.route('/personal', methods=['GET'])
@admin_required()
def personal():
    return cntauditoria_personal()
