<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useAlertDialog } from '@/composables/useAlertDialog'
import {
  listarServiciosPublicos,
  listarEmpleadosPublicos,
  consultarSlotsDisponibles,
  crearReservaWeb,
} from '@/api/publico'

const router  = useRouter()
const auth    = useAuthStore()
const { alertDialog } = useAlertDialog()

// ── Wizard state ─────────────────────────────────────────────
const step    = ref(1)
const mode    = ref('wizard') // 'wizard' | 'auth'

// ── API data ─────────────────────────────────────────────────
const serviciosAPI   = ref([])
const empleadosAPI   = ref([])
const slotsAPI       = ref([])   // [{hora, disponible}]
const loadingSvcs    = ref(true)
const loadingEmpls   = ref(false)
const loadingSlots   = ref(false)
let servicePollBusy  = false
let servicePollTimer = null

// ── Servicios pagination ──────────────────────────────────────
const PAGE_SIZE      = 5
const svcExpanded    = ref(false)
const serviciosVisible = computed(() =>
  svcExpanded.value ? serviciosAPI.value : serviciosAPI.value.slice(0, PAGE_SIZE)
)
const hasMore = computed(() => serviciosAPI.value.length > PAGE_SIZE)

// ── Selections ────────────────────────────────────────────────
const selectedIds    = ref(new Set())
const stylistId      = ref(null)   // null = auto
const dateIdx        = ref(0)
const slotHora       = ref(null)

// ── Auth inline ───────────────────────────────────────────────
const authTab        = ref('login')  // 'login' | 'register'
const loginForm      = ref({ username: '', password: '' })
const regForm        = ref({ nombre: '', apellido: '', documento: '', telefono: '', email: '', username: '', password: '' })
const authError      = ref('')
const authLoading    = ref(false)

// ── Payment ───────────────────────────────────────────────────
const paying         = ref(false)
const payError       = ref('')
const success        = ref(false)
const successData    = ref(null)

// ── Formatters ────────────────────────────────────────────────
const fmt = (n) => '$' + Number(n).toLocaleString('es-CO') + ' COP'

// ── Computed ─────────────────────────────────────────────────
const selectedServices = computed(() =>
  serviciosAPI.value.filter(s => selectedIds.value.has(s.id_servicio))
)
const total    = computed(() => selectedServices.value.reduce((a, s) => a + Number(s.precio), 0))
const anticipo = computed(() => Math.round(total.value * 0.3))
const saldo    = computed(() => total.value - anticipo.value)

const dates = computed(() => {
  const result = []
  for (let i = 0; i < 7; i++) {
    const d = new Date()
    d.setDate(d.getDate() + i + 1)
    const dow = d.toLocaleDateString('es-CO', { weekday: 'short' })
    result.push({
      dow: dow.charAt(0).toUpperCase() + dow.slice(1),
      day: d.getDate(),
      str: d.toISOString().slice(0, 10),
    })
  }
  return result
})

const stylistName = computed(() => {
  if (!stylistId.value) return 'Sin preferencia · auto-asignada'
  const e = empleadosAPI.value.find(x => x.id_empleado === stylistId.value)
  return e ? `${e.nombre} ${e.apellido}` : '—'
})

const summaryWhen = computed(() => {
  const d = dates.value[dateIdx.value]
  return d && slotHora.value ? `${d.dow} ${d.day} · ${slotHora.value}` : '—'
})

const canContinue = computed(() => {
  if (step.value === 1) return selectedIds.value.size > 0
  if (step.value === 3) return slotHora.value !== null
  return true
})

const stepName     = computed(() => ['Servicio', 'Estilista', 'Horario', 'Pago'][step.value - 1])
const progressPct  = computed(() => (step.value / 4) * 100 + '%')
const PROGRESS     = ['#8E2F47', '#B0455F', '#C66E84', '#D99AAA']
const progressColor = computed(() => PROGRESS[step.value - 1])
const onPayStep    = computed(() => step.value === 4)
const ctaLabel     = computed(() => onPayStep.value ? 'Pagar anticipo' : 'Continuar')
const barTopLabel  = computed(() => onPayStep.value ? 'Anticipo a pagar' : 'Total estimado')
const barAmount    = computed(() => fmt(onPayStep.value ? anticipo.value : total.value))

// ── Lifecycle ─────────────────────────────────────────────────
onMounted(async () => {
  // Returning from Wompi redirect
  const params = new URLSearchParams(window.location.search)
  if (params.get('exito') === 'true') {
    success.value = true
    successData.value = JSON.parse(sessionStorage.getItem('reserva_exitosa') || 'null')
    sessionStorage.removeItem('reserva_exitosa')
    window.history.replaceState({}, '', '/reservar')
    return
  }
  try {
    await refreshServiciosPublicos()
    if (serviciosAPI.value.length > 0) {
      selectedIds.value = new Set([serviciosAPI.value[0].id_servicio])
    }
    servicePollTimer = window.setInterval(pollServiciosPublicos, 8000)
  } finally {
    loadingSvcs.value = false
  }
})

onBeforeUnmount(() => {
  if (servicePollTimer) window.clearInterval(servicePollTimer)
})

// ── Actions ───────────────────────────────────────────────────
async function refreshServiciosPublicos({ notify = false } = {}) {
  const seleccionadosAntes = selectedServices.value
  const next = await listarServiciosPublicos()
  const activos = new Set(next.map(s => s.id_servicio))
  const removidos = seleccionadosAntes.filter(s => !activos.has(s.id_servicio))

  serviciosAPI.value = next

  if (removidos.length) {
    selectedIds.value = new Set(Array.from(selectedIds.value).filter(id => activos.has(id)))
    slotHora.value = null
    slotsAPI.value = []
    if (step.value > 1) step.value = 1
    if (notify) {
      await alertDialog({
        title: 'Servicio no disponible',
        message: `${removidos.map(s => s.nombre).join(', ')} quedo inactivo por stock bajo o agotado.`,
        variant: 'warning',
      })
    }
  }
}

async function pollServiciosPublicos() {
  if (servicePollBusy) return
  servicePollBusy = true
  try { await refreshServiciosPublicos({ notify: true }) }
  catch (_) {}
  finally { servicePollBusy = false }
}

function toggle(id) {
  const s = new Set(selectedIds.value)
  s.has(id) ? s.delete(id) : s.add(id)
  selectedIds.value = s
}

async function loadEmpleados() {
  if (empleadosAPI.value.length) return
  loadingEmpls.value = true
  try { empleadosAPI.value = await listarEmpleadosPublicos() }
  finally { loadingEmpls.value = false }
}

async function pickDate(i) {
  dateIdx.value = i
  slotHora.value = null
  await fetchSlots()
}

async function fetchSlots() {
  loadingSlots.value = true
  slotsAPI.value = []
  try {
    const servicios = Array.from(selectedIds.value).join(',')
    const params = { servicios, fecha: dates.value[dateIdx.value].str }
    if (stylistId.value) params.empleado_id = stylistId.value
    slotsAPI.value = await consultarSlotsDisponibles(params)
  } finally {
    loadingSlots.value = false
  }
}

function goStep(n) {
  if (n < 1 || n > 4) return
  if (n === 2) loadEmpleados()
  if (n === 3 && slotsAPI.value.length === 0) fetchSlots()
  step.value = n
}
function back() { goStep(step.value - 1) }
async function next() {
  if (step.value === 1) {
    await refreshServiciosPublicos({ notify: true })
  }
  if (!canContinue.value) return
  if (step.value === 4) return handlePay()
  goStep(step.value + 1)
}

// ── Auth inline ───────────────────────────────────────────────
function handlePay() {
  if (!auth.isAuthenticated || !auth.isCliente) {
    mode.value = 'auth'
    return
  }
  createReservation()
}

async function doLogin() {
  authError.value = ''
  authLoading.value = true
  try {
    const user = await auth.login(loginForm.value.username, loginForm.value.password)
    if (user.rol !== 'cliente') {
      auth.logout()
      authError.value = 'Inicia sesión con tu cuenta de cliente para reservar.'
      return
    }
    mode.value = 'wizard'
    await createReservation()
  } catch (e) {
    authError.value = e.response?.data?.message || 'Credenciales incorrectas'
  } finally {
    authLoading.value = false
  }
}

async function doRegister() {
  authError.value = ''
  authLoading.value = true
  try {
    const user = await auth.registrar(regForm.value)
    if (user.rol !== 'cliente') { auth.logout(); authError.value = 'Error al registrar cliente.'; return }
    mode.value = 'wizard'
    await createReservation()
  } catch (e) {
    authError.value = e.response?.data?.message || 'Error al registrarse'
  } finally {
    authLoading.value = false
  }
}

// ── Reservation + Wompi ───────────────────────────────────────
async function createReservation() {
  paying.value = true
  payError.value = ''
  try {
    await refreshServiciosPublicos({ notify: true })
    if (!selectedIds.value.size) {
      payError.value = 'Selecciona un servicio activo para continuar.'
      paying.value = false
      return
    }
    const payload = {
      servicios: Array.from(selectedIds.value),
      fecha: dates.value[dateIdx.value].str,
      hora: slotHora.value,
      anticipo: anticipo.value,
    }
    if (stylistId.value) payload.empleado_id = stylistId.value

    const reserva = await crearReservaWeb(payload)
    const w = reserva.wompi

    sessionStorage.setItem('pago_pendiente', JSON.stringify({
      wompi: w,
      summary: {
        services: selectedServices.value.map(s => ({ id: s.id_servicio, nombre: s.nombre, precio: s.precio })),
        when:     summaryWhen.value,
        stylist:  stylistName.value,
        anticipo: anticipo.value,
        saldo:    saldo.value,
        total:    total.value,
      },
    }))

    router.push('/pagar')
  } catch (e) {
    payError.value = e.response?.data?.message || 'Error al crear la reserva. Intenta de nuevo.'
    paying.value = false
  }
}

function reset() {
  step.value = 1; mode.value = 'wizard'; success.value = false
  slotHora.value = null; payError.value = ''
}
</script>

<template>
  <div class="wiz">

    <!-- ══════════════════════════════ ÉXITO ══════════════════════════════ -->
    <div v-if="success" class="ok">
      <div class="ok__circle">
        <svg width="46" height="46" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path class="ok__check" d="M20 6 9 17l-5-5"/>
        </svg>
      </div>
      <div class="ok__title">¡Cita confirmada!</div>
      <div class="ok__sub">Te esperamos. Recibirás los detalles en tu cuenta.</div>

      <div v-if="successData" class="ok__card">
        <div class="ok__when">{{ successData.when }}</div>
        <div class="card__line">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="9" r="3"/><path d="M12 2a7 7 0 0 0-7 7c0 5 7 13 7 13s7-8 7-13a7 7 0 0 0-7-7z"/></svg>
          <span>{{ successData.stylist }}</span>
        </div>
        <div class="hr"></div>
        <div class="break"><span class="muted sm">Anticipo pagado</span><span class="break__antval sm">{{ fmt(successData.anticipo) }}</span></div>
        <div class="break" style="margin-top:6px"><span class="muted sm">Saldo en Beutycore</span><span class="muted sm">{{ fmt(successData.saldo) }}</span></div>
      </div>

      <button class="ok__btn" @click="router.push('/mi-cuenta')">Ver mi cuenta</button>
    </div>

    <!-- ══════════════════════════════ AUTH MODAL ══════════════════════════════ -->
    <template v-else-if="mode === 'auth'">
      <div class="auth-wrap">
        <button class="auth-back" @click="mode = 'wizard'">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#1A1714" stroke-width="1.9" stroke-linecap="round"><path d="M15 18l-6-6 6-6"/></svg>
          Volver al resumen
        </button>
        <h2 class="auth-title">Para reservar necesitas una cuenta</h2>

        <div class="auth-tabs">
          <button class="auth-tab" :class="{ 'auth-tab--on': authTab === 'login' }" @click="authTab = 'login'">Iniciar sesión</button>
          <button class="auth-tab" :class="{ 'auth-tab--on': authTab === 'register' }" @click="authTab = 'register'">Registrarse</button>
        </div>

        <form class="auth-form" @submit.prevent="authTab === 'login' ? doLogin() : doRegister()">
          <template v-if="authTab === 'login'">
            <div class="auth-group">
              <label class="auth-label">Usuario</label>
              <input class="auth-input" v-model="loginForm.username" autocomplete="username" placeholder="tu_usuario" />
            </div>
            <div class="auth-group">
              <label class="auth-label">Contraseña</label>
              <input class="auth-input" v-model="loginForm.password" type="password" autocomplete="current-password" placeholder="••••••••" />
            </div>
          </template>
          <template v-else>
            <div class="auth-row">
              <div class="auth-group">
                <label class="auth-label">Nombre *</label>
                <input class="auth-input" v-model="regForm.nombre" placeholder="María" />
              </div>
              <div class="auth-group">
                <label class="auth-label">Apellido *</label>
                <input class="auth-input" v-model="regForm.apellido" placeholder="García" />
              </div>
            </div>
            <div class="auth-group">
              <label class="auth-label">Documento *</label>
              <input class="auth-input" v-model="regForm.documento" placeholder="1234567890" />
            </div>
            <div class="auth-group">
              <label class="auth-label">Teléfono</label>
              <input class="auth-input" v-model="regForm.telefono" placeholder="3001234567" />
            </div>
            <div class="auth-group">
              <label class="auth-label">Email *</label>
              <input class="auth-input" v-model="regForm.email" type="email" autocomplete="email" placeholder="maria@email.com" />
            </div>
            <div class="auth-group">
              <label class="auth-label">Usuario *</label>
              <input class="auth-input" v-model="regForm.username" autocomplete="username" placeholder="maria_garcia" />
            </div>
            <div class="auth-group">
              <label class="auth-label">Contraseña *</label>
              <input class="auth-input" v-model="regForm.password" type="password" autocomplete="new-password" placeholder="••••••••" />
            </div>
          </template>

          <p v-if="authError" class="auth-error">{{ authError }}</p>

          <button class="auth-btn" type="submit" :disabled="authLoading">
            <span v-if="authLoading" class="spin"></span>
            <span v-else>{{ authTab === 'login' ? 'Entrar y reservar' : 'Crear cuenta y reservar' }}</span>
          </button>
        </form>
      </div>
    </template>

    <!-- ══════════════════════════════ WIZARD ══════════════════════════════ -->
    <template v-else>
      <!-- progress -->
      <div class="wiz__top">
        <div class="wiz__bar">
          <button v-show="step > 1" class="wiz__back" @click="back">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#1A1714" stroke-width="1.9" stroke-linecap="round"><path d="M15 18l-6-6 6-6"/></svg>
            <span>Atrás</span>
          </button>
          <div class="wiz__stepname">{{ stepName }}</div>
        </div>
        <div class="wiz__track">
          <div class="wiz__fill" :style="{ width: progressPct, background: progressColor }"></div>
        </div>
      </div>

      <!-- content -->
      <div class="scrl wiz__content">

        <!-- PASO 1: Servicios -->
        <div v-if="step === 1" class="fade">
          <h2 class="wiz__title">Elige tus servicios</h2>
          <p class="wiz__sub">Puedes combinar más de uno.</p>

          <div v-if="loadingSvcs" class="col">
            <div v-for="i in 5" :key="i" class="svc shimmer" style="height:72px"></div>
          </div>
          <div v-else class="col">
            <div
              v-for="s in serviciosVisible" :key="s.id_servicio"
              class="svc"
              :style="{ borderColor: selectedIds.has(s.id_servicio) ? '#B0455F' : 'rgba(26,23,20,.1)' }"
              @click="toggle(s.id_servicio)"
            >
              <div class="svc__box" :style="{
                background: selectedIds.has(s.id_servicio) ? '#B0455F' : '#fff',
                borderColor: selectedIds.has(s.id_servicio) ? '#B0455F' : 'rgba(26,23,20,.2)',
              }">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="3" stroke-linecap="round" :style="{ opacity: selectedIds.has(s.id_servicio) ? 1 : 0 }"><path d="M20 6 9 17l-5-5"/></svg>
              </div>
              <div class="svc__info">
                <div class="svc__name">{{ s.nombre }}</div>
                <div class="svc__dur">{{ s.duracion }} min</div>
              </div>
              <div class="svc__price">{{ fmt(s.precio) }}</div>
            </div>

            <button v-if="hasMore && !svcExpanded" class="svc__more" @click="svcExpanded = true">
              Ver más servicios
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 9l6 6 6-6"/></svg>
            </button>
          </div>
        </div>

        <!-- PASO 2: Estilista -->
        <div v-else-if="step === 2" class="fade">
          <h2 class="wiz__title">Elige tu estilista</h2>
          <p class="wiz__sub">O deja que asignemos a la mejor disponible.</p>

          <div class="auto"
            :style="{ background: !stylistId ? '#FBEEF1' : '#fff', borderColor: !stylistId ? '#B0455F' : 'rgba(26,23,20,.1)' }"
            @click="stylistId = null"
          >
            <div class="auto__ico">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.6" stroke-linecap="round"><path d="M12 3l2.2 5.5L20 9l-4 4 1 6-5-3-5 3 1-6-4-4 5.8-.5z"/></svg>
            </div>
            <div class="auto__info">
              <div class="auto__name">Sin preferencia</div>
              <div class="auto__desc">Asignamos automáticamente a la mejor disponible</div>
            </div>
            <div class="radio" :style="{ borderColor: !stylistId ? '#B0455F' : 'rgba(26,23,20,.2)' }">
              <div class="radio__dot" :style="{ opacity: !stylistId ? 1 : 0 }"></div>
            </div>
          </div>

          <div v-if="loadingEmpls" class="grid2">
            <div v-for="i in 4" :key="i" class="stl shimmer" style="height:130px"></div>
          </div>
          <div v-else class="grid2">
            <div
              v-for="e in empleadosAPI" :key="e.id_empleado"
              class="stl"
              :style="{ borderColor: stylistId === e.id_empleado ? '#B0455F' : 'rgba(26,23,20,.1)' }"
              @click="stylistId = e.id_empleado"
            >
              <div class="stl__av">{{ (e.nombre[0] || '') + (e.apellido[0] || '') }}</div>
              <div class="stl__name">{{ e.nombre }} {{ e.apellido }}</div>
              <div class="stl__spec">{{ e.cargo || 'Estilista' }}</div>
            </div>
          </div>
        </div>

        <!-- PASO 3: Fecha + hora -->
        <div v-else-if="step === 3" class="fade">
          <h2 class="wiz__title">Elige fecha y hora</h2>
          <p class="wiz__sub">Disponibilidad en tiempo real.</p>

          <div class="scrl dates">
            <div
              v-for="(d, i) in dates" :key="i"
              class="date"
              :style="{ background: dateIdx === i ? '#B0455F' : '#fff', borderColor: dateIdx === i ? '#B0455F' : 'rgba(26,23,20,.1)' }"
              @click="pickDate(i)"
            >
              <div class="date__dow" :style="{ color: dateIdx === i ? 'rgba(251,246,244,.8)' : '#a59a8d' }">{{ d.dow }}</div>
              <div class="date__day" :style="{ color: dateIdx === i ? '#FBF6F4' : '#1A1714' }">{{ d.day }}</div>
            </div>
          </div>

          <div class="slots__label">Horarios disponibles</div>

          <div v-if="loadingSlots" class="slots">
            <div v-for="k in 10" :key="k" class="slot shimmer"></div>
          </div>
          <div v-else-if="slotsAPI.length" class="slots fade">
            <div
              v-for="t in slotsAPI" :key="t.hora"
              class="slot"
              :class="{ 'slot--taken': !t.disponible }"
              :style="t.disponible ? {
                background: slotHora === t.hora ? '#B0455F' : '#fff',
                borderColor: slotHora === t.hora ? '#B0455F' : 'rgba(26,23,20,.12)',
                color: slotHora === t.hora ? '#FBF6F4' : '#1A1714',
              } : {}"
              @click="t.disponible ? (slotHora = t.hora) : null"
            >{{ t.hora }}</div>
          </div>
          <p v-else class="wiz__sub" style="text-align:center;padding:20px 0">Selecciona una fecha para ver disponibilidad.</p>
        </div>

        <!-- PASO 4: Confirmación -->
        <div v-else-if="step === 4" class="fade">
          <h2 class="wiz__title">Confirma y reserva</h2>
          <p class="wiz__sub">Solo pagas el anticipo ahora.</p>

          <div class="card">
            <div v-for="s in selectedServices" :key="s.id_servicio" class="card__row">
              <div>
                <div class="card__name">{{ s.nombre }}</div>
                <div class="card__dur">{{ s.duracion }} min</div>
              </div>
              <div class="card__price">{{ fmt(s.precio) }}</div>
            </div>
            <div class="hr"></div>
            <div class="card__line">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.6" stroke-linecap="round"><circle cx="12" cy="9" r="3"/><path d="M12 2a7 7 0 0 0-7 7c0 5 7 13 7 13s7-8 7-13a7 7 0 0 0-7-7z"/></svg>
              <span>{{ stylistName }}</span>
            </div>
            <div class="card__line">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.6" stroke-linecap="round"><rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>
              <span>{{ summaryWhen }}</span>
            </div>
          </div>

          <div class="card">
            <div class="break"><span class="muted">Total servicios</span><span class="break__total">{{ fmt(total) }}</span></div>
            <div class="break break--anticipo">
              <span class="break__antlbl">Anticipo a pagar (30%)</span>
              <span class="break__antval">{{ fmt(anticipo) }}</span>
            </div>
            <div class="break"><span class="muted">Saldo en Beutycore</span><span class="muted">{{ fmt(saldo) }}</span></div>
          </div>

          <p v-if="payError" class="pay-error">{{ payError }}</p>

          <div class="wompi">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round"><rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>
            <span>Pago seguro · Cifrado de extremo a extremo</span>
          </div>
        </div>

      </div>

      <!-- resumen sticky (desktop) -->
      <aside class="wiz__aside">
        <div class="wiz__sumcard">
          <div class="wiz__sumttl">Resumen</div>
          <div v-if="selectedServices.length" class="wiz__sumlist">
            <div v-for="s in selectedServices" :key="s.id_servicio" class="wiz__sumrow">
              <span>{{ s.nombre }}</span><span>{{ fmt(s.precio) }}</span>
            </div>
          </div>
          <div v-else class="wiz__sumempty">Selecciona tus servicios…</div>

          <div class="hr"></div>
          <div class="wiz__sumrow"><span class="muted">Total</span><span>{{ fmt(total) }}</span></div>
          <div class="break break--anticipo">
            <span class="break__antlbl">Anticipo (30%)</span>
            <span class="break__antval">{{ fmt(anticipo) }}</span>
          </div>
          <div class="wiz__sumrow muted"><span>Saldo en Beutycore</span><span>{{ fmt(saldo) }}</span></div>

          <button
            class="wiz__sumbtn"
            :style="{ background: canContinue ? '#B0455F' : '#cdbfb4', cursor: canContinue ? 'pointer' : 'not-allowed' }"
            :disabled="paying"
            @click="next"
          >
            <span v-if="paying" class="spin"></span>
            <span v-else>{{ ctaLabel }}</span>
          </button>
          <div class="wiz__sumnote">Solo pagas el anticipo · confirmación inmediata</div>
        </div>
      </aside>

      <!-- barra inferior (mobile) -->
      <div class="wiz__cta">
        <div>
          <div class="wiz__cta-top">{{ barTopLabel }}</div>
          <div class="wiz__cta-amount">{{ barAmount }}</div>
        </div>
        <button
          class="wiz__cta-btn"
          :style="{ background: canContinue ? '#B0455F' : '#cdbfb4', opacity: canContinue ? 1 : 0.7, cursor: canContinue ? 'pointer' : 'not-allowed' }"
          :disabled="paying"
          @click="next"
        >
          <span v-if="paying" class="spin"></span>
          <template v-else>
            <span class="wiz__cta-label">{{ ctaLabel }}</span>
            <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="1.9" stroke-linecap="round"><path d="M5 12h13M13 6l6 6-6 6"/></svg>
          </template>
        </button>
      </div>
    </template>

  </div>
</template>

<style scoped>
.wiz {
  position: relative; display: flex; flex-direction: column;
  min-height: 100vh; width: 100%; max-width: 480px; margin: 0 auto;
}
.fade { animation: fade 0.35s ease both; }
@keyframes fade { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: none; } }
@keyframes spin { to { transform: rotate(360deg); } }
@keyframes pop { 0% { transform: scale(0); opacity: 0; } 60% { transform: scale(1.12); } 100% { transform: scale(1); opacity: 1; } }
@keyframes draw { to { stroke-dashoffset: 0; } }

/* shimmer */
.shimmer { background: linear-gradient(90deg, #f0ebe7 25%, #e8e3df 50%, #f0ebe7 75%); background-size: 200% 100%; animation: shimmer 1.4s infinite; border-radius: 12px; }
@keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }

/* progress */
.wiz__top { flex: none; padding: 20px 24px 16px; }
.wiz__bar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; min-height: 30px; }
.wiz__back { display: flex; align-items: center; gap: 6px; padding: 6px 12px 6px 8px; border: 0; border-radius: 20px; background: rgba(26,23,20,.05); cursor: pointer; font-size: 12px; font-weight: 500; color: var(--ink); }
.wiz__stepname { font-family: var(--serif); font-size: 13px; color: var(--ink); }
.wiz__track { position: relative; height: 4px; border-radius: 4px; background: rgba(26,23,20,.08); overflow: hidden; }
.wiz__fill { position: absolute; left: 0; top: 0; bottom: 0; border-radius: 4px; transition: width .55s cubic-bezier(.65,0,.35,1), background-color .55s ease; }

/* content */
.wiz__content { flex: 1; overflow-y: auto; padding: 24px 24px 120px; }
.wiz__title { margin: 0; font-family: var(--serif); font-size: 24px; font-weight: 500; color: var(--ink); letter-spacing: -.01em; }
.wiz__sub { margin: 5px 0 20px; font-size: 13px; color: var(--muted); }
.col { display: flex; flex-direction: column; gap: 12px; }

/* servicio */
.svc { display: flex; align-items: center; gap: 14px; padding: 16px; border-radius: 16px; background: #fff; border: 1.5px solid; cursor: pointer; transition: all .2s ease; }
.svc__box { flex: none; width: 24px; height: 24px; border-radius: 8px; display: flex; align-items: center; justify-content: center; border: 1.5px solid; transition: all .2s ease; }
.svc__info { flex: 1; }
.svc__name { font-family: var(--serif); font-size: 17px; color: var(--ink); }
.svc__dur  { font-size: 12px; color: var(--muted); margin-top: 2px; }
.svc__price { font-size: 15px; font-weight: 600; color: var(--rose); }
.svc__more { display: flex; align-items: center; justify-content: center; gap: 6px; width: 100%; height: 46px; border:none; border-radius: 14px;background: #fbeef1; color: var(--rose); font-size: 14px; font-weight: 500; cursor: pointer; transition: background .18s, border-color .18s; }
.svc__more:hover { background: #fbeef1; border-color: var(--rose); }

/* estilista */
.auto { display: flex; align-items: center; gap: 14px; padding: 16px; border-radius: 16px; border: 1.5px solid; cursor: pointer; margin-bottom: 18px; transition: all .2s ease; }
.auto__ico { flex: none; width: 46px; height: 46px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: #f8e8ec; }
.auto__info { flex: 1; }
.auto__name { font-family: var(--serif); font-size: 16px; color: var(--ink); }
.auto__desc { font-size: 12px; color: var(--muted); margin-top: 2px; }
.radio { flex: none; width: 22px; height: 22px; border-radius: 50%; border: 1.5px solid; display: flex; align-items: center; justify-content: center; }
.radio__dot { width: 11px; height: 11px; border-radius: 50%; background: var(--rose); }
.grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.stl { padding: 18px 14px; border-radius: 16px; background: #fff; border: 1.5px solid; cursor: pointer; text-align: center; transition: all .2s ease; }
.stl__av { width: 54px; height: 54px; border-radius: 50%; margin: 0 auto;     background: linear-gradient(135deg, #b0455f, #70001b); display: flex; align-items: center; justify-content: center; font-family: var(--serif); font-size: 18px; font-weight: 600; color: #fff; }
.stl__name { font-family: var(--serif); font-size: 14px; color: var(--ink); margin-top: 10px; }
.stl__spec { font-size: 11px; color: var(--muted); margin-top: 3px; line-height: 1.3; }

/* horario */
.dates { display: flex; gap: 10px; overflow-x: auto; padding: 0 24px 6px; margin: 0 -24px; }
.date { flex: none; width: 54px; padding: 12px 0; border-radius: 14px; border: 1.5px solid; text-align: center; cursor: pointer; transition: all .2s ease; }
.date__dow { font-size: 11px; text-transform: uppercase; letter-spacing: .04em; }
.date__day { font-family: var(--serif); font-size: 19px; margin-top: 3px; }
.slots__label { margin: 24px 0 14px; font-size: 12px; font-weight: 600; letter-spacing: .05em; text-transform: uppercase; color: var(--muted); }
.slots { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; }
.slot { height: 46px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 500; border: 1.5px solid transparent; cursor: pointer; transition: all .2s ease; }
.slot--taken { background: #f1ece8; color: #c2b6a8; text-decoration: line-through; cursor: not-allowed; }

/* pago */
.card { border-radius: 18px; background: #fff; border: 1px solid rgba(26,23,20,.08); padding: 18px; margin-bottom: 16px; }
.card__row { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 12px; }
.card__name { font-family: var(--serif); font-size: 15px; color: var(--ink); }
.card__dur  { font-size: 11px; color: var(--muted); margin-top: 1px; }
.card__price { font-size: 14px; font-weight: 600; color: var(--ink); }
.hr { height: 1px; background: rgba(26,23,20,.08); margin: 6px 0 14px; }
.card__line { display: flex; align-items: center; gap: 10px; font-size: 13px; color: var(--ink); margin-top: 9px; }
.card__line:first-of-type { margin-top: 0; }
.break { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.break:last-child { margin-bottom: 0; }
.muted { font-size: 13px; color: var(--muted); }
.muted.sm { font-size: 12px; }
.break__total { font-size: 14px; font-weight: 500; color: var(--ink); }
.break--anticipo { padding: 12px 14px; border-radius: 12px; background: #fbeef1; }
.break__antlbl { font-size: 13px; font-weight: 600; color: var(--ink); }
.break__antval { font-family: var(--serif); font-size: 20px; font-weight: 600; color: var(--rose); }
.break__antval.sm { font-size: 14px; }
.wompi { display: flex; align-items: center; justify-content: center; gap: 7px; font-size: 11.5px; color: var(--muted); margin-top: 4px; }
.pay-error { font-size: 13px; color: #dc2626; text-align: center; margin: 0 0 12px; }

/* auth panel */
.auth-wrap { flex: 1; padding: 28px 24px 40px; display: flex; flex-direction: column; }
.auth-back { display: flex; align-items: center; gap: 6px; border: 0; background: none; cursor: pointer; font-size: 13px; color: var(--muted); padding: 0; margin-bottom: 24px; }
.auth-title { font-family: var(--serif); font-size: 22px; font-weight: 500; color: var(--ink); margin: 0 0 20px; }
.auth-tabs { display: flex; gap: 0; background: rgba(26,23,20,.06); border-radius: 12px; padding: 3px; margin-bottom: 20px; }
.auth-tab { flex: 1; height: 36px; border: 0; background: transparent; border-radius: 10px; font-size: 13.5px; font-weight: 500; color: var(--muted); cursor: pointer; transition: all .18s; }
.auth-tab--on { background: #fff; color: var(--ink); box-shadow: 0 1px 4px rgba(26,23,20,.10); }
.auth-form { display: flex; flex-direction: column; gap: 14px; }
.auth-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.auth-group { display: flex; flex-direction: column; gap: 5px; min-width: 0; }
.auth-label { font-size: 11px; font-weight: 600; color: #8a7f72; text-transform: uppercase; letter-spacing: .04em; }
.auth-input { width: 100%; box-sizing: border-box; height: 44px; padding: 0 14px; border-radius: 12px; border: 1.5px solid rgba(26,23,20,.14); background: #fff; font-size: 14px; font-family: inherit; color: var(--ink); outline: none; transition: border-color .18s; }
.auth-input:focus { border-color: #B0455F; }
.auth-error { font-size: 13px; color: #dc2626; }
.auth-btn { height: 52px; border: 0; border-radius: 14px; background: #B0455F; color: #FBF6F4; font-family: var(--serif); font-size: 17px; font-weight: 500; cursor: pointer; transition: filter .2s; display: flex; align-items: center; justify-content: center; }
.auth-btn:disabled { opacity: .55; cursor: not-allowed; }
.auth-btn:not(:disabled):hover { filter: brightness(1.07); }

/* cta bar */
.wiz__cta { position: fixed; left: 50%; bottom: 0; transform: translateX(-50%); width: 100%; max-width: 480px; display: flex; align-items: center; justify-content: space-between; padding: 14px 20px 18px; background: rgba(251,246,244,.94); backdrop-filter: blur(16px); border-top: 1px solid rgba(26,23,20,.08); }
.wiz__cta-top { font-size: 11px; color: var(--muted); letter-spacing: .02em; }
.wiz__cta-amount { font-family: var(--serif); font-size: 22px; font-weight: 600; color: var(--ink); line-height: 1.1; }
.wiz__cta-btn { display: flex; align-items: center; justify-content: center; gap: 9px; min-width: 150px; height: 52px; padding: 0 22px; border: 0; border-radius: 14px; color: #fbf6f4; transition: all .2s ease; }
.wiz__cta-label { font-family: var(--serif); font-size: 17px; font-weight: 500; }
.spin { width: 18px; height: 18px; border-radius: 50%; border: 2px solid rgba(251,246,244,.4); border-top-color: #fbf6f4; animation: spin .7s linear infinite; display: inline-block; }

/* éxito */
.ok { display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding: 32px; min-height: 100vh; }
.ok__circle { width: 96px; height: 96px; border-radius: 50%; background: #fbeef1; display: flex; align-items: center; justify-content: center; animation: pop .5s cubic-bezier(.2,.8,.3,1.1) both; }
.ok__check { stroke-dasharray: 30; stroke-dashoffset: 30; animation: draw .5s .35s ease forwards; }
.ok__title { font-family: var(--serif); font-size: 30px; font-weight: 500; color: var(--ink); margin-top: 24px; letter-spacing: -.01em; animation: fade .4s .3s both; }
.ok__sub { font-size: 14px; color: var(--muted); margin-top: 8px; max-width: 260px; line-height: 1.5; animation: fade .4s .4s both; }
.ok__card { width: 100%; max-width: 300px; margin-top: 28px; border-radius: 18px; background: #fff; border: 1px solid rgba(26,23,20,.08); padding: 18px; text-align: left; animation: fade .4s .5s both; }
.ok__when { font-family: var(--serif); font-size: 16px; color: var(--ink); margin-bottom: 12px; }
.ok__btn { margin-top: 28px; width: 100%; max-width: 300px; height: 54px; border: 0; border-radius: 14px; background: var(--ink); color: #fbf6f4; cursor: pointer; font-family: var(--serif); font-size: 17px; font-weight: 500; animation: fade .4s .6s both; }

/* sidebar */
.wiz__aside { display: none; }

/* ══════════════ DESKTOP ══════════════ */
@media (min-width: 1100px) {
  .wiz { max-width: 1040px; min-height: auto; display: grid; grid-template-columns: minmax(0,1fr) 360px; grid-template-rows: auto 1fr; column-gap: 56px; padding: 12px 40px 80px; }
  .wiz__top { grid-column: 1 / -1; padding: 28px 0 22px; }
  .wiz__content { overflow: visible; padding: 8px 0 0; }
  .grid2 { grid-template-columns: repeat(4,1fr); }
  .wiz__cta { display: none; }
  .auth-wrap { grid-column: 1 / -1; max-width: 480px; margin: 0 auto; }
  .wiz__aside { display: block; }
  .wiz__sumcard { position: sticky; top: 90px; border: 1px solid rgba(26,23,20,.12); border-radius: 20px; padding: 22px; background: #fff; box-shadow: 0 10px 34px rgba(20,12,4,.10); }
  .wiz__sumttl { font-family: var(--serif); font-size: 18px; font-weight: 500; color: var(--ink); margin-bottom: 14px; }
  .wiz__sumlist { display: flex; flex-direction: column; gap: 10px; }
  .wiz__sumrow { display: flex; justify-content: space-between; gap: 12px; font-size: 14px; color: var(--ink); }
  .wiz__sumrow.muted { color: var(--muted); font-size: 13px; }
  .wiz__sumempty { font-size: 13px; color: var(--muted); }
  .wiz__aside .hr { margin: 14px 0; }
  .wiz__aside .break--anticipo { margin: 12px 0; }
  .wiz__sumbtn { display: flex; align-items: center; justify-content: center; width: 100%; height: 52px; margin-top: 18px; border: 0; border-radius: 14px; color: #fbf6f4; font-family: var(--serif); font-size: 18px; font-weight: 500; transition: filter .2s; }
  .wiz__sumbtn:not(:disabled):hover { filter: brightness(1.05); }
  .wiz__sumnote { margin-top: 12px; text-align: center; font-size: 12px; color: var(--muted); }
  .ok { grid-column: 1 / -1; min-height: 70vh; }
}
</style>
