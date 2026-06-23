import apiClient from './client'

const obj = (res) => res.data.data

export const crearPagoNequi = (data) =>
  apiClient.post('/pagos/nequi', data).then(obj)

export const consultarEstadoPago = (transactionId) =>
  apiClient.get(`/pagos/estado/${transactionId}`).then(obj)
