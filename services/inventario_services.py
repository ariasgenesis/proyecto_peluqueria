from collections import defaultdict
from decimal import Decimal

from services.base_service import ServiceError


class InventarioService:
    def __init__(self, mysql):
        self.mysql = mysql

    def procesar_factura_pagada(self, cursor, factura_id, user_id):
        cursor.execute(
            "SELECT fac_cita_id, fac_estado, COALESCE(fac_inventario_procesado, 0), fac_tipo "
            "FROM facturas WHERE fac_id = %s FOR UPDATE",
            (factura_id,),
        )
        factura = cursor.fetchone()
        if not factura:
            raise ServiceError('Factura no encontrada', 404)

        cita_id, estado, inventario_procesado, tipo = factura
        
        # REGLA: Descontar SOLO cuando fac_tipo = 'servicio' y fac_estado = 'pagada'
        if tipo != 'servicio' or estado != 'pagada':
            return False
            
        if inventario_procesado:
            return False

        if not cita_id:
            # Si no hay cita vinculada, no sabemos qué servicios se prestaron
            # (Aunque en teoría tipo servicio debería tener cita_id)
            return False

        requeridos = self._productos_requeridos(cursor, cita_id)
        totales_por_producto = defaultdict(int)
        for item in requeridos:
            totales_por_producto[item['producto_id']] += item['cantidad']

        for producto_id, requerido in totales_por_producto.items():
            cursor.execute(
                "SELECT pro_nombre, pro_stock FROM productos WHERE pro_id = %s FOR UPDATE",
                (producto_id,),
            )
            producto = cursor.fetchone()
            if not producto:
                raise ServiceError(f'Producto #{producto_id} no encontrado', 404)
            nombre, stock = producto
            if stock < requerido:
                raise ServiceError(f'Stock insuficiente para el producto {nombre}', 409)

        for item in requeridos:
            cursor.execute(
                "UPDATE productos SET pro_stock = pro_stock - %s WHERE pro_id = %s",
                (item['cantidad'], item['producto_id']),
            )
            
            # Adaptado a nombres de columnas del esquema consolidado
            cursor.execute(
                "INSERT INTO movimientos_inventario "
                "(moi_producto_id, moi_usuario_id, moi_factura_id, moi_servicio_id, moi_tipo, moi_cantidad, moi_descripcion) "
                "VALUES (%s, %s, %s, %s, 'salida', %s, %s)",
                (
                    item['producto_id'],
                    user_id,
                    factura_id,
                    item['servicio_id'],
                    item['cantidad'],
                    f'Descuento automatico por factura #{factura_id}'
                ),
            )
            
            cursor.execute(
                "INSERT INTO movimientos (mov_usuario_id, mov_tipo, mov_descripcion) VALUES (%s, 'descontar_stock', %s)",
                (
                    user_id,
                    f'Descuento automatico de {item["cantidad"]} unidades del producto #{item["producto_id"]} por factura #{factura_id}',
                ),
            )

        cursor.execute(
            "UPDATE facturas SET fac_inventario_procesado = 1 WHERE fac_id = %s",
            (factura_id,),
        )
        return True

    def _productos_requeridos(self, cursor, cita_id):
        cursor.execute(
            "SELECT p.pro_id, sp.sep_servicio_id, sp.sep_cantidad "
            "FROM detalle_citas dc "
            "INNER JOIN servicios_productos sp ON sp.sep_servicio_id = dc.dci_servicio_id "
            "INNER JOIN productos p ON p.pro_id = sp.sep_producto_id "
            "WHERE dc.dci_cita_id = %s AND p.pro_tipo_control = 'unitario' AND p.pro_estado = 'activo'",
            (cita_id,),
        )
        acumulados = defaultdict(lambda: {'cantidad': 0, 'servicio_id': None})
        for producto_id, servicio_id, cantidad in cursor.fetchall():
            acumulados[(producto_id, servicio_id)]['producto_id'] = producto_id
            acumulados[(producto_id, servicio_id)]['servicio_id'] = servicio_id
            acumulados[(producto_id, servicio_id)]['cantidad'] += int(cantidad)
        return list(acumulados.values())


def decimal_or_zero(value):
    return Decimal(str(value or 0))
