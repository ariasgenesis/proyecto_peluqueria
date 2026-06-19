from flask import Blueprint

from controllers.webhook_controllers import cntwebhook_wompi


webhook_bp = Blueprint('webhook', __name__)


@webhook_bp.route('/wompi', methods=['POST'])
def wompi():
    return cntwebhook_wompi()
