# Base de datos

Migraciones + seed del sistema de peluquería.

## Estructura
```
database/
  migrations/
    001_schema.sql     DDL: tablas + índices (hace DROP, reejecutable)
    002_triggers.sql   trigger trg_validar_stock_negativo (sin DELIMITER)
  seeds/
    catalogo.sql       productos (1..18) + servicios (1..12) + servicios_productos
  migrate.py           runner: crea BD, migra, siembra
```

## Uso
Requiere `.env` en la raíz con `MYSQL_HOST/USER/PASSWORD/DB/PORT` (lo lee `migrate.py`).

```bash
python database/migrate.py            # BD + DDL + seed completo (reset limpio)
python database/migrate.py --schema   # solo DDL
python database/migrate.py --seed     # solo seed
```

## Notas importantes
- **Nombre de BD**: el runner usa `MYSQL_DB` del `.env` (el script SQL original
  decía `gestionbd`, el `.env` `gestiondb`; el runner evita ese desajuste).
- **Credenciales hasheadas**: contraseñas y PIN se guardan con bcrypt (la app usa
  bcrypt). El seed SQL original las tenía en texto plano — por eso el seed base se
  hace desde Python, no SQL.
- **Orden del catálogo**: `servicios_productos` referencia IDs por posición
  (productos 1..18, servicios 1..12). No reordenar `catalogo.sql`.
- **Reejecutar resetea**: `001_schema.sql` hace DROP de todas las tablas.

## Credenciales de prueba
| usuario | clave | rol | PIN |
|---|---|---|---|
| admin | 123456 | admin | — |
| empleado1 | 123456 | empleado | 1234 |
| cliente1 | 123456 | cliente | — |
