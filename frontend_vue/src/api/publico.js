import apiClient from './client'

const list = (res) => res.data.data.data   // paginado: {success, data:{data:[],total,...}}
const obj  = (res) => res.data.data        // objeto único

export const listarServiciosPublicos  = (params) =>
  apiClient.get('/publico/servicios', { params: { page: 1, per_page: 100, estado: 'activo', ...params } }).then(list)

export const listarEmpleadosPublicos  = () =>
  apiClient.get('/publico/empleados').then(obj)

export const consultarSlotsDisponibles = (params) =>
  apiClient.get('/publico/slots', { params }).then(obj)

export const crearReservaWeb = (data) =>
  apiClient.post('/reservas_web/', data).then(obj)
