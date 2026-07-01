from flask import Blueprint

from controllers.auditoria_controllers import cnt_auditoria_resumen
from middlewares.auth_middleware import admin_required

auditoria_bp = Blueprint('auditoria', __name__)


@auditoria_bp.route('/resumen', methods=['GET'])
@admin_required()
def resumen():
    return cnt_auditoria_resumen()
