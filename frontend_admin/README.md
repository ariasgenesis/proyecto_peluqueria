# Salón Admin — Frontend Flutter Web

Panel administrativo para peluquería/estética. Consume la API REST Flask existente con JWT.

## Requisitos

- Flutter 3.16+
- Backend en ejecución (por defecto `http://localhost:4000`)

## Ejecutar

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## URL de la API

Por defecto: `http://localhost:4000`

Para otro entorno:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://tu-api.com
```

## Estructura

```
lib/
├── core/          # Red, tema, errores, storage, utils
├── routes/        # GoRouter + guards
├── shared/        # Layouts y widgets reutilizables
└── modules/       # auth, dashboard, empleados, ...
```

## Fases implementadas

- Dashboard con mini-tarjetas horizontales (datos reales del API)
- Kanban integrado en **Citas**
- CRUD por modales: empleados, clientes, servicios, productos, citas, horarios, facturas, pagos
- Inventario con ajustes de stock (PIN)
- Movimientos (historial admin)
- Sitio público: `/sitio`, `/sitio/servicios`, `/sitio/contacto`

## Conexión API

- Backend: `python app.py` (puerto **4000**)
- Flutter web resuelve la URL: mismo host del navegador + puerto 4000
- Override: `flutter run -d chrome --dart-define=API_BASE_URL=http://TU_IP:4000`
- Rutas de colección con barra final (`/empleados/`) y CORS habilitado en Flask
