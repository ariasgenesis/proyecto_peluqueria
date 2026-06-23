import axios from 'axios'

import { resolveApiBaseUrl, STORAGE_KEYS } from './config'

const apiClient = axios.create({
  baseURL: resolveApiBaseUrl(),
  headers: { 'Content-Type': 'application/json' },
})

// Inyecta el JWT en cada request.
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem(STORAGE_KEYS.token)
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Maneja 401: limpia sesión y redirige a login (vía bridge inyectado).
let onUnauthorized = null
export function setUnauthorizedHandler(fn) {
  onUnauthorized = fn
}

const AUTH_PATHS = ['/usuarios/login', '/usuarios/registro-cliente']

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    const url = error.config?.url || ''
    const isAuthEndpoint = AUTH_PATHS.some(p => url.includes(p))
    if (error.response?.status === 401 && onUnauthorized && !isAuthEndpoint) {
      onUnauthorized()
    }
    return Promise.reject(error)
  },
)

// Normaliza el error al mensaje del backend ({success, message}).
export function apiErrorMessage(error, fallback = 'Ocurrió un error inesperado') {
  return error.response?.data?.message || error.message || fallback
}

export default apiClient
