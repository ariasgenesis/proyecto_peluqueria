import { createRouter, createWebHistory } from 'vue-router'

import { useAuthStore } from '@/stores/auth'

const routes = [
  // ---------- Área pública (cliente, mobile-first) ----------
  {
    path: '/',
    component: () => import('@/layouts/PublicLayout.vue'),
    children: [
      { path: '', name: 'home', component: () => import('@/views/public/HomeView.vue'), meta: { hideShellHeader: true } },
      { path: 'servicios', name: 'servicios', component: () => import('@/views/public/ServiciosView.vue') },
      { path: 'reservar', name: 'reservar', component: () => import('@/views/public/ReservarView.vue'), meta: { hideShellHeader: true } },
      { path: 'login', name: 'login', component: () => import('@/views/public/LoginView.vue'), meta: { guestOnly: true, hideShellHeader: true } },
      { path: 'registro', name: 'registro', component: () => import('@/views/public/RegistroView.vue'), meta: { guestOnly: true } },
      {
        path: 'mi-cuenta',
        name: 'mi-cuenta',
        component: () => import('@/views/public/MiCuentaView.vue'),
        meta: { requiresAuth: true, roles: ['cliente'] },
      },
      {
        path: 'pagar',
        name: 'pagar',
        component: () => import('@/views/public/PagoView.vue'),
        meta: { requiresAuth: true, roles: ['cliente'], hideShellHeader: true },
      },
    ],
  },

  // ---------- Área admin (staff) ----------
  {
    path: '/admin',
    component: () => import('@/layouts/AdminLayout.vue'),
    meta: { requiresAuth: true, roles: ['admin', 'empleado'] },
    children: [
      { path: '', name: 'admin-dashboard', component: () => import('@/views/admin/DashboardView.vue') },
      { path: 'citas', name: 'admin-citas', component: () => import('@/views/admin/CitasView.vue') },
      { path: 'clientes', name: 'admin-clientes', component: () => import('@/views/admin/ClientesView.vue') },
      { path: 'servicios', name: 'admin-servicios', component: () => import('@/views/admin/ServiciosView.vue') },
      { path: 'empleados',   name: 'admin-empleados',   component: () => import('@/views/admin/EmpleadosView.vue') },
      { path: 'inventario',  name: 'admin-inventario',  component: () => import('@/views/admin/InventarioView.vue') },
      { path: 'facturacion', name: 'admin-facturacion', component: () => import('@/views/admin/FacturacionView.vue') },
      { path: 'movimientos', name: 'admin-movimientos', component: () => import('@/views/admin/MovimientosView.vue') },
      { path: 'reservas', name: 'admin-reservas', component: () => import('@/views/admin/ReservasWebView.vue') },
      { path: 'auditoria', name: 'admin-auditoria', component: () => import('@/views/admin/AuditoriaView.vue'), meta: { requiresAuth: true, roles: ['admin'] } },
    ],
  },

  { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Guard: auth + autorización por rol. Redirige según área.
router.beforeEach((to) => {
  const auth = useAuthStore()
  const roles = to.meta.roles

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (roles && auth.isAuthenticated && !roles.includes(auth.rol)) {
    // Autenticado pero sin rol para esta área -> a su home natural.
    return auth.isStaff ? { name: 'admin-dashboard' } : { name: 'mi-cuenta' }
  }

  if (to.meta.guestOnly && auth.isAuthenticated) {
    return auth.isStaff ? { name: 'admin-dashboard' } : { name: 'mi-cuenta' }
  }

  return true
})

export default router
