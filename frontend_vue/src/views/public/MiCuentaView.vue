<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { getHistorial } from '@/api/cliente'

const router = useRouter()
const auth   = useAuthStore()

const loading  = ref(true)
const error    = ref('')
const citas    = ref([])
const facturas = ref([])
const reservas = ref([])
const tab      = ref('reservas')

const fmt     = (n) => '$' + Number(n).toLocaleString('es-CO')
const fmtDate = (s) => {
  if (!s) return '—'
  const [y, m, d] = s.split('-')
  const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic']
  return `${parseInt(d)} ${meses[parseInt(m) - 1]} ${y}`
}
const fmtHora = (s) => (s || '').slice(0, 5)

onMounted(async () => {
  try {
    const data  = await getHistorial()
    citas.value    = data.citas    || []
    facturas.value = data.facturas || []
    reservas.value = data.reservas || []
  } catch {
    error.value = 'No se pudo cargar tu información.'
  } finally {
    loading.value = false
  }
})

const proximaCita = computed(() => {
  const hoy = new Date().toISOString().slice(0, 10)
  return (
    citas.value.find(c => c.fecha >= hoy && c.estado !== 'cancelada') ||
    reservas.value.find(r => r.fecha >= hoy && r.estado !== 'cancelada') ||
    null
  )
})

const ESTADO_CITA = {
  pendiente:  { label: 'Pendiente',  color: '#92400e', bg: '#fef3c7' },
  confirmada: { label: 'Confirmada', color: '#065f46', bg: '#d1fae5' },
  cancelada:  { label: 'Cancelada',  color: '#991b1b', bg: '#fee2e2' },
  completada: { label: 'Completada', color: '#4b5563', bg: '#f3f4f6' },
}
const ESTADO_FAC = {
  pendiente: { label: 'Pendiente', color: '#92400e', bg: '#fef3c7' },
  parcial:   { label: 'Parcial',   color: '#1e40af', bg: '#dbeafe' },
  pagada:    { label: 'Pagada',    color: '#065f46', bg: '#d1fae5' },
  cancelada: { label: 'Cancelada', color: '#991b1b', bg: '#fee2e2' },
}

function logout() {
  auth.logout()
  router.push('/')
}
</script>

<template>
  <div class="mc">

    <!-- header -->
    <div class="mc__head">
      <div>
        <div class="mc__greeting">Hola, {{ auth.usuario?.username }} 👋</div>
        <div class="mc__sub">Tu espacio en Beutycore</div>
      </div>
      <button class="mc__logout" @click="logout">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/></svg>
        Salir
      </button>
    </div>

    <!-- loading -->
    <div v-if="loading" class="mc__loading">
      <div class="mc__spinner"></div>
    </div>

    <template v-else-if="!error">

      <!-- próxima cita highlight -->
      <div v-if="proximaCita" class="mc__next">
        <div class="mc__next-label">Próxima cita</div>
        <div class="mc__next-date">{{ fmtDate(proximaCita.fecha) }} · {{ fmtHora(proximaCita.hora) }}</div>
        <div class="mc__next-svc">{{ proximaCita.servicio || 'Servicio no especificado' }}</div>
        <div class="mc__next-emp">Con {{ proximaCita.empleado || 'estilista asignada' }}</div>
        <RouterLink class="mc__next-btn" to="/reservar">+ Nueva reserva</RouterLink>
      </div>

      <div v-else class="mc__empty-next">
        <span>No tienes citas próximas.</span>
        <RouterLink class="mc__reservar" to="/reservar">Reservar ahora</RouterLink>
      </div>

      <!-- stats row -->
      <div class="mc__stats">
        <div class="mc__stat">
          <span class="mc__stat-n">{{ citas.length }}</span>
          <span class="mc__stat-lbl">Citas</span>
        </div>
        <div class="mc__stat">
          <span class="mc__stat-n">{{ facturas.filter(f => f.estado === 'pagada').length }}</span>
          <span class="mc__stat-lbl">Pagadas</span>
        </div>
        <div class="mc__stat">
          <span class="mc__stat-n">{{ fmt(facturas.filter(f=>f.estado==='pagada').reduce((a,f)=>a+f.total,0)) }}</span>
          <span class="mc__stat-lbl">Total invertido</span>
        </div>
      </div>

      <!-- tabs -->
      <div class="mc__tabs">
        <button class="mc__tab" :class="{ 'mc__tab--on': tab === 'reservas' }" @click="tab = 'reservas'">
          Reservas <span class="mc__badge">{{ reservas.length }}</span>
        </button>
        <button class="mc__tab" :class="{ 'mc__tab--on': tab === 'citas' }" @click="tab = 'citas'">
          Citas <span class="mc__badge">{{ citas.length }}</span>
        </button>
        <button class="mc__tab" :class="{ 'mc__tab--on': tab === 'facturas' }" @click="tab = 'facturas'">
          Facturas <span class="mc__badge">{{ facturas.length }}</span>
        </button>
      </div>

      <!-- reservas web -->
      <div v-if="tab === 'reservas'" class="mc__list fade">
        <div v-if="!reservas.length" class="mc__none">No tienes reservas aún. <RouterLink class="mc__reservar" to="/reservar">Reservar</RouterLink></div>
        <div v-for="r in reservas" :key="r.id_reserva" class="mc__card">
          <div class="mc__card-top">
            <div>
              <div class="mc__card-title">{{ r.servicio || 'Reserva web' }}</div>
              <div class="mc__card-meta">{{ fmtDate(r.fecha) }} · {{ fmtHora(r.hora) }}</div>
              <div class="mc__card-meta">Con {{ r.empleado || 'estilista asignada' }}</div>
              <div class="mc__card-meta">Anticipo: <strong>{{ fmt(r.anticipo) }}</strong></div>
            </div>
            <span class="mc__chip"
              :style="{ color: ESTADO_CITA[r.estado]?.color || '#4b5563', background: ESTADO_CITA[r.estado]?.bg || '#f3f4f6' }">
              {{ r.estado === 'pendiente' ? 'Pago pendiente' : r.estado === 'pagada' ? 'Confirmada' : 'Cancelada' }}
            </span>
          </div>
        </div>
      </div>

      <!-- citas -->
      <div v-else-if="tab === 'citas'" class="mc__list fade">
        <div v-if="!citas.length" class="mc__none">Aún no tienes citas registradas.</div>
        <div v-for="c in citas" :key="c.id_cita" class="mc__card">
          <div class="mc__card-top">
            <div>
              <div class="mc__card-title">{{ c.servicio || 'Servicio' }}</div>
              <div class="mc__card-meta">{{ fmtDate(c.fecha) }} · {{ fmtHora(c.hora) }}</div>
              <div class="mc__card-meta">Con {{ c.empleado || '—' }}</div>
            </div>
            <span class="mc__chip"
              :style="{ color: ESTADO_CITA[c.estado]?.color, background: ESTADO_CITA[c.estado]?.bg }">
              {{ ESTADO_CITA[c.estado]?.label || c.estado }}
            </span>
          </div>
        </div>
      </div>

      <!-- facturas -->
      <div v-else-if="tab === 'facturas'" class="mc__list fade">
        <div v-if="!facturas.length" class="mc__none">No tienes facturas aún.</div>
        <div v-for="f in facturas" :key="f.id_factura" class="mc__card">
          <div class="mc__card-top">
            <div>
              <div class="mc__card-title">
                Factura #{{ f.id_factura }}
                <span class="mc__tipo">{{ f.tipo }}</span>
              </div>
              <div class="mc__card-meta">{{ fmtDate(f.fecha) }}</div>
              <div class="mc__card-meta">Total: <strong>{{ fmt(f.total) }}</strong>
                <template v-if="f.saldo_pendiente > 0"> · Saldo: {{ fmt(f.saldo_pendiente) }}</template>
              </div>
            </div>
            <span class="mc__chip"
              :style="{ color: ESTADO_FAC[f.estado]?.color, background: ESTADO_FAC[f.estado]?.bg }">
              {{ ESTADO_FAC[f.estado]?.label || f.estado }}
            </span>
          </div>
        </div>
      </div>

    </template>

    <div v-else class="mc__error">{{ error }}</div>

  </div>
</template>

<style scoped>
@keyframes fadein { from { opacity: 0; transform: translateY(5px); } to { opacity: 1; transform: none; } }
.fade { animation: fadein .25s ease both; }

.mc { max-width: 480px; margin: 0 auto; padding: 0 0 80px; min-height: 100vh; }

/* header */
.mc__head { display: flex; align-items: flex-start; justify-content: space-between; padding: 28px 22px 18px; }
.mc__greeting { font-family: var(--serif); font-size: 22px; font-weight: 500; color: var(--ink); }
.mc__sub { font-size: 12px; color: var(--muted); margin-top: 3px; }
.mc__logout { display: flex; align-items: center; gap: 6px; padding: 7px 13px; border: 1px solid rgba(26,23,20,.14); border-radius: 20px; background: #fff; font-size: 12.5px; color: var(--muted); cursor: pointer; }
.mc__logout:hover { border-color: var(--rose); color: var(--rose); }

/* loading */
.mc__loading { display: flex; justify-content: center; padding: 60px 0; }
.mc__spinner { width: 36px; height: 36px; border-radius: 50%; border: 3px solid rgba(176,69,95,.15); border-top-color: #B0455F; animation: spin .8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.mc__error { padding: 40px 22px; font-size: 14px; color: #dc2626; text-align: center; }

/* próxima cita */
.mc__next { margin: 0 16px 16px; padding: 20px; border-radius: 20px; background: linear-gradient(135deg, #B0455F, #8E2F47); color: #FBF6F4; position: relative; overflow: hidden; }
.mc__next::after { content: ''; position: absolute; right: -20px; top: -20px; width: 110px; height: 110px; border-radius: 50%; background: rgba(255,255,255,.07); }
.mc__next-label { font-size: 11px; text-transform: uppercase; letter-spacing: .06em; opacity: .75; margin-bottom: 6px; }
.mc__next-date  { font-family: var(--serif); font-size: 20px; font-weight: 500; margin-bottom: 4px; }
.mc__next-svc   { font-size: 14px; opacity: .9; }
.mc__next-emp   { font-size: 12px; opacity: .7; margin-top: 2px; }
.mc__next-btn   { display: inline-block; margin-top: 14px; padding: 7px 16px; border-radius: 20px; background: rgba(255,255,255,.18); font-size: 13px; color: #FBF6F4; text-decoration: none; }
.mc__next-btn:hover { background: rgba(255,255,255,.28); }

.mc__empty-next { display: flex; align-items: center; justify-content: space-between; margin: 0 16px 16px; padding: 16px 18px; border-radius: 16px; border: 1.5px dashed rgba(176,69,95,.3); background: #fbeef1; font-size: 13px; color: var(--muted); }
.mc__reservar { font-size: 13px; font-weight: 600; color: var(--rose); text-decoration: none; }

/* stats */
.mc__stats { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; padding: 0 16px 16px; }
.mc__stat { background: #fff; border: 1px solid rgba(26,23,20,.08); border-radius: 16px; padding: 14px 12px; text-align: center; }
.mc__stat-n   { display: block; font-family: var(--serif); font-size: 20px; font-weight: 500; color: var(--ink); }
.mc__stat-lbl { display: block; font-size: 11px; color: var(--muted); margin-top: 2px; }

/* tabs */
.mc__tabs { display: flex; gap: 0; background: rgba(26,23,20,.06); border-radius: 14px; padding: 3px; margin: 0 16px 14px; }
.mc__tab { flex: 1; height: 36px; border: 0; background: transparent; border-radius: 12px; font-size: 13.5px; font-weight: 500; color: var(--muted); cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 6px; transition: all .18s; }
.mc__tab--on { background: #fff; color: var(--ink); box-shadow: 0 1px 4px rgba(26,23,20,.10); }
.mc__badge { font-size: 11px; padding: 1px 6px; border-radius: 20px; background: rgba(176,69,95,.12); color: var(--rose); font-weight: 600; }

/* list */
.mc__list { display: flex; flex-direction: column; gap: 10px; padding: 0 16px; }
.mc__none { font-size: 13px; color: var(--muted); text-align: center; padding: 28px 0; }

/* card */
.mc__card { background: #fff; border-radius: 16px; border: 1px solid rgba(26,23,20,.08); padding: 16px; }
.mc__card-top { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
.mc__card-title { font-family: var(--serif); font-size: 15px; color: var(--ink); display: flex; align-items: center; gap: 7px; flex-wrap: wrap; }
.mc__card-meta  { font-size: 12px; color: var(--muted); margin-top: 4px; }
.mc__tipo { font-size: 11px; padding: 2px 7px; border-radius: 20px; background: rgba(26,23,20,.07); color: var(--muted); font-family: var(--sans, Inter, sans-serif); font-weight: 500; }
.mc__chip { flex: none; font-size: 11px; font-weight: 600; padding: 3px 9px; border-radius: 20px; white-space: nowrap; }

@media (min-width: 900px) {
  .mc { border-left: 1px solid rgba(26,23,20,.07); border-right: 1px solid rgba(26,23,20,.07); }
}
</style>
