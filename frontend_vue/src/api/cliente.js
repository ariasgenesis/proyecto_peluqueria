import apiClient from './client'

const obj = (res) => res.data.data

export const getHistorial = () =>
  apiClient.get('/cliente/historial').then(obj)
