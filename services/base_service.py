from datetime import datetime
from decimal import Decimal, InvalidOperation

from flask import current_app


class ServiceError(Exception):
    status_code = 400

    def __init__(self, message, status_code=None):
        super().__init__(message)
        self.message = message
        if status_code is not None:
            self.status_code = status_code


class NotFoundError(ServiceError):
    status_code = 404


class PermissionError(ServiceError):
    status_code = 403


class BaseCrudService:
    model = None
    schema = {}

    def __init__(self, mysql):
        self.mysql = mysql

    def listar_todos(self, page, per_page, filters=None, search=None, include_deleted=False):
        return self.model.listar_todos(self.mysql, page, per_page, filters, search, include_deleted)

    def obtener_por_id(self, record_id):
        return self.model.obtener_por_id(self.mysql, record_id)

    def _validar_payload(self, data, partial=False):
        if not isinstance(data, dict):
            raise ServiceError('El cuerpo de la solicitud debe ser un objeto JSON')

        payload = {}
        for field, rules in self.schema.items():
            present = field in data
            if partial and not present:
                continue
            value = data.get(field)
            if not present and not partial and 'default' in rules:
                value = rules.get('default')
            required = rules.get('required', False) and not partial
            field_type = rules.get('type', 'str')

            if value is None:
                if required:
                    raise ServiceError(f'El campo "{field}" es requerido')
                if present or not partial:
                    payload[field] = None
                continue

            if field_type == 'str':
                if not isinstance(value, str) or (required and not value.strip()):
                    raise ServiceError(f'El campo "{field}" debe ser una cadena de texto')
                value = value.strip()
                if rules.get('lower'):
                    value = value.lower()
                if rules.get('max') and len(value) > rules['max']:
                    raise ServiceError(f'El campo "{field}" supera el maximo de {rules["max"]} caracteres')
                if rules.get('enum') and value not in rules['enum']:
                    raise ServiceError(f'El campo "{field}" debe ser uno de: {", ".join(rules["enum"])}')
                if rules.get('regex') and not rules['regex'].match(value):
                    raise ServiceError(rules.get('regex_error', f'El campo "{field}" tiene un formato invalido'))
                if rules.get('password') or rules.get('pin'):
                    value = current_app.bcrypt.generate_password_hash(value).decode('utf-8')

            elif field_type == 'int':
                if isinstance(value, bool) or not isinstance(value, int):
                    raise ServiceError(f'El campo "{field}" debe ser un numero entero')
                if rules.get('min') is not None and value < rules['min']:
                    raise ServiceError(f'El campo "{field}" debe ser mayor o igual a {rules["min"]}')

            elif field_type == 'decimal':
                try:
                    value = Decimal(str(value))
                except (InvalidOperation, TypeError, ValueError):
                    raise ServiceError(f'El campo "{field}" debe ser un numero valido')
                if value < 0:
                    raise ServiceError(f'El campo "{field}" no puede ser negativo')

            elif field_type == 'date':
                if not isinstance(value, str):
                    raise ServiceError(f'El campo "{field}" debe tener formato YYYY-MM-DD')
                try:
                    datetime.strptime(value, '%Y-%m-%d')
                except ValueError:
                    raise ServiceError(f'El campo "{field}" debe tener formato YYYY-MM-DD')

            elif field_type == 'time':
                if not isinstance(value, str):
                    raise ServiceError(f'El campo "{field}" debe tener formato HH:MM o HH:MM:SS')
                for fmt in ('%H:%M:%S', '%H:%M'):
                    try:
                        datetime.strptime(value, fmt)
                        break
                    except ValueError:
                        continue
                else:
                    raise ServiceError(f'El campo "{field}" debe tener formato HH:MM o HH:MM:SS')

            elif field_type == 'datetime':
                if not isinstance(value, str):
                    raise ServiceError(f'El campo "{field}" debe tener formato YYYY-MM-DD HH:MM:SS')
                try:
                    datetime.strptime(value, '%Y-%m-%d %H:%M:%S')
                except ValueError:
                    raise ServiceError(f'El campo "{field}" debe tener formato YYYY-MM-DD HH:MM:SS')

            payload[field] = value
        return payload

    def crear(self, data, user_id=None):
        return self.model.crear(self.mysql, **self._validar_payload(data))

    def actualizar(self, record_id, data, user_id=None):
        registro = self.model.actualizar(self.mysql, record_id, **self._validar_payload(data, partial=True))
        if not registro:
            raise NotFoundError('Registro no encontrado')
        return registro

    def eliminar(self, record_id, user_id=None):
        if not self.model.eliminar(self.mysql, record_id):
            raise NotFoundError('Registro no encontrado')
        return True
