# Sistema de Gestion para Peluqueria

![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-Backend-000000?logo=flask&logoColor=white)
![Vue.js](https://img.shields.io/badge/Vue.js-Frontend-4FC08D?logo=vuedotjs&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-Database-4479A1?logo=mysql&logoColor=white)
![Swagger](https://img.shields.io/badge/Swagger-API_Docs-85EA2D?logo=swagger&logoColor=black)
![JWT](https://img.shields.io/badge/JWT-Auth-000000?logo=jsonwebtokens&logoColor=white)

Plataforma web para administrar la operacion de una peluqueria o estetica con flujo constante de clientes, empleados, citas, inventario, facturacion y reservas web con anticipo. El sistema combina un backend Flask modular, una SPA en Vue.js orientada a mobile first y una base de datos MySQL.

## Descripcion General

El proyecto resuelve la gestion integral de una peluqueria desde dos frentes principales:

- Dashboard administrativo interno para operar citas, empleados, inventario, facturas, pagos, auditoria y reportes.
- Sitio publico para clientes, desde el cual se pueden consultar servicios, registrarse, iniciar sesion, reservar citas, pagar anticipos y consultar historial.

El flujo principal permite que un cliente reserve en linea, seleccione servicio, empleado y horario disponible, pague un anticipo mediante Wompi Sandbox y genere automaticamente la informacion operativa necesaria para el dashboard: cita, factura parcial, registro de pago y movimiento de auditoria.

## Caracteristicas Principales

- Autenticacion con JWT y roles para administrador, empleado y cliente.
- Gestion de usuarios, clientes y empleados.
- Agenda de citas con estados: pendiente, confirmada, cancelada y completada.
- Reservas web con estados: pendiente, pagada y cancelada.
- Validacion de disponibilidad para evitar cruces de horarios.
- Dashboard administrativo con vista operativa tipo Kanban.
- Gestion dinamica de tarjetas para cambiar estilista, modificar servicios, agregar servicios adicionales y recalcular saldos.
- Facturacion con pagos parciales, anticipos, metodos mixtos y bloqueo de edicion cuando la factura esta pagada o cancelada.
- Registro de pagos por efectivo, transferencia, tarjeta y Wompi.
- Inventario con productos unitarios y productos de control manual.
- Alertas de stock bajo, citas retrasadas y movimientos recientes.
- Validacion por PIN de empleado para acciones sensibles.
- Auditoria de movimientos sobre facturas, citas, inventario, reservas y pagos.
- Dashboard de cliente con proximas citas, historial de citas e historial de facturas.
- Horarios de empleados, bloqueos de agenda y validacion de jornada laboral.
- Documentacion interactiva de API con Swagger/Flasgger.

## Arquitectura y Tecnologias

### Backend

- Python 3.x
- Flask
- Flask-CORS
- Flask-MySQLdb
- PyMySQL
- Flask-JWT-Extended
- Flask-Bcrypt
- Flasgger / Swagger
- python-dotenv

El backend sigue una organizacion modular inspirada en MVC:

- `routes/`: definicion de endpoints y blueprints.
- `controllers/`: capa de entrada para coordinar solicitudes HTTP.
- `services/`: reglas de negocio, validaciones y procesos transaccionales.
- `models/`: acceso a datos y consultas MySQL.
- `middlewares/`: validacion de autenticacion, autorizacion y roles.
- `database/`: migraciones, seeds y scripts auxiliares de base de datos.

### Frontend

- Vue.js 3
- Vite
- Vue Router
- Pinia
- Axios
- CSS personalizado
- Mapbox GL para el mapa del salon

### Base de Datos

- MySQL
- Migraciones SQL versionadas en `database/migrations/`
- Datos semilla en `database/seeds/`
- Runner de migracion en `database/migrate.py`

### Integraciones

- Wompi Sandbox para anticipo de reservas.
- Webhook de Wompi para confirmacion de pagos.

## Estructura del Proyecto

```text
proyecto_peluqueria/
├── app.py                         # Punto de entrada del backend Flask
├── config.py                      # Configuracion por variables de entorno
├── requirements.txt               # Dependencias Python
├── swagger.json                   # Especificacion Swagger de la API
├── .env.example                   # Plantilla segura de variables de entorno
├── controllers/                   # Controladores HTTP
├── middlewares/                   # Middlewares de autenticacion/autorizacion
├── models/                        # Modelos y acceso a datos MySQL
├── routes/                        # Blueprints y rutas de la API
├── services/                      # Logica de negocio
├── database/
│   ├── README.md                  # Guia especifica de base de datos
│   ├── migrate.py                 # Runner de migraciones y seed
│   ├── migrations/                # Scripts DDL versionados
│   ├── seeds/                     # Catalogos y datos iniciales
│   ├── activosubicaciones.sql     # Script SQL auxiliar archivado
│   ├── insertsproductos.txt       # Inserts auxiliares archivados
│   └── base de datos final (1).txt # Respaldo/script SQL historico archivado
├── docs/
│   └── requerimientos_actualizados.txt # Requerimientos funcionales archivados
└── frontend_vue/
    ├── package.json               # Dependencias y scripts del frontend
    ├── vite.config.js             # Configuracion Vite
    ├── public/                    # Imagenes y recursos estaticos
    └── src/                       # SPA Vue.js
```

## Instalacion y Configuracion

### 1. Clonar el repositorio

```bash
git clone https://github.com/USUARIO/NOMBRE_REPOSITORIO.git
cd NOMBRE_REPOSITORIO
```

### 2. Crear entorno virtual del backend

En Windows PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

En macOS/Linux:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. Configurar variables de entorno

Copia la plantilla segura:

```bash
cp .env.example .env
```

En Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Luego ajusta los valores reales de MySQL, JWT, CORS, Wompi y frontend segun tu ambiente local.

### 4. Configurar base de datos

Crea la base de datos y ejecuta migraciones/seeds con el runner incluido:

```bash
python database/migrate.py
```

Tambien puedes ejecutar fases por separado:

```bash
python database/migrate.py --schema
python database/migrate.py --seed
```

Los scripts SQL auxiliares e historicos se conservan en `database/` para referencia. La guia especifica esta en `database/README.md`.

### 5. Ejecutar backend Flask

```bash
python app.py
```

Por defecto el backend queda disponible en:

```text
http://localhost:4000
```

### 6. Instalar y ejecutar frontend Vue.js

```bash
cd frontend_vue
npm install
npm run dev
```

El frontend de desarrollo normalmente queda disponible en:

```text
http://localhost:5173
```

Para generar una version de produccion:

```bash
npm run build
```

## Documentacion de la API

La API usa Flasgger y carga la especificacion desde `swagger.json`.

Con el backend en ejecucion, abre la documentacion interactiva en:

```text
http://localhost:4000/apidocs/
```

Tambien puedes consultar directamente el archivo `swagger.json` en la raiz del repositorio para revisar endpoints, esquemas, autenticacion Bearer JWT y parametros disponibles.

## Endpoints Principales

- `POST /usuarios/login`: autenticacion y emision de token JWT.
- `POST /usuarios/registro-cliente`: registro publico de cliente.
- `/usuarios`: gestion de usuarios.
- `/empleados`: gestion de empleados.
- `/clientes`: gestion de clientes.
- `/horarios`: configuracion de horarios y bloqueos.
- `/servicios`: catalogo de servicios.
- `/productos`: gestion de inventario y stock bajo.
- `/citas`: gestion de citas.
- `/reservas_web`: reservas online y confirmacion operativa.
- `/facturas`: facturacion.
- `/pagos`: registro y consulta de pagos.
- `/dashboard`: vistas administrativas y operativas.
- `/cliente`: dashboard del cliente.
- `/auditoria`: auditoria del personal.
- `/webhook/wompi`: recepcion de eventos Wompi.
- `/publico`: servicios, empleados y disponibilidad para el sitio publico.

## Seguridad y Buenas Practicas

- No versionar `.env`, credenciales reales ni secretos.
- Usar `.env.example` como unica referencia publica de configuracion.
- Configurar `JWT_SECRET_KEY` con un valor robusto antes de desplegar.
- Restringir `CORS_ORIGINS` en produccion.
- Usar llaves reales de Wompi solo en entornos seguros.
- Si `CREDENCIALES.md` llego a Git, eliminarlo del historial con `git filter-repo` o BFG y rotar las credenciales expuestas.

## Comandos de Limpieza Recomendados

Mover archivos SQL auxiliares a `database/`:

```powershell
Move-Item -LiteralPath "activosubicaciones.sql" -Destination "database\activosubicaciones.sql"
Move-Item -LiteralPath "insertsproductos.txt" -Destination "database\insertsproductos.txt"
Move-Item -LiteralPath "base de datos final (1).txt" -Destination "database\base de datos final (1).txt"
```

Archivar requerimientos fuera de la raiz:

```powershell
New-Item -ItemType Directory -Force docs
Move-Item -LiteralPath "requerimientos_actualizados.txt" -Destination "docs\requerimientos_actualizados.txt"
```

Eliminar archivos de configuracion local de Cursor:

```powershell
Remove-Item -LiteralPath ".cursor" -Recurse -Force
```

Eliminar `CREDENCIALES.md` del indice actual de Git:

```bash
git rm --cached CREDENCIALES.md
```

Eliminar `CREDENCIALES.md` de todo el historial con `git filter-repo`:

```bash
pip install git-filter-repo
git filter-repo --path CREDENCIALES.md --invert-paths
git push origin --force --all
git push origin --force --tags
```

Alternativa con BFG Repo-Cleaner:

```bash
bfg --delete-files CREDENCIALES.md
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push origin --force --all
git push origin --force --tags
```

> Importante: despues de reescribir historial, todos los colaboradores deben reclonar el repositorio o resincronizar sus ramas. Tambien se deben rotar las credenciales que hayan estado expuestas.

