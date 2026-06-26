from models.facturas_model import FacturaModel
from datetime import datetime
from decimal import Decimal

from services.base_service import BaseCrudService, ServiceError
from services.citas_services import CitaService
from services.empleados_services import EmpleadoService
from services.inventario_services import InventarioService
from services.movimientos_services import MovimientoService


class FacturaService(BaseCrudService):
    model = FacturaModel
    schema = {
        'cita_id': {'type': 'int', 'min': 1},
        'reserva_id': {'type': 'int', 'min': 1},
        'fecha': {'type': 'date', 'required': True},
        'total': {'type': 'decimal', 'required': True},
        'anticipo': {'type': 'decimal', 'default': 0},
        'saldo_pendiente': {'type': 'decimal'},
        'tipo': {'type': 'str', 'required': True, 'enum': ['anticipo', 'servicio']},
        'estado': {'type': 'str', 'default': 'pendiente', 'enum': ['pendiente', 'parcial', 'pagada', 'cancelada'], 'lower': True},
        'inventario_procesado': {'type': 'int', 'default': 0, 'min': 0},
        'generada_por': {'type': 'int', 'min': 1},
        'modificada_por': {'type': 'int', 'min': 1},
        'fecha_modificacion': {'type': 'datetime'}
    }

    def listar_todos(self, page, per_page, filters=None, search=None, include_deleted=False):
        where_sql, params = self._where_clause(filters, search, include_deleted)
        cursor = self.mysql.connection.cursor()
        cursor.execute(
            "SELECT COUNT(DISTINCT f.fac_id) FROM facturas f "
            "LEFT JOIN citas c ON c.cit_id = f.fac_cita_id "
            "LEFT JOIN reservas_web r ON r.res_id = f.fac_reserva_id "
            "LEFT JOIN clientes cli ON cli.cli_id = COALESCE(c.cit_cliente_id, r.res_cliente_id) "
            f"{where_sql}",
            tuple(params),
        )
        total = cursor.fetchone()[0]
        offset = (page - 1) * per_page
        cursor.execute(
            self._select_facturas_sql(where_sql) + " ORDER BY f.fac_id DESC LIMIT %s OFFSET %s",
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
        cursor.execute(self._select_facturas_sql("WHERE f.fac_id = %s"), (record_id,))
        row = cursor.fetchone()
        cursor.close()
        return self._row_to_dict(row) if row else None

    def _where_clause(self, filters=None, search=None, include_deleted=False):
        clauses = []
        params = []
        filters = filters or {}
        if not include_deleted:
            clauses.append("f.fac_estado <> %s")
            params.append('cancelada')
        field_map = {
            'cita_id': 'f.fac_cita_id',
            'reserva_id': 'f.fac_reserva_id',
            'estado': 'f.fac_estado',
            'tipo': 'f.fac_tipo',
            'generada_por': 'f.fac_generada_por',
        }
        for public_name, column in field_map.items():
            value = filters.get(public_name)
            if value not in (None, ''):
                clauses.append(f"{column} = %s")
                params.append(value)
        if search:
            clauses.append(
                "(CAST(f.fac_id AS CHAR) LIKE %s OR CAST(f.fac_cita_id AS CHAR) LIKE %s "
                "OR CAST(f.fac_reserva_id AS CHAR) LIKE %s OR cli.cli_nombre LIKE %s "
                "OR cli.cli_apellido LIKE %s OR cli.cli_documento LIKE %s)"
            )
            params.extend([f"%{search}%"] * 6)
        return (' WHERE ' + ' AND '.join(clauses) if clauses else ''), params

    def _select_facturas_sql(self, where_sql):
        return (
            "SELECT f.fac_id, f.fac_cita_id, f.fac_reserva_id, f.fac_fecha, f.fac_total, "
            "f.fac_anticipo, f.fac_saldo_pendiente, f.fac_tipo, f.fac_estado, "
            "f.fac_inventario_procesado, f.fac_generada_por, f.fac_modificada_por, "
            "f.fac_fecha_modificacion, f.created_at, f.updated_at, "
            "cli.cli_nombre, cli.cli_apellido, "
            "ug.usu_username, eg.emp_nombre, eg.emp_apellido, "
            "um.usu_username, em.emp_nombre, em.emp_apellido "
            "FROM facturas f "
            "LEFT JOIN citas c ON c.cit_id = f.fac_cita_id "
            "LEFT JOIN reservas_web r ON r.res_id = f.fac_reserva_id "
            "LEFT JOIN clientes cli ON cli.cli_id = COALESCE(c.cit_cliente_id, r.res_cliente_id) "
            "LEFT JOIN usuarios ug ON ug.usu_id = f.fac_generada_por "
            "LEFT JOIN empleados eg ON eg.emp_usuario_id = ug.usu_id "
            "LEFT JOIN usuarios um ON um.usu_id = f.fac_modificada_por "
            "LEFT JOIN empleados em ON em.emp_usuario_id = um.usu_id "
            f"{where_sql}"
        )

    def _row_to_dict(self, row):
        cliente = f'{row[15] or ""} {row[16] or ""}'.strip()
        generado_por = f'{row[18] or ""} {row[19] or ""}'.strip() or row[17]
        confirmado_por = f'{row[21] or ""} {row[22] or ""}'.strip() or row[20]
        return {
            'id_factura': row[0],
            'cita_id': row[1],
            'reserva_id': row[2],
            'fecha': str(row[3]) if row[3] is not None else None,
            'total': float(row[4]) if row[4] is not None else 0,
            'anticipo': float(row[5]) if row[5] is not None else 0,
            'saldo_pendiente': float(row[6]) if row[6] is not None else 0,
            'tipo': row[7],
            'estado': row[8],
            'inventario_procesado': row[9],
            'generada_por': row[10],
            'modificada_por': row[11],
            'fecha_modificacion': str(row[12]) if row[12] is not None else None,
            'created_at': str(row[13]) if row[13] is not None else None,
            'updated_at': str(row[14]) if row[14] is not None else None,
            'cliente': cliente,
            'cliente_nombre': row[15],
            'cliente_apellido': row[16],
            'generada_por_nombre': generado_por,
            'confirmada_por_nombre': confirmado_por,
            'empleado_confirmo': confirmado_por,
        }

    def _normalizar_saldo(self, payload):
        anticipo = Decimal(str(payload.get('anticipo') or 0))
        total = Decimal(str(payload.get('total') or 0))
        saldo = total - anticipo
        if saldo < 0:
            raise ServiceError('El anticipo no puede superar el total de la factura')
        payload['saldo_pendiente'] = saldo
        
        # Lógica de estado automática solo si no se provee explícitamente
        if 'estado' not in payload or payload['estado'] not in ['cancelada']:
            if saldo == 0:
                payload['estado'] = 'pagada'
            elif anticipo > 0:
                payload['estado'] = 'parcial'
            else:
                payload['estado'] = 'pendiente'
        return payload

    def _sincronizar_reserva_por_factura(self, cursor, factura_id):
        cursor.execute(
            "SELECT fac_reserva_id, fac_estado FROM facturas WHERE fac_id = %s",
            (factura_id,),
        )
        row = cursor.fetchone()
        if not row or not row[0]:
            return
        reserva_id, estado = row
        if estado == 'pagada':
            cursor.execute("UPDATE reservas_web SET res_estado = 'pagada' WHERE res_id = %s", (reserva_id,))
        elif estado == 'cancelada':
            cursor.execute("UPDATE reservas_web SET res_estado = 'cancelada' WHERE res_id = %s", (reserva_id,))

    def asegurar_cita_para_factura_pagada(self, cursor, factura_id, user_id=None):
        cursor.execute(
            "SELECT f.fac_cita_id, f.fac_reserva_id, r.res_cliente_id, r.res_empleado_id, r.res_fecha, r.res_hora "
            "FROM facturas f "
            "LEFT JOIN reservas_web r ON r.res_id = f.fac_reserva_id "
            "WHERE f.fac_id = %s FOR UPDATE",
            (factura_id,),
        )
        row = cursor.fetchone()
        if not row or row[0] or not row[1]:
            return row[0] if row else None

        _cita_id, reserva_id, cliente_id, empleado_id, fecha, hora = row
        if not cliente_id:
            raise ServiceError('La reserva web no tiene cliente asociado', 409)

        cursor.execute(
            "SELECT drv_servicio_id, drv_precio FROM detalle_reservas_web WHERE drv_reserva_id = %s",
            (reserva_id,),
        )
        servicios = cursor.fetchall()
        if not servicios:
            raise ServiceError('La reserva web no tiene servicios para generar la cita', 409)
        servicios_ids = [s[0] for s in servicios]

        cursor.execute(
            "SELECT f2.fac_cita_id FROM facturas f2 "
            "WHERE f2.fac_reserva_id = %s AND f2.fac_cita_id IS NOT NULL "
            "ORDER BY f2.fac_id DESC LIMIT 1",
            (reserva_id,),
        )
        cita_existente = cursor.fetchone()
        cita_id = cita_existente[0] if cita_existente else None

        if not cita_id:
            cursor.execute(
                "SELECT cit_id FROM citas "
                "WHERE cit_cliente_id = %s AND cit_fecha = %s AND cit_hora = %s "
                "AND cit_origen = 'web' AND cit_estado <> 'cancelada' "
                "ORDER BY cit_id DESC LIMIT 1",
                (cliente_id, fecha, hora),
            )
            cita = cursor.fetchone()
            cita_id = cita[0] if cita else None

        if not cita_id:
            if not empleado_id:
                empleado_id = CitaService(self.mysql).buscar_empleado_disponible(
                    None, str(fecha), str(hora), cursor=cursor, servicios_ids=servicios_ids
                )
                cursor.execute("UPDATE reservas_web SET res_empleado_id = %s WHERE res_id = %s", (empleado_id, reserva_id))
            else:
                CitaService(self.mysql).validar_disponibilidad_publica(
                    empleado_id, str(fecha), str(hora), cursor=cursor,
                    reserva_id=reserva_id, servicios_ids=servicios_ids
                )

            cursor.execute(
                "INSERT INTO citas (cit_cliente_id, cit_empleado_id, cit_fecha, cit_hora, cit_origen, cit_estado, cit_creado_por) "
                "VALUES (%s, %s, %s, %s, 'web', 'confirmada', %s)",
                (cliente_id, empleado_id, fecha, hora, user_id),
            )
            cita_id = cursor.lastrowid
            for servicio_id, precio in servicios:
                cursor.execute(
                    "INSERT INTO detalle_citas (dci_cita_id, dci_servicio_id, dci_precio) VALUES (%s, %s, %s)",
                    (cita_id, servicio_id, precio),
                )
            cursor.execute(
                "INSERT INTO movimientos (mov_usuario_id, mov_tipo, mov_descripcion) VALUES (%s, 'crear_cita', %s)",
                (user_id, f'Cita #{cita_id} creada desde reserva web #{reserva_id}'),
            )
        else:
            cursor.execute("SELECT COUNT(*) FROM detalle_citas WHERE dci_cita_id = %s", (cita_id,))
            if cursor.fetchone()[0] == 0:
                for servicio_id, precio in servicios:
                    cursor.execute(
                        "INSERT INTO detalle_citas (dci_cita_id, dci_servicio_id, dci_precio) VALUES (%s, %s, %s)",
                        (cita_id, servicio_id, precio),
                    )

        cursor.execute("UPDATE facturas SET fac_cita_id = %s WHERE fac_id = %s", (cita_id, factura_id))
        return cita_id

    def crear(self, data, user_id=None):
        if not isinstance(data, dict):
            raise ServiceError('El cuerpo de la solicitud debe ser un objeto JSON')
        
        EmpleadoService(self.mysql).validar_pin_usuario(user_id, data.get('pin'), data.get('pin_empleado_id'))
        
        payload = self._validar_payload(data)
        payload['generada_por'] = payload.get('generada_por') or user_id
        if not payload['generada_por']:
            raise ServiceError('No se pudo identificar el usuario generador')
            
        payload.pop('modificada_por', None)
        payload.pop('fecha_modificacion', None)
        payload = self._normalizar_saldo(payload)
        payload['inventario_procesado'] = 0

        cursor = self.mysql.connection.cursor()
        try:
            cursor.execute(
                "INSERT INTO facturas "
                "(fac_cita_id, fac_reserva_id, fac_fecha, fac_total, fac_anticipo, fac_saldo_pendiente, "
                "fac_tipo, fac_estado, fac_generada_por, fac_inventario_procesado) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 0)",
                (
                    payload.get('cita_id'),
                    payload.get('reserva_id'),
                    payload['fecha'],
                    payload['total'],
                    payload['anticipo'],
                    payload['saldo_pendiente'],
                    payload['tipo'],
                    payload['estado'],
                    payload['generada_por'],
                ),
            )
            factura_id = cursor.lastrowid
            
            cursor.execute(
                "INSERT INTO movimientos (mov_usuario_id, mov_tipo, mov_descripcion) VALUES (%s, 'crear_factura', %s)",
                (user_id or payload['generada_por'], f'Factura #{factura_id} creada'),
            )
            
            # SOLO descontar inventario si es tipo SERVICIO y estado PAGADA
            if payload['tipo'] == 'servicio' and payload['estado'] == 'pagada':
                self.asegurar_cita_para_factura_pagada(cursor, factura_id, user_id or payload['generada_por'])
                InventarioService(self.mysql).procesar_factura_pagada(cursor, factura_id, user_id or payload['generada_por'])
            self._sincronizar_reserva_por_factura(cursor, factura_id)

            self.mysql.connection.commit()
        except Exception:
            self.mysql.connection.rollback()
            raise
        finally:
            cursor.close()
            
        return self.obtener_por_id(factura_id)

    def actualizar(self, record_id, data, user_id=None):
        if not isinstance(data, dict):
            raise ServiceError('El cuerpo de la solicitud debe ser un objeto JSON')
            
        actual = self.model.obtener_por_id(self.mysql, record_id)
        if not actual:
            raise ServiceError('Factura no encontrada', 404)
            
        # RESTRICCIÓN: Solo facturas PENDIENTES pueden modificarse estructuralmente (total, servicios)
        # Si está parcial o pagada, solo se deberían permitir pagos (que usualmente no pasan por aquí sino por PagosService)
        if actual['estado'] in ['pagada', 'parcial', 'cancelada']:
            # Solo permitir cambios que no afecten el total o tipo si ya está en proceso de pago
            if any(k in data for k in ('total', 'tipo', 'cita_id', 'reserva_id')):
                 raise ServiceError(f'Las facturas en estado {actual["estado"]} no permiten cambios estructurales', 409)

        EmpleadoService(self.mysql).validar_pin_usuario(user_id, data.get('pin'), data.get('pin_empleado_id'))
        
        payload = self._validar_payload(data, partial=True)
        merged = {**actual, **payload}
        normalizado = self._normalizar_saldo(merged)
        
        payload['anticipo'] = normalizado['anticipo']
        payload['saldo_pendiente'] = normalizado['saldo_pendiente']
        payload['estado'] = normalizado['estado']
        payload['modificada_por'] = user_id
        payload['fecha_modificacion'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        cursor = self.mysql.connection.cursor()
        try:
            field_map = {
                'cita_id': 'fac_cita_id',
                'reserva_id': 'fac_reserva_id',
                'fecha': 'fac_fecha',
                'total': 'fac_total',
                'anticipo': 'fac_anticipo',
                'saldo_pendiente': 'fac_saldo_pendiente',
                'tipo': 'fac_tipo',
                'estado': 'fac_estado',
                'inventario_procesado': 'fac_inventario_procesado',
                'generada_por': 'fac_generada_por',
                'modificada_por': 'fac_modificada_por',
                'fecha_modificacion': 'fac_fecha_modificacion',
            }
            assignments = []
            values = []
            for field, column in field_map.items():
                if field in payload:
                    assignments.append(f'{column} = %s')
                    values.append(payload[field])
            if assignments:
                cursor.execute(
                    f"UPDATE facturas SET {', '.join(assignments)} WHERE fac_id = %s",
                    tuple(values + [record_id]),
                )
                if cursor.rowcount == 0:
                    raise ServiceError('Factura no encontrada', 404)
                
            if payload.get('estado') == 'pagada':
                self.asegurar_cita_para_factura_pagada(cursor, record_id, user_id)
                InventarioService(self.mysql).procesar_factura_pagada(cursor, record_id, user_id)
            self._sincronizar_reserva_por_factura(cursor, record_id)

            # Verificar si con el cambio pasó a PAGADA y es de tipo SERVICIO
            self.mysql.connection.commit()
            MovimientoService(self.mysql).registrar(user_id, 'editar_factura', f'Factura #{record_id} editada')
            return self.obtener_por_id(record_id)
        except Exception:
            self.mysql.connection.rollback()
            raise
        finally:
            cursor.close()

    def eliminar(self, record_id, user_id=None):
        cursor = self.mysql.connection.cursor()
        cursor.execute("SELECT fac_id, fac_estado FROM facturas WHERE fac_id = %s", (record_id,))
        existe = cursor.fetchone()
        cursor.close()
        
        if not existe:
            raise ServiceError('Factura no encontrada', 404)
        if existe[1] == 'pagada':
            raise ServiceError('Las facturas pagadas no pueden cancelarse', 409)
            
        if not self.model.eliminar(self.mysql, record_id):
            raise ServiceError('Factura no encontrada', 404)
            
        MovimientoService(self.mysql).registrar(user_id, 'eliminar_factura', f'Factura #{record_id} cancelada')
        return True

    def eliminar_con_pin(self, record_id, data, user_id=None):
        if not isinstance(data, dict):
            raise ServiceError('El cuerpo de la solicitud debe ser un objeto JSON')
        EmpleadoService(self.mysql).validar_pin_usuario(user_id, data.get('pin'), data.get('pin_empleado_id'))
        return self.eliminar(record_id, user_id)
