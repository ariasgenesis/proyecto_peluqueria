import apiClient from './client'

const obj  = (res) => res.data.data
const list = (res) => res.data.data   // ya viene paginado internamente

export const listarReservasWeb = (params) =>
  apiClient.get('/reservas_web/', { params }).then(list)

export const cancelarReservaWeb = (id) =>
  apiClient.post(`/reservas_web/${id}/cancelar`).then(obj)

export const actualizarReservaWeb = (id, data) =>
  apiClient.put(`/reservas_web/${id}`, data).then(obj)
