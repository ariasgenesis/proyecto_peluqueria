<script setup>
// Skeleton de carga reutilizable. Uso:
// <BaseSkeleton v-for="n in 5" :key="n" height="64px" />
// <BaseSkeleton width="60%" height="1rem" rounded />
defineProps({
  width: { type: String, default: '100%' },
  height: { type: String, default: '1rem' },
  rounded: { type: Boolean, default: false },
})
</script>

<template>
  <span
    class="skeleton"
    :class="{ 'skeleton--rounded': rounded }"
    :style="{ width, height }"
    aria-hidden="true"
  />
</template>

<style scoped>
.skeleton {
  display: block;
  border-radius: 8px;
  background: linear-gradient(90deg, #e2e8f0 25%, #f1f5f9 37%, #e2e8f0 63%);
  background-size: 400% 100%;
  animation: skeleton-shimmer 1.3s ease infinite;
}
.skeleton--rounded {
  border-radius: 999px;
}
@keyframes skeleton-shimmer {
  0% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0 50%;
  }
}
</style>
