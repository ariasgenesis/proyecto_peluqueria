<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { getDashboardAdmin, getDashboardAlertas, fmtCOP } from '@/api/admin'

const loading    = ref(true)
const loadingAlt = ref(true)
const error      = ref('')
const metricas   = ref({})
const citasHoy   = ref([])
const stockBajo  = ref([])
const retrasadas = ref([])

const hoy = (() => {
  const d = new Date()
  const dias  = ['dom','lun','mar','mié','jue','vie','sáb']
  const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic']
  return `${dias[d.getDay()]} ${d.getDate()} ${meses[d.getMonth()]}`
})()

onMounted(async () => {
  // Llamadas independientes: si alertas falla, el resumen principal sigue visible
  getDashboardAdmin()
    .then(resumen => {
      metricas.value = resumen.metricas  || {}
      citasHoy.value = resumen.citas_hoy || []
    })
    .catch(e => { error.value = e?.response?.data?.message || 'Error al cargar métricas' })
    .finally(() => { loading.value = false })

  getDashboardAlertas()
    .then(alertas => {
      stockBajo.value  = alertas.productos_stock_bajo || []
      retrasadas.value = alertas.citas_retrasadas     || []
    })
    .catch(() => {})
    .finally(() => { loadingAlt.value = false })
})

const stats = computed(() => [
  {
    label: 'Citas hoy',        icon: 'cal',      accent: '#B0455F',
    value: metricas.value.citas_hoy ?? '—',
    sub: `${metricas.value.citas_pendientes ?? 0} pendientes`,
  },
  {
    label: 'Ingresos del día', icon: 'money',    accent: '#16a34a',
    value: fmtCOP(metricas.value.ingresos_hoy),
    sub: 'facturas pagadas hoy',
  },
  {
    label: 'Clientes',         icon: 'scissors', accent: '#d97706',
    value: metricas.value.clientes_total ?? '—',
    sub: `${metricas.value.servicios_activos ?? 0} servicios activos`,
  },
  {
    label: 'Stock bajo',       icon: 'receipt',  accent: '#7c3aed',
    value: metricas.value.stock_bajo ?? '—',
    sub: 'productos por reponer',
  },
])

const alertasList = computed(() => {
  const list = []
  if (stockBajo.value.length)
    list.push({ tipo: 'stock', color: '#B0455F', bg: 'rgba(176,69,95,.10)', texto: `Stock bajo en ${stockBajo.value.length} producto(s)`, sub: stockBajo.value.slice(0,2).map(p => p.nombre).join(' · ') })
  if (retrasadas.value.length)
    list.push({ tipo: 'retraso', color: '#d97706', bg: 'rgba(217,119,6,.12)', texto: `${retrasadas.value.length} cita(s) retrasada(s)`, sub: retrasadas.value[0]?.cliente || '' })
  if (!list.length)
    list.push({ tipo: 'ok', color: '#16a34a', bg: 'rgba(22,163,74,.12)', texto: 'Sin alertas activas', sub: 'Todo en orden' })
  return list
})

const initials = (nombre, apellido) =>
  ((nombre?.[0] || '') + (apellido?.[0] || '')).toUpperCase() || '?'

const badgeStyle = (estado) => {
  if (estado === 'en_curso') return { bg: 'rgba(217,119,6,.12)', color: '#b06407', label: 'En curso' }
  return { bg: 'rgba(176,69,95,.10)', color: '#B0455F', label: 'Confirmada' }
}
</script>

<template>
  <div class="dash">

    <!-- TOPBAR -->
    <div class="topbar">
      <div class="topbar__left">
        <h1 class="topbar__title">Dashboard</h1>
        <span class="topbar__date">{{ hoy }}</span>
      </div>
      <RouterLink to="/admin/citas" class="topbar__btn">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>
        Ver citas
      </RouterLink>
    </div>

    <!-- STATS -->
    <div v-if="error" class="dash-error">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>
      {{ error }}
    </div>
    <div class="stats">
      <!-- skeletons mientras carga -->
      <template v-if="loading">
        <div v-for="k in 4" :key="k" class="stat">
          <div class="shimmer" style="width:42px;height:42px;border-radius:12px;flex:none"></div>
          <div style="flex:1">
            <div class="shimmer sk-line" style="width:50%;height:18px;margin-bottom:6px"></div>
            <div class="shimmer sk-line" style="width:70%;height:12px;margin-bottom:4px"></div>
            <div class="shimmer sk-line" style="width:40%;height:10px"></div>
          </div>
        </div>
      </template>
      <template v-else>
        <div v-for="s in stats" :key="s.label" class="stat">
          <div class="stat__ico" :style="{ background: s.accent + '18' }">
            <svg v-if="s.icon === 'cal'" width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="s.accent" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>
            <svg v-else-if="s.icon === 'money'" width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="s.accent" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="13" rx="2"/><path d="M16 7V5a2 2 0 0 0-4 0v2M12 12v3M10 14h4"/></svg>
            <svg v-else-if="s.icon === 'scissors'" width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="s.accent" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M20 4 8.12 15.88M14.8 14.8 20 20M8.12 8.12 12 12"/></svg>
            <svg v-else-if="s.icon === 'receipt'" width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="s.accent" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M5 3v18l2.5-1.5L10 21l2-1.5L14 21l2.5-1.5L19 21V3l-2.5 1.5L14 3l-2 1.5L10 3 7.5 4.5z"/><path d="M9 8h6M9 12h6"/></svg>
          </div>
          <div class="stat__body">
            <div class="stat__val">{{ s.value }}</div>
            <div class="stat__lbl">{{ s.label }}</div>
            <div class="stat__sub">{{ s.sub }}</div>
          </div>
        </div>
      </template>
    </div>

    <div class="grid">

      <!-- PRÓXIMAS CITAS -->
      <div class="panel">
        <div class="panel__head">
          <div class="panel__title">Citas de hoy</div>
          <RouterLink to="/admin/citas" class="panel__link">Ver tablero →</RouterLink>
        </div>
        <div v-if="loading" class="cita-list">
          <div v-for="k in 4" :key="k" class="cita-row">
            <div class="shimmer sk-av"></div>
            <div style="flex:1"><div class="shimmer sk-line" style="width:60%;height:13px"></div><div class="shimmer sk-line" style="width:40%;height:11px;margin-top:5px"></div></div>
            <div class="shimmer sk-line" style="width:36px;height:13px"></div>
          </div>
        </div>
        <div v-else class="cita-list">
          <p v-if="!citasHoy.length" style="font-size:13px;color:#a59a8d;text-align:center;padding:20px 0">Sin citas hoy</p>
          <div v-for="c in citasHoy" :key="c.id_cita" class="cita-row">
            <div class="cita-row__avatar">{{ initials(c.cliente_nombre, c.cliente_apellido) }}</div>
            <div class="cita-row__info">
              <div class="cita-row__name">{{ c.cliente_nombre }} {{ c.cliente_apellido }}</div>
              <div class="cita-row__meta">{{ c.empleado_nombre }} {{ c.empleado_apellido }}</div>
            </div>
            <div class="cita-row__right">
              <div class="cita-row__time">{{ (c.hora || '').slice(0,5) }}</div>
              <span class="badge" :style="{ background: badgeStyle(c.estado).bg, color: badgeStyle(c.estado).color }">{{ badgeStyle(c.estado).label }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- ALERTAS -->
      <div class="panel">
        <div class="panel__head">
          <div class="panel__title">Alertas</div>
        </div>
        <div class="alert-list">
          <div v-for="a in alertasList" :key="a.tipo" class="alert-row">
            <span class="alert-row__dot" :style="{ background: a.color }"></span>
            <div class="alert-row__body">
              <div class="alert-row__txt">{{ a.texto }}</div>
              <div class="alert-row__sub">{{ a.sub }}</div>
            </div>
            <span class="alert-row__chip" :style="{ background: a.bg, color: a.color }">
              {{ a.tipo === 'stock' ? 'Stock' : a.tipo === 'retraso' ? 'Citas' : 'Pago' }}
            </span>
          </div>
        </div>

        <!-- accesos rápidos -->
        <div class="panel__head" style="margin-top: 24px; padding-top: 18px; border-top: 1px solid rgba(26,23,20,.07)">
          <div class="panel__title">Accesos rápidos</div>
        </div>
        <div class="quick-grid">
          <RouterLink to="/admin/clientes" class="quick-btn">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0M16 6.2a3 3 0 0 1 0 5.6M21 20a5 5 0 0 0-3.5-4.8"/></svg>
            Clientes
          </RouterLink>
          <RouterLink to="/admin/inventario" class="quick-btn">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="M3 8l9 5 9-5M12 13v8"/></svg>
            Inventario
          </RouterLink>
          <RouterLink to="/admin/facturacion" class="quick-btn">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M5 3v18l2.5-1.5L10 21l2-1.5L14 21l2.5-1.5L19 21V3l-2.5 1.5L14 3l-2 1.5L10 3 7.5 4.5z"/><path d="M9 8h6M9 12h6"/></svg>
            Facturación
          </RouterLink>
          <RouterLink to="/admin/movimientos" class="quick-btn">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M7 4 3 8l4 4M3 8h14M17 20l4-4-4-4M21 16H7"/></svg>
            Movimientos
          </RouterLink>
        </div>
      </div>

    </div>
  </div>
</template>

<style scoped>
.dash-error {
  display: flex; align-items: center; gap: 8px;
  margin: 0 20px 12px; padding: 11px 14px; border-radius: 11px;
  background: #fee2e2; color: #991b1b; font-size: 13px; font-weight: 500;
}

.dash {
  flex: 1;
  display: flex;
  flex-direction: column;
  font-family: Inter, system-ui, sans-serif;
  background: #FBF6F4;
  min-height: 100vh;
}

/* topbar */
.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 22px 20px 16px;
}
.topbar__left { display: flex; align-items: baseline; gap: 12px; }
.topbar__title {
  margin: 0;
  font-family: Fraunces, Georgia, serif;
  font-size: 22px;
  font-weight: 500;
  color: #1A1714;
  letter-spacing: -.01em;
}
.topbar__date { font-size: 13px; color: #8a7f72; }
.topbar__btn {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  height: 38px;
  padding: 0 16px;
  border-radius: 11px;
  background: #B0455F;
  color: #FBF6F4;
  text-decoration: none;
  font-size: 13px;
  font-weight: 500;
  transition: filter .2s;
}
.topbar__btn:hover { filter: brightness(1.08); }

/* stats */
.stats {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  padding: 0 20px 16px;
}
.stat {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  padding: 16px;
  background: #fff;
  border-radius: 16px;
  border: 1px solid rgba(26,23,20,.08);
}
.stat__ico {
  flex: none;
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.stat__val {
  font-family: Fraunces, Georgia, serif;
  font-size: 22px;
  font-weight: 600;
  color: #1A1714;
  letter-spacing: -.01em;
  line-height: 1;
}
.stat__lbl {
  font-size: 12px;
  font-weight: 600;
  color: #1A1714;
  margin-top: 4px;
}
.stat__sub {
  font-size: 11px;
  color: #a59a8d;
  margin-top: 2px;
  line-height: 1.35;
}

/* grid dos columnas */
.grid {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 0 20px 28px;
}

/* panel */
.panel {
  background: #fff;
  border-radius: 16px;
  border: 1px solid rgba(26,23,20,.08);
  padding: 18px 18px 20px;
}
.panel__head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 16px;
}
.panel__title {
  font-family: Fraunces, Georgia, serif;
  font-size: 16px;
  font-weight: 500;
  color: #1A1714;
}
.panel__link {
  font-size: 12px;
  font-weight: 500;
  color: #B0455F;
  text-decoration: none;
}
.panel__link:hover { text-decoration: underline; }

/* lista citas */
.cita-list { display: flex; flex-direction: column; gap: 0; }
.cita-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 0;
  border-bottom: 1px solid rgba(26,23,20,.06);
}
.cita-row:last-child { border-bottom: none; }
.cita-row--delay .cita-row__name { color: #c0392b; }
.cita-row__avatar {
  flex: none;
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: #F1E5E3;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 600;
  color: #7a3a4f;
}
.cita-row__info { flex: 1; min-width: 0; }
.cita-row__name {
  font-size: 13.5px;
  font-weight: 500;
  color: #1A1714;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.cita-row__meta { font-size: 11.5px; color: #a59a8d; margin-top: 1px; }
.cita-row__right { flex: none; text-align: right; }
.cita-row__time {
  font-size: 13px;
  font-weight: 600;
  color: #1A1714;
  font-variant-numeric: tabular-nums;
}
.badge {
  display: inline-block;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 20px;
  margin-top: 4px;
}

/* alertas */
.alert-list { display: flex; flex-direction: column; gap: 12px; }
.alert-row {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}
.alert-row__dot {
  flex: none;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-top: 4px;
}
.alert-row__body { flex: 1; min-width: 0; }
.alert-row__txt { font-size: 13px; font-weight: 500; color: #1A1714; }
.alert-row__sub { font-size: 11.5px; color: #a59a8d; margin-top: 1px; }
.alert-row__chip {
  flex: none;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 9px;
  border-radius: 20px;
}

/* accesos rápidos */
.quick-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}
.quick-btn {
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 12px 14px;
  border-radius: 12px;
  background: #FBF6F4;
  border: 1px solid rgba(26,23,20,.09);
  color: #1A1714;
  text-decoration: none;
  font-size: 13px;
  font-weight: 500;
  transition: background .15s;
}
.quick-btn:hover { background: #f1e8ea; color: #B0455F; }

/* skeleton */
.sk-av { flex:none;width:34px;height:34px;border-radius:50%; }
.sk-line { border-radius:5px; }
@keyframes shimmer { from { background-position: -200% 0; } to { background-position: 200% 0; } }
.shimmer {
  background: linear-gradient(90deg, #f0ece8 25%, #e8e3de 50%, #f0ece8 75%);
  background-size: 200% 100%;
  animation: shimmer 1.4s infinite;
}

/* ===== DESKTOP ===== */
@media (min-width: 1024px) {
  .topbar { padding: 24px 28px 20px; }
  .topbar__title { font-size: 26px; }
  .stats {
    grid-template-columns: repeat(4, 1fr);
    padding: 0 28px 20px;
    gap: 16px;
  }
  .grid {
    flex-direction: row;
    align-items: flex-start;
    padding: 0 28px 32px;
    gap: 20px;
  }
  .grid > .panel:first-child { flex: 1.1; }
  .grid > .panel:last-child  { flex: 0.9; }
}
</style>
