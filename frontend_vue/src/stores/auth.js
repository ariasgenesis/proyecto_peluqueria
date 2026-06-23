import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

import { login as loginRequest, registroCliente } from '@/api/auth'
import { STORAGE_KEYS } from '@/api/config'

const STAFF_ROLES = ['admin', 'empleado']

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem(STORAGE_KEYS.token) || null)
  const usuario = ref(JSON.parse(localStorage.getItem(STORAGE_KEYS.usuario) || 'null'))

  const isAuthenticated = computed(() => !!token.value)
  const rol = computed(() => usuario.value?.rol || null)
  const isStaff = computed(() => STAFF_ROLES.includes(rol.value))
  const isCliente = computed(() => rol.value === 'cliente')

  function setSession(accessToken, user) {
    token.value = accessToken
    usuario.value = user
    localStorage.setItem(STORAGE_KEYS.token, accessToken)
    localStorage.setItem(STORAGE_KEYS.usuario, JSON.stringify(user))
  }

  function clearSession() {
    token.value = null
    usuario.value = null
    localStorage.removeItem(STORAGE_KEYS.token)
    localStorage.removeItem(STORAGE_KEYS.usuario)
  }

  async function login(username, password) {
    const { access_token, usuario: user } = await loginRequest(username, password)
    setSession(access_token, user)
    return user
  }

  async function registrar(payload) {
    const { access_token, usuario: user } = await registroCliente(payload)
    setSession(access_token, user)
    return user
  }

  function logout() {
    clearSession()
  }

  return {
    token,
    usuario,
    isAuthenticated,
    rol,
    isStaff,
    isCliente,
    login,
    registrar,
    logout,
    clearSession,
  }
})
