<script setup>
// Loader reutilizable. Uso: <BaseLoader v-if="loading" label="Cargando…" />
defineProps({
  label: { type: String, default: '' },
  size: { type: Number, default: 28 },
})
</script>

<template>
  <div class="loader" role="status" aria-live="polite">
    <span class="loader__spinner" :style="{ width: size + 'px', height: size + 'px' }" />
    <span v-if="label" class="loader__label">{{ label }}</span>
  </div>
</template>

<style scoped>
.loader {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  color: #64748b;
  font-size: 0.875rem;
}
.loader__spinner {
  display: inline-block;
  border: 3px solid #e2e8f0;
  border-top-color: #2563eb;
  border-radius: 50%;
  animation: loader-spin 0.7s linear infinite;
}
@keyframes loader-spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
