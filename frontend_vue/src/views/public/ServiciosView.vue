<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

import { listarServiciosPublicos } from '@/api/publico'
import { apiErrorMessage } from '@/api/client'
import BaseSkeleton from '@/components/BaseSkeleton.vue'

const servicios = ref([])
const loading = ref(true)
const error = ref('')
let pollTimer = null

function imageUrl(value) {
  if (!value) return ''
  const src = String(value).trim()
  if (!src) return ''
  if (/^(https?:|data:|blob:|\/)/i.test(src)) return src
  return `/${src.replace(/^\/+/, '')}`
}

async function loadServicios() {
  try {
    const data = await listarServiciosPublicos()
    servicios.value = Array.isArray(data) ? data : data?.data || []
    error.value = ''
  } catch (err) {
    error.value = apiErrorMessage(err, 'No se pudieron cargar los servicios')
  }
}

onMounted(async () => {
  await loadServicios()
  loading.value = false
  pollTimer = window.setInterval(loadServicios, 8000)
})

onBeforeUnmount(() => {
  if (pollTimer) window.clearInterval(pollTimer)
})
</script>

<template>
  <section>
    <h1>Servicios</h1>

    <p v-if="error" class="error">{{ error }}</p>

    <!-- Skeletons durante carga -->
    <ul v-if="loading" class="lista">
      <li v-for="n in 4" :key="n" class="card">
        <BaseSkeleton width="55%" height="1.1rem" />
        <BaseSkeleton width="80%" height="0.85rem" />
        <BaseSkeleton width="30%" height="1rem" />
      </li>
    </ul>

    <ul v-else class="lista">
      <li v-for="s in servicios" :key="s.id_servicio" class="card">
        <img v-if="imageUrl(s.imagen)" class="card__img" :src="imageUrl(s.imagen)" :alt="s.nombre" />
        <strong>{{ s.nombre }}</strong>
        <span class="card__desc">{{ s.descripcion }}</span>
        <span class="card__precio">${{ s.precio }} · {{ s.duracion }} min</span>
      </li>
    </ul>
  </section>
</template>

<style scoped>
.lista {
  list-style: none;
  padding: 0;
  margin: 16px 0 0;
  display: grid;
  gap: 12px;
}
.card {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 14px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}
.card__img {
  width: 100%;
  aspect-ratio: 16 / 9;
  object-fit: cover;
  border-radius: 10px;
  background: #f1f5f9;
}
.card__desc {
  color: #64748b;
  font-size: 0.875rem;
}
.card__precio {
  color: #2563eb;
  font-weight: 600;
}
.error {
  color: #dc2626;
}
</style>
