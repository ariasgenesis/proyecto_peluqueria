from models.base_model import BaseModel


class ServicioModel(BaseModel):
    table = 'servicios'
    id_field = 'id_servicio'
    id_column = 'ser_id'
    fields = [
        ('id_servicio', 'ser_id', 'int'),
        ('nombre', 'ser_nombre', 'str'),
        ('descripcion', 'ser_descripcion', 'str'),
        ('imagen', 'ser_imagen', 'str'),
        ('precio', 'ser_precio', 'decimal'),
        ('duracion', 'ser_duracion', 'int'),
        ('estado', 'ser_estado', 'str'),
        ('created_at', 'created_at', 'datetime'),
        ('updated_at', 'updated_at', 'datetime'),
    ]
    writable_fields = ['nombre', 'descripcion', 'imagen', 'precio', 'duracion', 'estado']
    search_fields = ['ser_nombre', 'ser_descripcion']
    filter_fields = {'estado': 'ser_estado'}
    soft_delete_column = 'ser_estado'
    soft_delete_value = 'inactivo'
