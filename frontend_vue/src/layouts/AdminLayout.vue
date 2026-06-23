<script setup>
import { RouterLink, RouterView, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const router = useRouter()

function logout() {
  auth.logout()
  router.replace({ path: '/' })
}

const navItems = [
  { label: 'Dashboard', to: '/admin', icon: 'grid' },
  { label: 'Citas', to: '/admin/citas', icon: 'cal' },
  { label: 'Clientes', to: '/admin/clientes', icon: 'users' },
  { label: 'Empleados', to: '/admin/empleados', icon: 'scissors' },
  { label: 'Inventario', to: '/admin/inventario', icon: 'box' },
  { label: 'Facturación', to: '/admin/facturacion', icon: 'receipt' },
  { label: 'Movimientos', to: '/admin/movimientos', icon: 'swap' },
  { label: 'Reservas web', to: '/admin/reservas', icon: 'globe' },
]

const tabItems = [
  { label: 'Inicio', to: '/admin', icon: 'grid' },
  { label: 'Citas', to: '/admin/citas', icon: 'cal' },
  { label: 'Clientes', to: '/admin/clientes', icon: 'users' },
  { label: 'Stock', to: '/admin/inventario', icon: 'box' },
  { label: 'Reservas', to: '/admin/reservas', icon: 'globe' },
]

const initials = (name) => name ? name.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase() : '?'
</script>

<template>
  <div class="shell">

    <!-- SIDEBAR (desktop) -->
    <aside class="sidebar">
      <div class="sidebar__brand">Beutycore</div>

      <nav class="sidebar__nav">
        <RouterLink
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="nav-item"
          active-class="nav-item--on"
          exact-active-class="nav-item--on"
        >
          <!-- grid -->
          <svg v-if="item.icon === 'grid'" class="nav-item__ico" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>
          <!-- cal -->
          <svg v-else-if="item.icon === 'cal'" class="nav-item__ico" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>
          <!-- users -->
          <svg v-else-if="item.icon === 'users'" class="nav-item__ico" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0M16 6.2a3 3 0 0 1 0 5.6M21 20a5 5 0 0 0-3.5-4.8"/></svg>
          <!-- scissors -->
          <svg v-else-if="item.icon === 'scissors'" class="nav-item__ico" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M20 4 8.12 15.88M14.8 14.8 20 20M8.12 8.12 12 12"/></svg>
          <!-- box -->
          <svg v-else-if="item.icon === 'box'" class="nav-item__ico" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="M3 8l9 5 9-5M12 13v8"/></svg>
          <!-- receipt -->
          <svg v-else-if="item.icon === 'receipt'" class="nav-item__ico" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M5 3v18l2.5-1.5L10 21l2-1.5L14 21l2.5-1.5L19 21V3l-2.5 1.5L14 3l-2 1.5L10 3 7.5 4.5z"/><path d="M9 8h6M9 12h6"/></svg>
          <!-- swap -->
          <svg v-else-if="item.icon === 'swap'" class="nav-item__ico" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M7 4 3 8l4 4M3 8h14M17 20l4-4-4-4M21 16H7"/></svg>
          <!-- globe -->
          <svg v-else-if="item.icon === 'globe'" class="nav-item__ico" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 3a14.5 14.5 0 0 1 0 18M12 3a14.5 14.5 0 0 0 0 18M3 12h18"/></svg>
          <span>{{ item.label }}</span>
        </RouterLink>
      </nav>

      <div class="sidebar__user">
        <div class="sidebar__avatar">{{ initials(auth.usuario?.username || 'Admin') }}</div>
        <div class="sidebar__info">
          <div class="sidebar__name">{{ auth.usuario?.username || 'Admin' }}</div>
          <div class="sidebar__role">{{ auth.rol === 'admin' ? 'Administrador' : 'Empleado' }}</div>
        </div>
        <button class="sidebar__logout" @click="logout" title="Cerrar sesión">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/></svg>
        </button>
      </div>
    </aside>

    <!-- MAIN -->
    <div class="main">
      <RouterView />
    </div>

    <!-- BOTTOM TAB BAR (mobile) -->
    <nav class="tabbar">
      <RouterLink
        v-for="t in tabItems"
        :key="t.to"
        :to="t.to"
        class="tab"
        active-class="tab--on"
        exact-active-class="tab--on"
      >
        <svg v-if="t.icon === 'grid'" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>
        <svg v-else-if="t.icon === 'cal'" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>
        <svg v-else-if="t.icon === 'users'" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0M16 6.2a3 3 0 0 1 0 5.6M21 20a5 5 0 0 0-3.5-4.8"/></svg>
        <svg v-else-if="t.icon === 'box'" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="M3 8l9 5 9-5M12 13v8"/></svg>
        <svg v-else-if="t.icon === 'receipt'" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M5 3v18l2.5-1.5L10 21l2-1.5L14 21l2.5-1.5L19 21V3l-2.5 1.5L14 3l-2 1.5L10 3 7.5 4.5z"/><path d="M9 8h6M9 12h6"/></svg>
        <svg v-else-if="t.icon === 'globe'" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 3a14.5 14.5 0 0 1 0 18M12 3a14.5 14.5 0 0 0 0 18M3 12h18"/></svg>
        <span class="tab__lbl">{{ t.label }}</span>
      </RouterLink>
      <button class="tab tab--logout" @click="logout">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/></svg>
        <span class="tab__lbl">Salir</span>
      </button>
    </nav>

  </div>
</template>

<style scoped>
*, *::before, *::after { box-sizing: border-box; }

.shell {
  min-height: 100vh;
  display: flex;
  background: #FBF6F4;
  font-family: Inter, system-ui, sans-serif;
}

/* ===== SIDEBAR ===== */
.sidebar {
  display: none; /* oculto mobile */
}

/* ===== MAIN ===== */
.main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  padding-bottom: 64px; /* espacio bottom tabbar mobile */
}

/* ===== BOTTOM TAB BAR ===== */
.tabbar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 50;
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding: 10px 12px 18px;
  background: #f6ecec;
  border-top: 1px solid rgba(26, 23, 20, .07);
}
.tab {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  text-decoration: none;
  color: #a59a8d;
}
.tab__lbl {
  font-size: 10px;
  font-weight: 500;
}
.tab--on {
  color: #B0455F;
}
.tab--on .tab__lbl {
  font-weight: 600;
}
.tab--logout {
  border: none; background: none; cursor: pointer; padding: 0;
  color: #c0392b;
}
.tab--logout:active { opacity: .7; }

/* ===== DESKTOP ===== */
@media (min-width: 1024px) {
  .main {
    padding-bottom: 0;
  }
  .tabbar {
    display: none;
  }
  .sidebar {
    display: flex;
    flex: none;
    width: 240px;
    background: #f6ecec;
    border-right: 1px solid rgba(26, 23, 20, .06);
    flex-direction: column;
    padding: 26px 18px 20px;
  }
  .sidebar__brand {
    font-family: Fraunces, Georgia, serif;
    font-size: 24px;
    font-weight: 500;
    color: #1A1714;
    letter-spacing: -.01em;
    padding: 0 10px 28px;
  }
  .sidebar__nav {
    display: flex;
    flex-direction: column;
    gap: 3px;
  }
  .nav-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 10px 12px;
    border-radius: 11px;
    text-decoration: none;
    font-size: 13.5px;
    font-weight: 500;
    color: #6b6258;
    transition: background .15s, color .15s;
  }
  .nav-item__ico { flex: none; }
  .nav-item:hover {
    background: rgba(176, 69, 95, .06);
    color: #1A1714;
  }
  .nav-item--on {
    background: rgba(176, 69, 95, .10);
    color: #B0455F;
    font-weight: 600;
  }
  .sidebar__user {
    margin-top: auto;
    display: flex;
    align-items: center;
    gap: 11px;
    padding: 12px 10px 4px;
    border-top: 1px solid rgba(26, 23, 20, .07);
  }
  .sidebar__avatar {
    width: 38px;
    height: 38px;
    border-radius: 50%;
    background: radial-gradient(circle at 35% 30%, #C9A98C, #a8866a);
    flex: none;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    font-weight: 700;
    color: #fff;
  }
  .sidebar__info { flex: 1; min-width: 0; }
  .sidebar__name {
    font-size: 13px;
    font-weight: 600;
    color: #1A1714;
  }
  .sidebar__role {
    display: inline-flex;
    margin-top: 3px;
    font-size: 10px;
    font-weight: 600;
    letter-spacing: .03em;
    padding: 2px 8px;
    border-radius: 20px;
    background: rgba(176, 69, 95, .10);
    color: #B0455F;
  }
  .sidebar__logout {
    flex: none;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 30px;
    height: 30px;
    border-radius: 8px;
    border: 1px solid rgba(26, 23, 20, .10);
    background: transparent;
    color: #8a7f72;
    cursor: pointer;
    transition: background .15s, color .15s;
  }
  .sidebar__logout:hover { background: #fff; color: #B0455F; }
}
</style>
