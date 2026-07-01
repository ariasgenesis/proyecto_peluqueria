import apiClient from './client'

// Helpers
const list = (res) => res.data.data.data   // {success, data:{data:[...], total,...}}
const obj  = (res) => res.data.data        // {success, data:{...}}

// Dashboard
export const getDashboardAdmin    = () => apiClient.get('/dashboard/admin').then(obj)
export const getDashboardEmpleado = () => apiClient.get('/dashboard/empleado').then(obj)
export const getDashboardKanban   = (params) => apiClient.get('/dashboard/kanban', { params }).then(obj)
export const getDashboardAlertas  = () => apiClient.get('/dashboard/alertas').then(obj)

// CRUD lists — per_page=100 (backend max)
export const getClientes    = (params) => apiClient.get('/clientes/',    { params: { page:1, per_page:100, ...params } }).then(list)
export const getEmpleados   = (params) => apiClient.get('/empleados/',   { params: { page:1, per_page:100, ...params } }).then(list)
export const getProductos   = (params) => apiClient.get('/productos/',   { params: { page:1, per_page:100, include_deleted: true, ...params } }).then(list)
export const getFacturas    = (params) => apiClient.get('/facturas/',    { params: { page:1, per_page:100, ...params } }).then(list)
export const getFactura     = (id) => apiClient.get(`/facturas/${id}`).then(obj)
export const getMovimientos = (params) => apiClient.get('/movimientos/', { params: { page:1, per_page:100, ...params } }).then(list)

// Stock (pin requerido por el backend)
export const agregarStock   = (id, cantidad, pin) => apiClient.post(`/productos/${id}/agregar-stock`,   { cantidad, pin }).then(obj)
export const descontarStock = (id, cantidad, pin) => apiClient.post(`/productos/${id}/descontar-stock`, { cantidad, pin }).then(obj)

// Productos CRUD
export const createProducto = (data) => apiClient.post('/productos/', data).then(obj)
export const updateProducto = (id, data) => apiClient.put(`/productos/${id}`, data).then(obj)
export const deleteProducto = (id) => apiClient.delete(`/productos/${id}`).then(obj)

// Facturas CRUD (crear/actualizar requieren pin)
export const createFactura  = (data) => apiClient.post('/facturas/', data).then(obj)
export const updateFactura  = (id, data) => apiClient.put(`/facturas/${id}`, data).then(obj)
export const deleteFactura  = (id) => apiClient.delete(`/facturas/${id}`).then(obj)

// Clientes CRUD
export const createCliente  = (data) => apiClient.post('/clientes/', data).then(obj)
export const updateCliente  = (id, data) => apiClient.put(`/clientes/${id}`, data).then(obj)
export const deleteCliente  = (id) => apiClient.delete(`/clientes/${id}`).then(obj)

// Empleados CRUD
export const createEmpleado = (data) => apiClient.post('/empleados/', data).then(obj)
export const updateEmpleado = (id, data) => apiClient.put(`/empleados/${id}`, data).then(obj)
export const deleteEmpleado = (id) => apiClient.delete(`/empleados/${id}`).then(obj)

// Citas CRUD
export const getCitas           = (params) => apiClient.get('/citas/', { params: { page: 1, per_page: 100, ...params } }).then(list)
export const getCita            = (id) => apiClient.get(`/citas/${id}`).then(obj)
export const createCita         = (data) => apiClient.post('/citas/', data).then(obj)
export const updateCita         = (id, data) => apiClient.put(`/citas/${id}`, data).then(obj)
export const editarDinamicaCita = (id, data) => apiClient.put(`/citas/${id}/editar-dinamica`, data).then(obj)
export const deleteCita         = (id) => apiClient.delete(`/citas/${id}`).then(obj)
export const getDetallesCitas   = (params) => apiClient.get('/detalle_citas/', { params: { page: 1, per_page: 100, ...params } }).then(list)

// Servicios CRUD
export const getServicios    = (params) => apiClient.get('/servicios/', { params: { page: 1, per_page: 100, include_deleted: true, ...params } }).then(list)
export const createServicio  = (data) => apiClient.post('/servicios/', data).then(obj)
export const updateServicio  = (id, data) => apiClient.put(`/servicios/${id}`, data).then(obj)
export const toggleServicio  = (id) => apiClient.patch(`/servicios/${id}/toggle-estado`).then(obj)

// Productos vinculados a servicios
export const getServiciosProductos    = (params) => apiClient.get('/servicios_productos/', { params: { page: 1, per_page: 100, ...params } }).then(list)
export const createServicioProducto   = (data) => apiClient.post('/servicios_productos/', data).then(obj)
export const updateServicioProducto   = (id, data) => apiClient.put(`/servicios_productos/${id}`, data).then(obj)
export const deleteServicioProducto   = (id) => apiClient.delete(`/servicios_productos/${id}`).then(obj)

// Pagos
export const getPagos = (params) => apiClient.get('/pagos/', { params: { page: 1, per_page: 100, ...params } }).then(list)
export const crearPago = (data) => apiClient.post('/pagos/', data).then(obj)

// Reservas web (admin)
export const getReservaWeb = (id) => apiClient.get(`/reservas_web/${id}`).then(obj)

// Auditoría y Desempeño del Personal
export const getAuditoriaResumen = (params) =>
  apiClient.get('/auditoria/resumen', { params }).then(obj)

// Formateo moneda COP
export const fmtCOP = (n) =>
  n == null ? '—' : '$' + Number(n).toLocaleString('es-CO', { minimumFractionDigits: 0, maximumFractionDigits: 0 })
