import logging
import os

import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask, send_from_directory
from flask_bcrypt import Bcrypt
from flask_cors import CORS
from flask_mysqldb import MySQL

from config import Config
from routes import cargarRutas
from services.auth_services import configurar_auth

app = Flask(__name__)
app.config.from_object(Config)

_jwt_secret = os.getenv('JWT_SECRET_KEY') or os.getenv('SECRET_KEY') or 'change-me'
app.config['JWT_SECRET_KEY'] = _jwt_secret
logging.basicConfig(level=logging.INFO)

if _jwt_secret == 'change-me':
    logging.warning(
        '[SEGURIDAD] JWT_SECRET_KEY usa el valor por defecto inseguro "change-me". '
        'Configure la variable de entorno JWT_SECRET_KEY antes de pasar a produccion.'
    )

# CORS: orígenes permitidos configurables via variable de entorno CORS_ORIGINS
# Ejemplo: CORS_ORIGINS=https://mi-dominio.com,https://app.mi-dominio.com
# Si no se define, se usa '*' (permite todo, útil en desarrollo).
_cors_origins_env = os.getenv('CORS_ORIGINS', '').strip()
_cors_origins = [o.strip() for o in _cors_origins_env.split(',') if o.strip()] or '*'

CORS(
    app,
    resources={r'/*': {'origins': _cors_origins}},
    supports_credentials=False,
    allow_headers=['Content-Type', 'Authorization'],
    methods=['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
)
app.url_map.strict_slashes = False
configurar_auth(app)

bcrypt = Bcrypt(app)
app.bcrypt = bcrypt

mysql = MySQL(app)
app.mysql = mysql

try:
    from flasgger import Swagger
    Swagger(app, template_file='swagger.json')
except ImportError:
    print("❌ ERROR: No se pudo cargar Swagger porque 'flasgger' no está instalado.")

cargarRutas(app)

FRONTEND_DIST = os.path.join(os.path.dirname(__file__), 'frontend_vue', 'dist')
API_PREFIXES = {
    'usuarios', 'empleados', 'clientes', 'horarios', 'servicios', 'productos',
    'servicios_productos', 'citas', 'detalle_citas', 'facturas', 'pagos',
    'movimientos', 'dashboard', 'publico', 'reservas_web', 'webhook', 'cliente',
    'auditoria',
}


@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def servir_frontend(path):
    primer_segmento = path.split('/', 1)[0]
    if primer_segmento in API_PREFIXES or not os.path.isdir(FRONTEND_DIST):
        return {'success': False, 'message': 'Recurso no encontrado'}, 404
    target = os.path.join(FRONTEND_DIST, path)
    if path and os.path.isfile(target):
        return send_from_directory(FRONTEND_DIST, path)
    return send_from_directory(FRONTEND_DIST, 'index.html')


@app.errorhandler(404)
def manejar_no_encontrado(_error):
    return {'success': False, 'message': 'Recurso no encontrado'}, 404


@app.errorhandler(500)
def manejar_error_interno(error):
    app.logger.exception(error)
    return {'success': False, 'message': 'Error interno del servidor'}, 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 4000))
    app.run(debug=False, port=port, host='0.0.0.0')
