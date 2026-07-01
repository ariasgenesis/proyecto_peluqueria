from uuid import uuid4
import re

from flask import current_app

from models.clientes_model import ClienteModel
from services.base_service import BaseCrudService, ServiceError


class ClienteService(BaseCrudService):
    model = ClienteModel
    schema = {'usuario_id': {'type': 'int', 'min': 1}, 'nombre': {'type': 'str', 'required': True, 'max': 50}, 'apellido': {'type': 'str', 'required': True, 'max': 50}, 'documento': {'type': 'str', 'required': True, 'max': 20, 'regex': re.compile(r'^[0-9]{5,20}$'),'regex_error': 'El documento debe contener solo numeros'}, 'telefono': {'type': 'str', 'max': 20, 'regex': re.compile(r'^\+?[0-9 ]{7,20}$'), 'regex_error': 'El telefono no tiene un formato valido'}, 'direccion': {'type': 'str', 'max': 150}, 'estado': {'type': 'str', 'default': 'activo', 'enum': ['activo', 'inactivo'], 'lower': True}}

    def crear(self, data, user_id=None):
        payload = self._validar_payload(data)
        
        payload['documento'] = payload['documento'].strip()
        if not re.fullmatch(r'^[0-9]{5,20}$', payload['documento']):
            raise ServiceError(
                'El documento debe contener solo numeros'
            )
        if payload.get('usuario_id'):
            return self.model.crear(self.mysql, **payload)

        username = self._generar_username(payload)
        email = self._generar_email(username)
        password_hash = current_app.bcrypt.generate_password_hash(uuid4().hex).decode('utf-8')
        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute(
                "INSERT INTO usuarios (usu_username, usu_password, usu_email, usu_rol, usu_estado) "
                "VALUES (%s, %s, %s, 'cliente', %s)",
                (username, password_hash, email, payload.get('estado') or 'activo'),
            )
            usuario_id = cursor.lastrowid
            cursor.execute(
                "INSERT INTO clientes (cli_usuario_id, cli_nombre, cli_apellido, cli_documento, cli_telefono, cli_direccion, cli_estado) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s)",
                (
                    usuario_id,
                    payload['nombre'],
                    payload['apellido'],
                    payload['documento'],
                    payload.get('telefono'),
                    payload.get('direccion'),
                    payload.get('estado') or 'activo',
                ),
            )
            cliente_id = cursor.lastrowid
            self.mysql.connection.commit()
        except Exception as exc:
            self.mysql.connection.rollback()
            message = str(exc).lower()
            if 'cli_documento' in message: 
                raise ServiceError(
                    'Ya existe un cliente con ese documento',
                    409
                )
            if 'usu_email' in message:
                raise ServiceError(
                    'El correo ya se encuentra registrado',
                    409
                )
            if 'usu_username' in message:
                raise ServiceError(
                    'El nombre de usuario ya existe',
                    409
                )
            if 'duplicate' in message or 'duplicada' in message:
                raise ServiceError(
                    'Ya existe un cliente o usuario con esos datos',
                    409
                )
            raise ServiceError(
                'No se pudo registrar el cliente',
                500
            )
        finally:
            cursor.close()
        return self.model.obtener_por_id(self.mysql, cliente_id)

    def registrar_cliente(self, data):
        if not isinstance(data, dict):
            raise ServiceError('El cuerpo de la solicitud debe ser un objeto JSON')

        required = ['username', 'password', 'email', 'nombre', 'apellido', 'documento']
        for field in required:
            value = data.get(field)
            if not isinstance(value, str) or not value.strip():
                raise ServiceError(f'El campo "{field}" es requerido')

        username = data['username'].strip()
        if len(username) < 3 or len(username) > 50:
            raise ServiceError('El campo "username" debe tener entre 3 y 50 caracteres')
        if not re.fullmatch(r'^[A-Za-z0-9._\-]{3,50}$', username):
            raise ServiceError('El campo "username" solo puede contener letras, números, puntos, guiones y guiones bajos')
        password = data['password']
        if len(password) < 8:
            raise ServiceError('La contraseña debe tener al menos 8 caracteres')
        email = data['email'].strip().lower()
        if not re.fullmatch(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', email):
            raise ServiceError('El correo no tiene un formato valido')
        telefono = data.get('telefono')
        if telefono and not re.fullmatch(r'^\+?[0-9 ]{7,20}$', str(telefono).strip()):
            raise ServiceError('El telefono no tiene un formato valido')
        password_hash = current_app.bcrypt.generate_password_hash(data['password']).decode('utf-8')
        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute(
                "INSERT INTO usuarios (usu_username, usu_password, usu_email, usu_rol, usu_estado) "
                "VALUES (%s, %s, %s, 'cliente', 'activo')",
                (username, password_hash, email),
            )
            usuario_id = cursor.lastrowid
            documento = data['documento'].strip()
            if not re.fullmatch(
                r'^[0-9]{5,20}$',
                documento
            ):
                raise ServiceError('El documento debe contener solo numeros')
            cursor.execute(
                "INSERT INTO clientes (cli_usuario_id, cli_nombre, cli_apellido, cli_documento, cli_telefono, cli_direccion, cli_estado) "
                "VALUES (%s, %s, %s, %s, %s, %s, 'activo')",
                (
                    usuario_id,
                    data['nombre'].strip(),
                    data['apellido'].strip(),
                    documento,
                    str(telefono).strip() if telefono else None,
                    data.get('direccion'),
                ),
            )
            cliente_id = cursor.lastrowid
            self.mysql.connection.commit()
        except ServiceError:
            self.mysql.connection.rollback()
            raise
        except Exception as exc:
            self.mysql.connection.rollback()
            msg = str(exc).lower()
            
            if 'cli_documento' in msg:
                raise ServiceError(
                    'Ya existe un cliente con ese documento',
                    409
            )
            
            if 'usu_email' in msg:
                raise ServiceError(
                    'El correo ya se encuentra registrado',
                    409
                )
            
            if 'usu_username' in msg: 
                raise ServiceError(
                    'El nombre de usuario ya existe',
                    409
                
                )
            if 'duplicate' in msg:
                raise ServiceError(
                    'Ya existe un usuario o documento con esos datos',
                    409
                )
            raise ServiceError('No se pudo registrar el cliente')
        finally:
            cursor.close()

        return {
            'id_usuario': usuario_id,
            'id_cliente': cliente_id,
            'username': username,
            'documento': documento,
            'email': email,
            'rol': 'cliente',
            'estado': 'activo',
        }

    def obtener_cliente_id_por_usuario(self, usuario_id):
        cursor = self.mysql.connection.cursor()
        cursor.execute(
            "SELECT cli_id FROM clientes WHERE cli_usuario_id = %s AND cli_estado = 'activo'",
            (usuario_id,),
        )
        row = cursor.fetchone()
        cursor.close()
        if not row:
            raise ServiceError('No se encontro cliente activo para el usuario autenticado', 404)
        return row[0]

    def _generar_username(self, payload):
        base = f"{payload['nombre']}.{payload['apellido']}".lower()
        base = ''.join(ch for ch in base if ch.isalnum() or ch in '._-').strip('.')
        return f"{base or 'cliente'}_{uuid4().hex[:8]}"

    def _generar_email(self, username):
        return f"{username}@clientes.local"
