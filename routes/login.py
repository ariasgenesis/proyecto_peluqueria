from flask import Blueprint

from controllers.login_controllers import cntlogin, cntregistro_cliente


login_bp = Blueprint('login', __name__)


@login_bp.route('/login', methods=['POST'])
def login():
    return cntlogin()


@login_bp.route('/registro-cliente', methods=['POST'])
def registro_cliente():
    return cntregistro_cliente()
