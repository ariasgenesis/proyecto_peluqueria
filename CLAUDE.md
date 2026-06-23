# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Salon/peluquería management system. Two parts:
- **Backend** (repo root): Flask REST API over MySQL. JWT auth, Swagger docs.
- **`frontend_admin/`**: Flutter admin panel (`salon_admin`) — Riverpod + go_router + Dio.
- `frontend_web/` is a stale/empty Flutter scaffold (no `lib/`); ignore unless told otherwise.

All domain naming is Spanish. Roles: `admin`, `empleado`, `cliente`.

## Commands

### Backend
```bash
pip install -r requirements.txt
python app.py            # serves on 0.0.0.0:4000, debug=True
```
Requires a `.env` (loaded by `config.py`) with `MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DB`, `MYSQL_PORT`, `JWT_SECRET_KEY`. Columns are referenced directly in models/raw SQL (no ORM). No backend test suite.

### Database setup
```bash
python database/migrate.py            # create DB + schema + seed (clean reset)
python database/migrate.py --schema   # DDL only
python database/migrate.py --seed     # seed only
```
`database/migrate.py` is the migration/seed runner: creates the DB named by `.env`'s `MYSQL_DB`, applies `database/migrations/*.sql` (DDL + triggers), seeds base users (bcrypt-hashed passwords/PIN) + `database/seeds/catalogo.sql`. `001_schema.sql` DROPs all tables, so re-running resets. Seed logins: `admin/123456`, `empleado1/123456` (PIN `1234`), `cliente1/123456`. See `database/README.md`.

Swagger UI from `swagger.json` (served by flasgger at app startup).

### Frontend admin (`frontend_admin/`)
```bash
flutter pub get
flutter run                       # pick device; web uses same host as browser, port 4000
flutter test                      # all tests
flutter test test/<file>_test.dart   # single test file
flutter analyze
```
API base URL resolved at runtime via `resolveApiBaseUrl()` (web → browser host:4000).

## Backend architecture

Strict 4-layer split, one module per domain entity (`usuarios`, `empleados`, `clientes`, `servicios`, `productos`, `citas`, `facturas`, `pagos`, `movimientos`, `horarios`, `reservas_web`, etc.):

```
routes/<x>.py        Blueprint + URL rules + auth decorator per endpoint
controllers/<x>.py   cnt* thin wrappers, no logic
services/<x>.py      business logic + validation schema
models/<x>.py        BaseModel subclass: table/column/type mapping
```

- **`routes/__init__.py` `cargarRutas(app)`** registers every blueprint with its `url_prefix`. Add new routers here. Note `login_bp` also mounts under `/usuarios`.
- **`models/base_model.py` `BaseModel`** is a generic SQL builder. Each subclass declares `fields` as `(python_name, db_column, type)` tuples — DB columns are table-prefixed (e.g. `ser_id`, `ser_nombre`). `to_dict()`/`_from_row()` map between them. Other knobs: `writable_fields`, `search_fields`, `filter_fields` (public→column), and soft delete via `soft_delete_column`/`soft_delete_value` (flips a status column instead of `DELETE`). Pagination/filter/search all live in `listar_todos` + `_where_clause`.
- **`services/base_service.py` `BaseCrudService`** wires a `model` + a `schema` dict that drives `_validar_payload` (types: str/int/decimal/date/time/datetime; rules: required, default, max, enum, regex, lower, min, and `password`/`pin` which bcrypt-hash). Raise `ServiceError`/`NotFoundError`/`PermissionError` (each carries an HTTP `status_code`).
- **`controllers/base_controller.py`** has generic `listar/obtener/crear/actualizar/eliminar` helpers — pass a service class; they handle pagination, JSON parsing, `ServiceError`→HTTP, and the uniform envelope `{success, message, data}`. Most controllers are one-liners delegating to these.
- **`middlewares/auth_middleware.py`**: `role_required(*roles)` validates JWT, checks `estado == 'activo'`, populates `g.auth_user`. Shortcuts: `admin_required()`, `staff_required()`/`jwt_auth_required()` (admin+empleado). Apply per route function. JWT claims set in `services/auth_services.py`: `username`, `rol`, `estado`.

To add an entity: model (field tuples) → service (model + schema) → controller (delegate to base helpers) → route (blueprint + decorators) → register in `routes/__init__.py`.

### Non-CRUD flows (read the service, not just the base)

Some services override `crear`/`actualizar` and write raw SQL across multiple tables in one transaction (manual `cursor` + `commit`/`rollback`). The booking + payment pipeline is the most involved:

- **`reservas_web_services.py`**: public web booking. `crear` validates services, auto-assigns an available `empleado` via `CitaService.buscar_empleado_disponible`, writes `reservas_web` + `detalle_reservas_web`, and returns a Wompi sandbox payment block.
- **`confirmar_pago_wompi`** (triggered by `routes/webhook.py`): on payment, atomically creates the `citas` + `detalle_citas` records, **two** `facturas` (`anticipo` + `servicio`), a `pagos` row, and `movimientos` audit entries; runs inventory deduction via `InventarioService.procesar_factura_pagada` when fully paid.
- `citas_services.py` owns availability/scheduling logic (`validar_disponibilidad_publica`, `buscar_empleado_disponible`); `movimientos_services.py` records an audit trail — call `MovimientoService(...).registrar(...)` for significant actions.

When editing these, preserve the single-transaction pattern (one cursor, commit once, rollback on exception).

## Frontend admin architecture

Feature-first under `lib/modules/<feature>/` (auth, citas, clientes, dashboard, empleados, facturacion, horarios, inventario, movimientos, pagos, productos, servicios, sitio_publico). Cross-cutting code in `lib/core/` (network, constants, storage, theme) and `lib/shared/` (layouts, widgets, dialogs, providers, kanban, cards). Routing in `lib/routes/app_router.dart` (go_router) + `route_names.dart`. State via Riverpod; HTTP via `core/network/api_client.dart` (Dio + interceptor + `unauthorized_bridge` for 401 handling); tokens/session in `core/storage/`.

### Flutter conventions (`.cursor/rules/flutter-frontend.mdc`)
- API query params: use `apiQuery({...})` (`lib/core/utils/api_query.dart`) or `'key': ?value` maps — never `if (x != null) 'key': x` in map literals.
- Flask collection routes need a trailing slash: `ApiConstants.empleados` → `/empleados/`.
- After every `await`, guard with `if (!context.mounted) return;` before using `context` (Navigator/ScaffoldMessenger/setState).
- `DropdownButtonFormField`: use `initialValue` (not deprecated `value`); add `key: ValueKey(...)` when the value changes via `setState`.
- `child:` argument goes last; use null-aware `?widget` for optional children.
- CRUD lives in modals/drawers (`showAppModal`), not full form pages.
