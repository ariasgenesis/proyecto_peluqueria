<script setup>
import { ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'

import { useAuthStore } from '@/stores/auth'
import { apiErrorMessage } from '@/api/client'
import BaseLoader from '@/components/BaseLoader.vue'

const auth = useAuthStore()
const router = useRouter()

const form = ref({ nombre: '', apellido:'', documento: '', telefono: '', email: '', username:'', password: '' })
const error = ref('')
const loading = ref(false)

async function onSubmit() {
  error.value = ''
  loading.value = true
  try {
    await auth.registrar({ ...form.value })
    router.replace({ name: 'home' })
  } catch (err) {
    error.value = apiErrorMessage(err, 'No se pudo completar el registro')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <section class="auth">
    <h1>Crear cuenta</h1>
    <form @submit.prevent="onSubmit">
      <label>Nombre<input v-model="form.nombre" type="text" maxlength="50" required /></label>
      <label>Apellido<input v-model="form.apellido" type="text" maxlength="50" required /></label>
      <label>Documento<input v-model="form.documento" type="text" maxlength="20" pattern="[0-9]*" required /></label>
      <label>Teléfono<input v-model="form.telefono" type="tel" /></label>
      <label>Email<input v-model="form.email" type="email" autocomplete="email" required /></label>
      <label>Usuario<input v-model="form.username" type="text" autocomplete="username" required /></label>
      <label>Contraseña<input v-model="form.password" type="password" autocomplete="new-password" required /></label>

      <p v-if="error" class="auth__error">{{ error }}</p>

      <button type="submit" :disabled="loading">
        <BaseLoader v-if="loading" :size="18" />
        <span v-else>Registrarme</span>
      </button>
    </form>
    <p class="auth__alt">¿Ya tienes cuenta? <RouterLink to="/login">Inicia sesión</RouterLink></p>
  </section>
</template>

<style scoped>
.auth {
  max-width: 360px;
  margin: 24px auto;
}
.auth form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.auth label {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 0.875rem;
  color: #334155;
}
.auth input {
  padding: 10px 12px;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 1rem;
}
.auth__error {
  margin: 0;
  color: #dc2626;
  font-size: 0.875rem;
}
.auth button {
  display: flex;
  justify-content: center;
  padding: 11px;
  border: 0;
  border-radius: 8px;
  background: #2563eb;
  color: #fff;
  font-size: 1rem;
  cursor: pointer;
}
.auth__alt {
  margin-top: 16px;
  font-size: 0.875rem;
  text-align: center;
}
</style>
