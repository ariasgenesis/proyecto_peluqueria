import apiClient from './client'

// POST /usuarios/login -> { success, data: { access_token, usuario } }
// Nota: el backend solo acepta roles staff (admin/empleado) en este endpoint.
export async function login(username, password) {
  const { data } = await apiClient.post('/usuarios/login', { username, password })
  return data.data
}

// POST /usuarios/registro-cliente -> { success, data: { access_token, usuario } }
export async function registroCliente(payload) {
  const { data } = await apiClient.post('/usuarios/registro-cliente', payload)
  return data.data
}
