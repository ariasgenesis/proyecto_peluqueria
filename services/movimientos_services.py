from models.movimientos_model import MovimientoModel
from services.base_service import BaseCrudService


class MovimientoService(BaseCrudService):
    model = MovimientoModel
    schema = {'usuario_id': {'type': 'int', 'required': True, 'min': 1}, 'tipo': {'type': 'str', 'required': True, 'enum': ['crear_factura', 'editar_factura', 'eliminar_factura', 'crear_cita', 'cancelar_cita', 'crear_reserva_web', 'confirmar_pago_wompi', 'agregar_stock', 'descontar_stock', 'editar_producto'], 'lower': True}, 'descripcion': {'type': 'str'}}

    def registrar(self, usuario_id, tipo, descripcion):
        if not usuario_id:
            return None
        return self.model.crear(
            self.mysql,
            usuario_id=usuario_id,
            tipo=tipo,
            descripcion=descripcion
        )
