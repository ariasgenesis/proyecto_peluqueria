// Resuelve la URL base del backend Flask.
// Prioridad: variable de entorno -> host del navegador en puerto 4000.
export function resolveApiBaseUrl() {
  const fromEnv = import.meta.env.VITE_API_BASE_URL
  if (fromEnv) return fromEnv.replace(/\/$/, '')
  const { protocol, hostname } = window.location
  return `${protocol}//${hostname}:4000`
}

export const STORAGE_KEYS = {
  token: 'salon.access_token',
  usuario: 'salon.usuario',
}
