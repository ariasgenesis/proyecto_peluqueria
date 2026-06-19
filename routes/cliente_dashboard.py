from flask import Blueprint

from controllers.cliente_dashboard_controllers import (
    cnthistorial_basico,
    cntmis_citas,
    cntmis_facturas,
)
from middlewares.auth_middleware import role_required


cliente_dashboard_bp = Blueprint('cliente_dashboard', __name__)


@cliente_dashboard_bp.route('/mis-citas', methods=['GET'])
@role_required('cliente')
def mis_citas():
    return cntmis_citas()


@cliente_dashboard_bp.route('/mis-facturas', methods=['GET'])
@role_required('cliente')
def mis_facturas():
    return cntmis_facturas()


@cliente_dashboard_bp.route('/historial', methods=['GET'])
@role_required('cliente')
def historial():
    return cnthistorial_basico()
