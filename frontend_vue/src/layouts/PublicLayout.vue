<script setup>
import { RouterLink, RouterView, useRoute } from 'vue-router'

import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import LoginModal from '@/components/LoginModal.vue'

const auth = useAuthStore()
const ui = useUiStore()
const route = useRoute()
</script>

<template>
  <div class="shell">
    <header v-if="!route.meta.hideShellHeader" class="shell__header">
      <RouterLink to="/" class="shell__brand">Beutycore</RouterLink>
      <RouterLink v-if="auth.isCliente" to="/mi-cuenta" class="shell__link">Mi cuenta</RouterLink>
      <button v-else class="shell__link shell__link--btn" @click="ui.openLogin()">Ingresar</button>
    </header>

    <RouterView />
    <LoginModal />
  </div>
</template>

<style scoped>
.shell {
  position: relative;
  width: 100%;
  max-width: 480px;
  min-height: 100vh;
  margin: 0 auto;
  background: var(--bg);
  overflow-x: hidden;
}
@media (min-width: 768px) {
  .shell {
    max-width: 720px;
  }
}
@media (min-width: 1100px) {
  .shell {
    max-width: 1440px;
  }
}
.shell__header {
  position: sticky;
  top: 0;
  z-index: 20;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px 13px;
  background: rgba(251, 246, 244, 0.72);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
}
.shell__brand {
  font-family: var(--serif);
  font-size: 22px;
  font-weight: 500;
  letter-spacing: -0.01em;
  color: var(--ink);
  text-decoration: none;
}
.shell__link {
  font-size: 13px;
  font-weight: 500;
  color: var(--rose);
  text-decoration: none;
}
.shell__link--btn {
  border: none;
  background: none;
  cursor: pointer;
  padding: 0;
  font-family: var(--sans);
}
</style>
