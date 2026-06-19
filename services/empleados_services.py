import re

from flask import current_app

from models.empleados_model import EmpleadoModel
from services.base_service import BaseCrudService, NotFoundError, PermissionError, ServiceError


class EmpleadoService(BaseCrudService):
    model = EmpleadoModel
    schema = {
        'nombre': {'type': 'str', 'required': True, 'max': 50},
        'apellido': {'type': 'str', 'required': True, 'max': 50},
        'documento': {'type': 'str', 'required': True, 'max': 20},
        'telefono': {'type': 'str', 'max': 20},
        'username': {'type': 'str', 'max': 50},
        'email': {'type': 'str', 'max': 100},
        'pin': {'type': 'str', 'required': True, 'max': 4},
        'rol': {'type': 'str', 'default': 'empleado', 'enum': ['admin', 'empleado'], 'lower': True},
        'cargo': {'type': 'str', 'max': 50},
        'estado': {'type': 'str', 'default': 'activo', 'enum': ['activo', 'inactivo'], 'lower': True},
    }

    def listar_todos(self, page, per_page, filters=None, search=None, include_deleted=False):
        where_sql, params = self._where_clause(filters, search, include_deleted)
        cursor = self.mysql.connection.cursor()
        cursor.execute(f"SELECT COUNT(*) FROM empleados e INNER JOIN usuarios u ON u.usu_id = e.emp_usuario_id{where_sql}", tuple(params))
        total = cursor.fetchone()[0]
        offset = (page - 1) * per_page
        cursor.execute(
            "SELECT e.emp_id, e.emp_usuario_id, e.emp_nombre, e.emp_apellido, e.emp_documento, "
            "e.emp_telefono, e.emp_cargo, e.emp_estado, e.created_at, e.updated_at, "
            "u.usu_username, u.usu_email "
            "FROM empleados e INNER JOIN usuarios u ON u.usu_id = e.emp_usuario_id"
            f"{where_sql} ORDER BY e.emp_id DESC LIMIT %s OFFSET %s",
            tuple(params + [per_page, offset]),
        )
        rows = cursor.fetchall()
        cursor.close()
        return {
            'data': [self._row_to_dict(row) for row in rows],
            'total': total,
            'page': page,
            'per_page': per_page,
            'total_pages': (total + per_page - 1) // per_page if total else 0,
        }

    def obtener_por_id(self, record_id):
        cursor = self.mysql.connection.cursor()
        cursor.execute(
            "SELECT e.emp_id, e.emp_usuario_id, e.emp_nombre, e.emp_apellido, e.emp_documento, "
            "e.emp_telefono, e.emp_cargo, e.emp_estado, e.created_at, e.updated_at, "
            "u.usu_username, u.usu_email "
            "FROM empleados e INNER JOIN usuarios u ON u.usu_id = e.emp_usuario_id "
            "WHERE e.emp_id = %s",
            (record_id,),
        )
        row = cursor.fetchone()
        cursor.close()
        return self._row_to_dict(row) if row else None

    def crear(self, data, user_id=None):
        payload = self._validar_empleado_payload(data)
        rol = payload.get('rol') or 'empleado'
        username = payload.get('username') or payload['documento']
        email = payload.get('email') or f"{payload['documento']}@staff.local"
        pin_hash = current_app.bcrypt.generate_password_hash(payload['pin']).decode('utf-8')
        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute(
                "INSERT INTO usuarios (usu_username, usu_password, usu_email, usu_rol, usu_estado) "
                "VALUES (%s, %s, %s, %s, %s)",
                (username, pin_hash, email, rol, payload['estado']),
            )
            usuario_id = cursor.lastrowid
            cursor.execute(
                "INSERT INTO empleados (emp_usuario_id, emp_nombre, emp_apellido, emp_documento, "
                "emp_telefono, emp_cargo, emp_pin, emp_estado) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                (
                    usuario_id,
                    payload['nombre'],
                    payload['apellido'],
                    payload['documento'],
                    payload.get('telefono'),
                    payload.get('cargo'),
                    pin_hash,
                    payload['estado'],
                ),
            )
            empleado_id = cursor.lastrowid
            self.mysql.connection.commit()
        except Exception as exc:
            self.mysql.connection.rollback()
            raise self._integrity_error(exc)
        finally:
            cursor.close()
        return self.obtener_por_id(empleado_id)

    def actualizar(self, record_id, data, user_id=None):
        actual = self.obtener_por_id(record_id)
        if not actual:
            raise NotFoundError('Empleado no encontrado')
        payload = self._validar_empleado_payload(data, partial=True)
        if not payload:
            return actual

        usuario_fields = []
        usuario_values = []
        if 'username' in payload:
            usuario_fields.append('usu_username = %s')
            usuario_values.append(payload['username'])
        if 'email' in payload:
            usuario_fields.append('usu_email = %s')
            usuario_values.append(payload['email'])
        if 'estado' in payload:
            usuario_fields.append('usu_estado = %s')
            usuario_values.append(payload['estado'])
        if 'pin' in payload:
            pin_hash = current_app.bcrypt.generate_password_hash(payload['pin']).decode('utf-8')
            usuario_fields.append('usu_password = %s')
            usuario_values.append(pin_hash)
            payload['pin'] = pin_hash

        empleado_map = {
            'nombre': 'emp_nombre',
            'apellido': 'emp_apellido',
            'documento': 'emp_documento',
            'telefono': 'emp_telefono',
            'cargo': 'emp_cargo',
            'pin': 'emp_pin',
            'estado': 'emp_estado',
        }
        empleado_fields = []
        empleado_values = []
        for public_name, column in empleado_map.items():
            if public_name in payload:
                empleado_fields.append(f'{column} = %s')
                empleado_values.append(payload[public_name])

        cursor = self.mysql.connection.cursor()
        try:
            if usuario_fields:
                cursor.execute(
                    f"UPDATE usuarios SET {', '.join(usuario_fields)} WHERE usu_id = %s",
                    tuple(usuario_values + [actual['usuario_id']]),
                )
            if empleado_fields:
                cursor.execute(
                    f"UPDATE empleados SET {', '.join(empleado_fields)} WHERE emp_id = %s",
                    tuple(empleado_values + [record_id]),
                )
            self.mysql.connection.commit()
        except Exception as exc:
            self.mysql.connection.rollback()
            raise self._integrity_error(exc)
        finally:
            cursor.close()
        return self.obtener_por_id(record_id)

    def eliminar(self, record_id, user_id=None):
        actual = self.obtener_por_id(record_id)
        if not actual:
            raise NotFoundError('Empleado no encontrado')
        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute("UPDATE empleados SET emp_estado = 'inactivo' WHERE emp_id = %s", (record_id,))
            cursor.execute("UPDATE usuarios SET usu_estado = 'inactivo' WHERE usu_id = %s", (actual['usuario_id'],))
            self.mysql.connection.commit()
        except Exception:
            self.mysql.connection.rollback()
            raise
        finally:
            cursor.close()
        return True

    def validar_pin_usuario(self, usuario_id, pin, empleado_id=None):
        if not pin:
            raise PermissionError('El PIN del empleado es requerido')
        cursor = self.mysql.connection.cursor()
        if empleado_id:
            cursor.execute("SELECT emp_pin FROM empleados WHERE emp_id = %s AND emp_estado = 'activo'", (empleado_id,))
        else:
            cursor.execute("SELECT emp_pin FROM empleados WHERE emp_usuario_id = %s AND emp_estado = 'activo'", (usuario_id,))
        row = cursor.fetchone()
        cursor.close()
        if not row:
            raise PermissionError('No se encontro empleado para validar PIN')
        try:
            pin_valido = current_app.bcrypt.check_password_hash(row[0], pin)
        except ValueError:
            pin_valido = row[0] == pin
            if pin_valido:
                nuevo_hash = current_app.bcrypt.generate_password_hash(pin).decode('utf-8')
                cursor = self.mysql.connection.cursor()
                if empleado_id:
                    cursor.execute("UPDATE empleados SET emp_pin = %s WHERE emp_id = %s", (nuevo_hash, empleado_id))
                else:
                    cursor.execute("UPDATE empleados SET emp_pin = %s WHERE emp_usuario_id = %s", (nuevo_hash, usuario_id))
                self.mysql.connection.commit()
                cursor.close()
        if not pin_valido:
            raise PermissionError('PIN invalido')
        return True

    def _validar_empleado_payload(self, data, partial=False):
        payload = self._validar_payload(data, partial=partial)
        if 'pin' in payload and payload['pin'] is not None:
            if not re.fullmatch(r'\d{4}', payload['pin']):
                raise ServiceError('El PIN debe tener exactamente 4 digitos')
        if 'email' in payload and payload['email'] is not None:
            payload['email'] = payload['email'].strip().lower()
            if '@' not in payload['email']:
                raise ServiceError('El correo no tiene un formato valido')
        if 'documento' in payload and payload['documento'] is not None:
            payload['documento'] = payload['documento'].strip()
            if not payload['documento']:
                raise ServiceError('El campo "documento" es requerido')
        return payload

    def _where_clause(self, filters=None, search=None, include_deleted=False):
        clauses = []
        params = []
        filters = filters or {}
        if not include_deleted:
            clauses.append("e.emp_estado = %s")
            params.append('activo')
        if filters.get('estado'):
            clauses.append("e.emp_estado = %s")
            params.append(filters['estado'])
        if filters.get('cargo'):
            clauses.append("e.emp_cargo = %s")
            params.append(filters['cargo'])
        if search:
            clauses.append(
                "(e.emp_nombre LIKE %s OR e.emp_apellido LIKE %s OR e.emp_documento LIKE %s "
                "OR e.emp_telefono LIKE %s OR e.emp_cargo LIKE %s OR u.usu_username LIKE %s OR u.usu_email LIKE %s)"
            )
            params.extend([f"%{search}%"] * 7)
        return (' WHERE ' + ' AND '.join(clauses) if clauses else ''), params

    def _row_to_dict(self, row):
        return {
            'id_empleado': row[0],
            'usuario_id': row[1],
            'nombre': row[2],
            'apellido': row[3],
            'documento': row[4],
            'telefono': row[5],
            'cargo': row[6],
            'estado': row[7],
            'created_at': str(row[8]) if row[8] is not None else None,
            'updated_at': str(row[9]) if row[9] is not None else None,
            'username': row[10],
            'email': row[11],
        }

    def _integrity_error(self, exc):
        message = str(exc).lower()
        if 'duplicate' in message or 'duplicada' in message:
            return ServiceError('Ya existe un usuario, correo o documento con esos datos', 409)
        return ServiceError('No se pudo guardar el empleado')
