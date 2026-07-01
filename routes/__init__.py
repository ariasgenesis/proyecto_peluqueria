from .usuarios import usuario_bp
from .empleados import empleado_bp
from .clientes import cliente_bp
from .horarios import horario_bp
from .servicios import servicio_bp
from .productos import producto_bp
from .servicios_productos import servicio_producto_bp
from .citas import cita_bp
from .detalles_citas import detalle_cita_bp
from .facturas import factura_bp
from .pagos import pago_bp
from .movimientos import movimiento_bp
from .dashboard import dashboard_bp
from .login import login_bp
from .publico import publico_bp
from .reservas_web import reserva_web_bp
from .webhook import webhook_bp
from .cliente_dashboard import cliente_dashboard_bp
from .auditoria import auditoria_bp


def cargarRutas(app):
    app.register_blueprint(usuario_bp, url_prefix='/usuarios')
    app.register_blueprint(empleado_bp, url_prefix='/empleados')
    app.register_blueprint(cliente_bp, url_prefix='/clientes')
    app.register_blueprint(horario_bp, url_prefix='/horarios')
    app.register_blueprint(servicio_bp, url_prefix='/servicios')
    app.register_blueprint(producto_bp, url_prefix='/productos')
    app.register_blueprint(servicio_producto_bp, url_prefix='/servicios_productos')
    app.register_blueprint(cita_bp, url_prefix='/citas')
    app.register_blueprint(detalle_cita_bp, url_prefix='/detalle_citas')
    app.register_blueprint(factura_bp, url_prefix='/facturas')
    app.register_blueprint(pago_bp, url_prefix='/pagos')
    app.register_blueprint(movimiento_bp, url_prefix='/movimientos')
    app.register_blueprint(dashboard_bp, url_prefix='/dashboard')
    app.register_blueprint(login_bp, url_prefix='/usuarios')
    app.register_blueprint(publico_bp, url_prefix='/publico')
    app.register_blueprint(reserva_web_bp, url_prefix='/reservas_web')
    app.register_blueprint(webhook_bp, url_prefix='/webhook')
    app.register_blueprint(cliente_dashboard_bp, url_prefix='/cliente')
    app.register_blueprint(auditoria_bp, url_prefix='/auditoria')
