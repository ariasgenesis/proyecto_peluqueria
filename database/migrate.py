"""
Runner de migraciones + seed para el proyecto peluquería.

Uso (desde la raíz del repo o desde database/):
    python database/migrate.py            # migra (DDL) + seed completo
    python database/migrate.py --schema   # solo DDL (migraciones)
    python database/migrate.py --seed     # solo seed (base + catálogo)

- Crea la base de datos con el nombre de MYSQL_DB del .env (resuelve el
  desajuste gestiondb/gestionbd del script original).
- Las contraseñas y el PIN se guardan HASHEADOS con bcrypt (la app usa bcrypt).
- El schema hace DROP de las tablas: reejecutar = reset limpio.

Credenciales de prueba creadas:
    admin / 123456      (rol admin)
    empleado1 / 123456  (rol empleado, PIN 1234)
    cliente1 / 123456   (rol cliente)
"""
import os
import sys

import bcrypt
import MySQLdb
from dotenv import load_dotenv

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(os.path.dirname(BASE_DIR), '.env'))

DB_NAME = os.getenv('MYSQL_DB', 'gestiondb')


def conectar(use_db=False):
    return MySQLdb.connect(
        host=os.getenv('MYSQL_HOST', 'localhost'),
        user=os.getenv('MYSQL_USER', 'root'),
        passwd=os.getenv('MYSQL_PASSWORD', ''),
        port=int(os.getenv('MYSQL_PORT', 3306)),
        db=DB_NAME if use_db else '',
        charset='utf8mb4',
    )


def hash_secret(texto):
    return bcrypt.hashpw(texto.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


def _strip_comments(texto):
    lineas = [l for l in texto.splitlines() if not l.strip().startswith('--')]
    return '\n'.join(lineas)


def ejecutar_sql_simple(cursor, ruta):
    """Ejecuta un .sql separando sentencias por ';' (sin triggers/rutinas)."""
    sql = _strip_comments(open(ruta, encoding='utf-8').read())
    n = 0
    for sentencia in sql.split(';'):
        if sentencia.strip():
            cursor.execute(sentencia)
            n += 1
    return n


def ejecutar_sql_bloques(cursor, ruta):
    """Ejecuta un .sql separando por el marcador de sentencia (triggers).

    Quita los comentarios ANTES de partir, así el marcador no se confunde
    si aparece dentro de un comentario.
    """
    n = 0
    for bloque in open(ruta, encoding='utf-8').read().split('-- @stmt'):
        cuerpo = _strip_comments(bloque).strip()
        if cuerpo:
            cursor.execute(cuerpo)
            n += 1
    return n


def crear_base():
    conn = conectar(use_db=False)
    cur = conn.cursor()
    cur.execute(
        f"CREATE DATABASE IF NOT EXISTS {DB_NAME} "
        "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    )
    conn.commit()
    cur.close()
    conn.close()
    print(f"[ok] base de datos '{DB_NAME}' lista")


def migrar(cur):
    mig_dir = os.path.join(BASE_DIR, 'migrations')
    print(f"[..] ejecutando schema 001 ({ejecutar_sql_simple(cur, os.path.join(mig_dir, '001_schema.sql'))} sentencias)")
    print(f"[..] ejecutando triggers 002 ({ejecutar_sql_bloques(cur, os.path.join(mig_dir, '002_triggers.sql'))} sentencias)")
    print("[ok] migraciones aplicadas")


def seed_base(cur):
    pwd = hash_secret('123456')
    pin = hash_secret('1234')

    cur.executemany(
        "INSERT INTO usuarios (usu_username, usu_password, usu_email, usu_rol) VALUES (%s, %s, %s, %s)",
        [
            ('admin', pwd, 'admin@test.com', 'admin'),
            ('empleado1', pwd, 'empleado@test.com', 'empleado'),
            ('cliente1', pwd, 'cliente@test.com', 'cliente'),
        ],
    )
    # IDs: admin=1, empleado1=2, cliente1=3
    cur.execute(
        "INSERT INTO empleados (emp_usuario_id, emp_documento, emp_nombre, emp_apellido, "
        "emp_telefono, emp_cargo, emp_especialidad, emp_pin) "
        "VALUES (2, '10203040', 'Ana', 'Lopez', '3001234567', 'Estilista', 'Corte y peinado', %s)",
        (pin,),
    )
    cur.execute(
        "INSERT INTO clientes (cli_usuario_id, cli_documento, cli_nombre, cli_apellido, "
        "cli_telefono, cli_direccion) "
        "VALUES (3, '50607080', 'Juan', 'Perez', '3009876543', 'Calle 123')"
    )
    # Horario del empleado 1: lunes a sábado
    horario = [(1, dia, '09:00:00', '18:00:00') for dia in
               ('lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado')]
    cur.executemany(
        "INSERT INTO horarios (hor_empleado_id, hor_dia_semana, hor_hora_inicio, hor_hora_fin) "
        "VALUES (%s, %s, %s, %s)",
        horario,
    )
    print("[ok] seed base (usuarios, empleado, cliente, horarios)")


def seed_catalogo(cur):
    ruta = os.path.join(BASE_DIR, 'seeds', 'catalogo.sql')
    print(f"[ok] seed catálogo ({ejecutar_sql_simple(cur, ruta)} sentencias)")


def main():
    args = set(sys.argv[1:])
    solo_schema = '--schema' in args
    solo_seed = '--seed' in args
    hacer_todo = not (solo_schema or solo_seed)

    crear_base()
    conn = conectar(use_db=True)
    cur = conn.cursor()
    try:
        if solo_schema or hacer_todo:
            migrar(cur)
        if solo_seed or hacer_todo:
            seed_base(cur)
            seed_catalogo(cur)
        conn.commit()
        print("\n[OK] Listo. Credenciales: admin/123456 | empleado1/123456 (PIN 1234) | cliente1/123456")
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == '__main__':
    main()
