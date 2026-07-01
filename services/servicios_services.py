import re

from models.servicios_model import ServicioModel
from services.base_service import BaseCrudService, NotFoundError, ServiceError


class ServicioService(BaseCrudService):
    model = ServicioModel
    schema = {
        'nombre': {'type': 'str', 'required': True, 'max': 100, 'regex': re.compile(r'^[A-Za-zÀ-ÿÑñ ]+$'), 'regex_error': 'El nombre del servicio solo puede contener letras y espacios'},
        'descripcion': {'type': 'str'},
        'imagen': {'type': 'str', 'max': 255},
        'precio': {'type': 'decimal', 'required': True},
        'duracion': {'type': 'int', 'required': True, 'min': 1},
        'estado': {'type': 'str', 'default': 'activo', 'enum': ['activo', 'inactivo'], 'lower': True},
    }

    def listar_todos(self, page, per_page, filters=None, search=None, include_deleted=False):
        self.sincronizar_estados_por_stock()
        return super().listar_todos(page, per_page, filters, search, include_deleted)

    def _servicios_bloqueados_por_stock(self, cursor, servicio_id):
        cursor.execute(
            "SELECT p.pro_id, p.pro_nombre, p.pro_stock, p.pro_stock_minimo, p.pro_estado "
            "FROM servicios_productos sp "
            "INNER JOIN productos p ON p.pro_id = sp.sep_producto_id "
            "WHERE sp.sep_servicio_id = %s "
            "AND (p.pro_estado <> 'activo' OR p.pro_stock <= p.pro_stock_minimo)",
            (servicio_id,),
        )
        return [
            {
                'id_producto': row[0],
                'nombre': row[1],
                'stock': int(row[2] or 0),
                'stock_minimo': int(row[3] or 0),
                'estado': row[4],
            }
            for row in cursor.fetchall()
        ]

    def validar_stock_para_servicio_activo(self, servicio_id, cursor=None):
        close_cursor = cursor is None
        cursor = cursor or self.mysql.connection.cursor()
        bloqueados = self._servicios_bloqueados_por_stock(cursor, servicio_id)
        if close_cursor:
            cursor.close()
        if bloqueados:
            nombres = ', '.join(p['nombre'] for p in bloqueados)
            raise ServiceError(f'No se puede activar el servicio: stock bajo o agotado en {nombres}', 409)

    def validar_servicios_reservables(self, servicio_ids, cursor=None):
        ids = []
        for servicio_id in servicio_ids or []:
            if isinstance(servicio_id, bool) or not isinstance(servicio_id, int) or servicio_id <= 0:
                raise ServiceError('El campo "servicio_id" debe ser un entero mayor que cero')
            if servicio_id not in ids:
                ids.append(servicio_id)
        if not ids:
            raise ServiceError('Debe seleccionar al menos un servicio')

        close_cursor = cursor is None
        cursor = cursor or self.mysql.connection.cursor()
        self.sincronizar_estados_por_stock(cursor, servicio_ids=ids)

        cursor.execute(
            "SELECT ser_id, ser_nombre, ser_estado FROM servicios "
            "WHERE ser_id IN (" + ", ".join(["%s"] * len(ids)) + ")",
            tuple(ids),
        )
        rows = cursor.fetchall()
        encontrados = {row[0]: row for row in rows}
        faltantes = [servicio_id for servicio_id in ids if servicio_id not in encontrados]
        if faltantes:
            if close_cursor:
                self.mysql.connection.commit()
                cursor.close()
            raise ServiceError(f'Servicio #{faltantes[0]} no encontrado', 404)

        for servicio_id in ids:
            _id, nombre, estado = encontrados[servicio_id]
            bloqueados = self._servicios_bloqueados_por_stock(cursor, servicio_id)
            if bloqueados:
                productos = ', '.join(
                    f'{p["nombre"]} (stock {p["stock"]}, minimo {p["stock_minimo"]})'
                    for p in bloqueados
                )
                if close_cursor:
                    self.mysql.connection.commit()
                    cursor.close()
                raise ServiceError(
                    f'No se puede reservar "{nombre}": stock bajo o agotado en {productos}',
                    409,
                )
            if estado != 'activo':
                if close_cursor:
                    self.mysql.connection.commit()
                    cursor.close()
                raise ServiceError(f'El servicio "{nombre}" esta inactivo y no permite reservas', 409)

        if close_cursor:
            self.mysql.connection.commit()
            cursor.close()

    def actualizar(self, record_id, data, user_id=None):
        if isinstance(data, dict) and str(data.get('estado', '')).lower() == 'activo':
            self.validar_stock_para_servicio_activo(record_id)
        return super().actualizar(record_id, data, user_id)

    def _servicios_en_scope(self, cursor, producto_ids=None, servicio_ids=None):
        params = []
        filtros = []
        if producto_ids:
            producto_ids = [int(pid) for pid in producto_ids if pid]
            if producto_ids:
                filtros.append(
                    "sp.sep_producto_id IN (" + ", ".join(["%s"] * len(producto_ids)) + ")"
                )
                params.extend(producto_ids)
        if servicio_ids:
            servicio_ids = [int(sid) for sid in servicio_ids if sid]
            if servicio_ids:
                filtros.append(
                    "sp.sep_servicio_id IN (" + ", ".join(["%s"] * len(servicio_ids)) + ")"
                )
                params.extend(servicio_ids)

        where = " WHERE " + " OR ".join(filtros) if filtros else ""
        cursor.execute(
            "SELECT DISTINCT s.ser_id, s.ser_nombre, s.ser_estado "
            "FROM servicios s "
            "INNER JOIN servicios_productos sp ON sp.sep_servicio_id = s.ser_id"
            f"{where}",
            tuple(params),
        )
        return cursor.fetchall()

    def estados_servicios_por_stock(self, cursor=None, producto_ids=None, servicio_ids=None):
        close_cursor = cursor is None
        cursor = cursor or self.mysql.connection.cursor()
        servicios = self._servicios_en_scope(cursor, producto_ids, servicio_ids)
        if close_cursor:
            cursor.close()
        return {
            servicio_id: {'nombre': nombre, 'estado': estado}
            for servicio_id, nombre, estado in servicios
        }

    def sincronizar_estados_por_stock(self, cursor=None, producto_ids=None, servicio_ids=None, estados_anteriores=None):
        close_cursor = cursor is None
        cursor = cursor or self.mysql.connection.cursor()
        servicios = self._servicios_en_scope(cursor, producto_ids, servicio_ids)
        cambios = []
        estados_anteriores = estados_anteriores or {}

        for servicio_id, nombre, estado_actual in servicios:
            bloqueados = self._servicios_bloqueados_por_stock(cursor, servicio_id)
            nuevo_estado = 'inactivo' if bloqueados else 'activo'
            anterior = estados_anteriores.get(servicio_id, {})
            estado_anterior = anterior.get('estado', estado_actual)
            nombre_servicio = anterior.get('nombre', nombre)
            if estado_actual != nuevo_estado:
                cursor.execute(
                    "UPDATE servicios SET ser_estado = %s WHERE ser_id = %s",
                    (nuevo_estado, servicio_id),
                )
            if estado_anterior != nuevo_estado:
                cambios.append(
                    {
                        'id_servicio': servicio_id,
                        'nombre': nombre_servicio,
                        'estado_anterior': estado_anterior,
                        'estado_nuevo': nuevo_estado,
                        'productos_bloqueados': bloqueados,
                    }
                )

        if close_cursor:
            self.mysql.connection.commit()
            cursor.close()
        return cambios

    def toggle_estado(self, record_id):
        row = self.model.obtener_por_id(self.mysql, record_id)
        if not row:
            raise NotFoundError('Servicio no encontrado')
        nuevo_estado = 'inactivo' if row.get('estado') == 'activo' else 'activo'
        if nuevo_estado == 'activo':
            self.validar_stock_para_servicio_activo(record_id)
        return self.model.actualizar(self.mysql, record_id, estado=nuevo_estado)
