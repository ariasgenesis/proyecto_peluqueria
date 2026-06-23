# Credenciales de prueba

Creadas por `python database/migrate.py`. Contraseñas hasheadas con bcrypt.

## Usuarios del sistema

| Usuario | Contraseña | Rol | PIN |
|---|---|---|---|
| `admin` | `123456` | Administrador | — |
| `empleado1` | `123456` | Empleado | `1234` |
| `cliente1` | `123456` | Cliente | — |

## Acceso por área

| Área | URL | Roles permitidos |
|---|---|---|
| Sitio público | `http://localhost:5173/` | Todos / sin login |
| Login modal | Botón "Ingresar" en el sitio | Todos los roles |
| Panel admin | `http://localhost:5173/admin` | `admin`, `empleado` |
| Mi cuenta | `http://localhost:5173/mi-cuenta` | `cliente` |

## Notas

- El campo **"Usuario o correo"** acepta el username (`admin`) o el email del usuario.
- `admin` → redirige a `/admin` tras login.
- `empleado1` → redirige a `/admin` (vista filtrada por sus citas).
- `cliente1` → permanece en el sitio público.
- PIN `1234` solo se usa en acciones sensibles del panel admin (facturas, inventario).

## Levantar el sistema

```bash
# Backend
python app.py        # http://localhost:4000

# Frontend
cd frontend_vue
npm run dev          # http://localhost:5173

# Reset base de datos
python database/migrate.py
```
