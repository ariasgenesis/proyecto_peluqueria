<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { crearPagoNequi, consultarEstadoPago } from '@/api/pagos'

const router = useRouter()

// ── Datos del pago (desde sessionStorage) ────────────────────
const pagoData   = ref(null)   // { wompi, summary }
const wompi      = ref(null)   // { public_key, reference, amount_in_cents, integrity_hash }
const summary    = ref(null)   // { services, when, stylist, anticipo, saldo, total }

// ── Estado UI ─────────────────────────────────────────────────
const telefono   = ref('')
const telError   = ref('')
const estado     = ref('form')  // 'form' | 'pending' | 'approved' | 'declined' | 'error'
const loading    = ref(false)
const errMsg     = ref('')
const txId       = ref(null)
const pollCount  = ref(0)
const MAX_POLLS  = 80  // 4 min a 3s

let pollTimer = null

const fmt = (n) => '$' + Number(n).toLocaleString('es-CO') + ' COP'

onMounted(() => {
  const raw = sessionStorage.getItem('pago_pendiente')
  if (!raw) { router.replace('/reservar'); return }
  pagoData.value = JSON.parse(raw)
  wompi.value   = pagoData.value.wompi
  summary.value = pagoData.value.summary
})

onUnmounted(() => clearInterval(pollTimer))

// ── Validar teléfono ──────────────────────────────────────────
function validarTel() {
  const t = telefono.value.replace(/\s/g, '')
  if (!t) { telError.value = 'Ingresa tu número de celular'; return false }
  if (!/^\d{10}$/.test(t)) { telError.value = 'Debe ser un número de 10 dígitos'; return false }
  telError.value = ''
  return true
}

// ── Confirmar pago ────────────────────────────────────────────
async function confirmar() {
  if (!validarTel()) return
  loading.value = true
  errMsg.value  = ''
  try {
    const tel = telefono.value.replace(/\s/g, '')
    const res = await crearPagoNequi({
      referencia:      wompi.value.reference,
      amount_in_cents: wompi.value.amount_in_cents,
      integrity_hash:  wompi.value.integrity_hash,
      telefono:        tel,
    })
    txId.value    = res.transaction_id
    estado.value  = 'pending'
    startPolling()
  } catch (e) {
    errMsg.value = e.response?.data?.message || 'Error al iniciar el pago. Intenta de nuevo.'
  } finally {
    loading.value = false
  }
}

// ── Polling ───────────────────────────────────────────────────
function startPolling() {
  pollCount.value = 0
  pollTimer = setInterval(checkStatus, 3000)
}

async function checkStatus() {
  pollCount.value++
  if (pollCount.value > MAX_POLLS) {
    clearInterval(pollTimer)
    estado.value = 'error'
    errMsg.value = 'Tiempo de espera agotado. Verifica en tu app Nequi si el pago fue procesado.'
    return
  }
  try {
    const res = await consultarEstadoPago(txId.value)
    const s   = res.status
    if (s === 'APPROVED') {
      clearInterval(pollTimer)
      sessionStorage.removeItem('pago_pendiente')
      sessionStorage.setItem('reserva_exitosa', JSON.stringify({
        when:    summary.value?.when,
        stylist: summary.value?.stylist,
        anticipo: summary.value?.anticipo,
        saldo:   summary.value?.saldo,
      }))
      estado.value = 'approved'
    } else if (s === 'DECLINED' || s === 'VOIDED' || s === 'ERROR') {
      clearInterval(pollTimer)
      estado.value = 'declined'
      errMsg.value = s === 'DECLINED' ? 'Pago rechazado por Nequi. Verifica que tu cuenta tenga saldo.' : 'El pago fue cancelado o venció.'
    }
  } catch { /* continúa polling */ }
}

function reintentar() {
  clearInterval(pollTimer)
  estado.value  = 'form'
  errMsg.value  = ''
  txId.value    = null
}

function irAlExito() {
  router.replace('/reservar?exito=true')
}
</script>

<template>
  <div class="pg">

    <!-- ── HEADER ── -->
    <div class="pg__head">
      <button class="pg__back" @click="router.back()">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"><path d="M15 18l-6-6 6-6"/></svg>
      </button>
      <span class="pg__headtitle">Pagar anticipo</span>
      <span style="width:34px"></span>
    </div>

    <div v-if="summary" class="pg__body">

      <!-- ── RESUMEN ── -->
      <div class="pg__card">
        <div class="pg__svcs">
          <div v-for="s in summary.services" :key="s.id" class="pg__svc">
            <span class="pg__svcname">{{ s.nombre }}</span>
            <span class="pg__svcprice">{{ fmt(s.precio) }}</span>
          </div>
        </div>
        <div class="pg__hr"></div>
        <div class="pg__meta">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.6" stroke-linecap="round"><rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>
          <span>{{ summary.when }}</span>
        </div>
        <div class="pg__meta">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.6" stroke-linecap="round"><circle cx="12" cy="9" r="3"/><path d="M12 2a7 7 0 0 0-7 7c0 5 7 13 7 13s7-8 7-13a7 7 0 0 0-7-7z"/></svg>
          <span>{{ summary.stylist }}</span>
        </div>
      </div>

      <!-- ── FORMULARIO ── -->
      <template v-if="estado === 'form'">
        <div class="pg__card">
          <!-- Logo Nequi -->
          <div class="nq__head">
            <div class="nq__logo">
              <span class="nq__star">*</span><span class="nq__word">Nequi</span>
            </div>
          </div>

          <p class="nq__desc">Ingresa tu número de celular Nequi. Recibirás una notificación push para aprobar el pago.</p>

          <label class="pg__label">Número de celular</label>
          <input
            class="pg__input"
            :class="{ 'pg__input--err': telError }"
            v-model="telefono"
            type="tel"
            inputmode="numeric"
            placeholder="300 000 0000"
            maxlength="10"
            autocomplete="tel-national"
          />
          <span v-if="telError" class="pg__fielderr">{{ telError }}</span>

          <div class="pg__hr" style="margin-top:20px"></div>
          <div class="pg__row"><span class="pg__rowlbl">Total servicios</span><span class="pg__rowval">{{ fmt(summary.total) }}</span></div>
          <div class="pg__row pg__row--ant">
            <span class="pg__antlbl">Anticipo a pagar (30%)</span>
            <span class="pg__antval">{{ fmt(summary.anticipo) }}</span>
          </div>
          <div class="pg__row pg__row--saldo"><span class="pg__rowlbl muted">Saldo en Beutycore</span><span class="pg__rowlbl muted">{{ fmt(summary.saldo) }}</span></div>
        </div>

        <p v-if="errMsg" class="pg__errmsg">{{ errMsg }}</p>

        <p class="pg__terms">Al continuar aceptas los <a href="https://wompi.com/terminos-y-condiciones" target="_blank" class="pg__link">Términos y Condiciones</a> de Wompi.</p>

        <button class="pg__btn" :disabled="loading" @click="confirmar">
          <span v-if="loading" class="spin"></span>
          <span v-else>Confirmar</span>
        </button>
      </template>

      <!-- ── PENDIENTE ── -->
      <template v-else-if="estado === 'pending'">
        <div class="pg__card pg__card--center">
          <div class="nq__logo nq__logo--lg">
            <span class="nq__star">*</span><span class="nq__word">Nequi</span>
          </div>
          <div class="pg__spinner"></div>
          <p class="pg__pending-ttl">Esperando confirmación</p>
          <p class="pg__pending-sub">Revisa la notificación en tu app Nequi y aprueba el pago de <strong>{{ fmt(summary.anticipo) }}</strong>.</p>
          <div class="pg__dots">
            <span class="pg__dot"></span>
            <span class="pg__dot"></span>
            <span class="pg__dot"></span>
          </div>
        </div>
        <button class="pg__btn pg__btn--ghost" @click="reintentar">Cancelar</button>
      </template>

      <!-- ── APROBADO ── -->
      <template v-else-if="estado === 'approved'">
        <div class="pg__card pg__card--center">
          <div class="ok__circle">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="2.4" stroke-linecap="round">
              <path class="ok__check" d="M20 6 9 17l-5-5"/>
            </svg>
          </div>
          <p class="pg__ok-ttl">¡Pago confirmado!</p>
          <p class="pg__ok-sub">Anticipo de <strong>{{ fmt(summary.anticipo) }}</strong> recibido. Tu cita está lista.</p>
        </div>
        <button class="pg__btn" @click="irAlExito">Ver mi reserva</button>
      </template>

      <!-- ── DECLINADO / ERROR ── -->
      <template v-else>
        <div class="pg__card pg__card--center">
          <div class="err__circle">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2.2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
          </div>
          <p class="pg__ok-ttl">Pago no procesado</p>
          <p class="pg__ok-sub">{{ errMsg }}</p>
        </div>
        <button class="pg__btn" @click="reintentar">Intentar de nuevo</button>
      </template>

    </div>

    <!-- cargando (antes de montar summary) -->
    <div v-else class="pg__loading">
      <div class="pg__spinner"></div>
    </div>

  </div>
</template>

<style scoped>
@keyframes spin  { to { transform: rotate(360deg); } }
@keyframes pulse { 0%,100% { opacity: .35; transform: scale(.85); } 50% { opacity: 1; transform: scale(1); } }
@keyframes pop   { 0% { transform: scale(0); opacity: 0; } 60% { transform: scale(1.1); } 100% { transform: scale(1); opacity: 1; } }
@keyframes draw  { to { stroke-dashoffset: 0; } }
@keyframes fadein { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: none; } }

.pg {
  min-height: 100vh; display: flex; flex-direction: column;
  background: var(--bg); max-width: 480px; margin: 0 auto;
}

/* header */
.pg__head {
  display: flex; align-items: center; justify-content: space-between;
  padding: 16px 20px 12px; border-bottom: 1px solid rgba(26,23,20,.08);
  position: sticky; top: 0; background: var(--bg); z-index: 10;
}
.pg__back {
  width: 34px; height: 34px; border: 0; background: rgba(26,23,20,.05);
  border-radius: 50%; display: flex; align-items: center; justify-content: center;
  cursor: pointer; color: var(--ink);
}
.pg__headtitle { font-family: var(--serif); font-size: 16px; font-weight: 500; color: var(--ink); }

/* body */
.pg__body { flex: 1; padding: 20px 20px 100px; display: flex; flex-direction: column; gap: 14px; animation: fadein .3s ease both; }
.pg__loading { flex: 1; display: flex; align-items: center; justify-content: center; }

/* card */
.pg__card {
  background: #fff; border-radius: 20px; padding: 20px;
  border: 1px solid rgba(26,23,20,.08);
}
.pg__card--center { text-align: center; display: flex; flex-direction: column; align-items: center; gap: 14px; padding: 32px 20px; }

/* summary */
.pg__svcs { display: flex; flex-direction: column; gap: 10px; }
.pg__svc  { display: flex; justify-content: space-between; align-items: center; }
.pg__svcname  { font-family: var(--serif); font-size: 15px; color: var(--ink); }
.pg__svcprice { font-size: 14px; font-weight: 600; color: var(--ink); }
.pg__hr { height: 1px; background: rgba(26,23,20,.08); margin: 14px 0; }
.pg__meta { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--ink); margin-bottom: 6px; }
.pg__meta:last-child { margin-bottom: 0; }

/* Nequi logo */
.nq__head { display: flex; align-items: center; justify-content: center; margin-bottom: 14px; }
.nq__logo { display: inline-flex; align-items: baseline; gap: 2px; }
.nq__logo--lg { font-size: 1.4em; margin-bottom: 4px; }
.nq__star { font-size: 22px; font-weight: 900; color: #9B1EC0; line-height: 1; }
.nq__word { font-size: 26px; font-weight: 900; color: #1A1714; font-family: var(--serif); letter-spacing: -.02em; }

/* form */
.nq__desc { font-size: 13px; color: var(--muted); line-height: 1.55; margin: 0 0 18px; }
.pg__label { display: block; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: .04em; color: #8a7f72; margin-bottom: 8px; }
.pg__input {
  width: 100%; box-sizing: border-box; height: 52px; padding: 0 16px;
  border-radius: 14px; border: 1.5px solid rgba(26,23,20,.14); background: #f7f3f0;
  font-size: 18px; letter-spacing: .05em; font-family: inherit; color: var(--ink);
  outline: none; transition: border-color .18s;
}
.pg__input:focus { border-color: #B0455F; background: #fff; }
.pg__input--err  { border-color: #dc2626; }
.pg__fielderr { font-size: 12px; color: #dc2626; display: block; margin-top: 5px; }

/* breakdown */
.pg__row { display: flex; justify-content: space-between; align-items: center; font-size: 13px; color: var(--ink); margin-bottom: 8px; }
.pg__row:last-child { margin-bottom: 0; }
.pg__rowlbl { color: var(--muted); }
.pg__rowval { font-weight: 500; }
.pg__row--ant { padding: 12px 14px; border-radius: 12px; background: #fbeef1; margin: 4px 0; }
.pg__antlbl { font-size: 13px; font-weight: 600; color: var(--ink); }
.pg__antval { font-family: var(--serif); font-size: 20px; font-weight: 600; color: var(--rose); }
.pg__row--saldo { margin-top: 6px; }
.muted { color: var(--muted) !important; }

/* terms */
.pg__terms { font-size: 11.5px; color: var(--muted); text-align: center; margin: 0; }
.pg__link  { color: var(--rose); text-decoration: underline; text-underline-offset: 2px; }
.pg__errmsg { font-size: 13px; color: #dc2626; text-align: center; margin: 0; }

/* buttons */
.pg__btn {
  width: 100%; height: 56px; border: 0; border-radius: 16px; background: #B0455F;
  color: #FBF6F4; font-family: var(--serif); font-size: 19px; font-weight: 500;
  cursor: pointer; display: flex; align-items: center; justify-content: center;
  transition: filter .2s;
}
.pg__btn:not(:disabled):hover { filter: brightness(1.06); }
.pg__btn:disabled { opacity: .55; cursor: not-allowed; }
.pg__btn--ghost { background: transparent; border: 1.5px solid rgba(26,23,20,.15); color: var(--muted); font-size: 15px; }

/* spinner */
.pg__spinner {
  width: 44px; height: 44px; border-radius: 50%;
  border: 3px solid rgba(176,69,95,.15); border-top-color: #B0455F;
  animation: spin .8s linear infinite;
}
.spin { width: 20px; height: 20px; border-radius: 50%; border: 2px solid rgba(251,246,244,.4); border-top-color: #fbf6f4; animation: spin .7s linear infinite; display: inline-block; }

/* pending dots */
.pg__pending-ttl { font-family: var(--serif); font-size: 20px; color: var(--ink); margin: 0; }
.pg__pending-sub { font-size: 13px; color: var(--muted); line-height: 1.55; margin: 0; max-width: 280px; }
.pg__dots { display: flex; gap: 8px; align-items: center; }
.pg__dot {
  width: 8px; height: 8px; border-radius: 50%; background: #B0455F;
  animation: pulse 1.4s ease infinite;
}
.pg__dot:nth-child(2) { animation-delay: .2s; }
.pg__dot:nth-child(3) { animation-delay: .4s; }

/* success */
.ok__circle {
  width: 84px; height: 84px; border-radius: 50%; background: #fbeef1;
  display: flex; align-items: center; justify-content: center;
  animation: pop .45s cubic-bezier(.2,.8,.3,1.1) both;
}
.ok__check { stroke-dasharray: 30; stroke-dashoffset: 30; animation: draw .45s .3s ease forwards; }
.pg__ok-ttl { font-family: var(--serif); font-size: 22px; color: var(--ink); margin: 0; }
.pg__ok-sub { font-size: 13px; color: var(--muted); line-height: 1.55; margin: 0; max-width: 260px; }

/* error */
.err__circle {
  width: 74px; height: 74px; border-radius: 50%; background: #fef2f2;
  display: flex; align-items: center; justify-content: center;
  animation: pop .4s ease both;
}

/* desktop */
@media (min-width: 900px) {
  .pg { border-left: 1px solid rgba(26,23,20,.07); border-right: 1px solid rgba(26,23,20,.07); }
}
</style>
