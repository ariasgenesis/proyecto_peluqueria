<script setup>
import { onMounted, ref, watch } from 'vue'
import { listarReservasWeb, cancelarReservaWeb, actualizarReservaWeb } from '@/api/reservasWeb'
import { updateFactura } from '@/api/admin'
import { useAlertDialog } from '@/composables/useAlertDialog'

const items    = ref([])
const loading  = ref(true)
const total    = ref(0)
const page     = ref(1)
const PER_PAGE = 20

const filtroEstado = ref('')
const selected     = ref(null)
const canceling    = ref(false)
const saving       = ref(false)
const actionError  = ref('')
const { alertDialog, confirmDialog, promptDialog } = useAlertDialog()

async function showStockServiceAlert(changes = []) {
  if (!changes?.length) return
  const inactivos = changes.filter(c => c.estado_nuevo === 'inactivo')
  const nombres = changes.map(c => c.nombre).join(', ')
  await alertDialog({
    title: inactivos.length ? 'Servicio inactivado' : 'Servicio actualizado',
    message: inactivos.length
      ? `${nombres} quedo inactivo por stock bajo o agotado.`
      : `${nombres} volvio a estar activo por recuperacion de stock.`,
    variant: inactivos.length ? 'warning' : 'success',
  })
}

const fmt     = (n) => '$' + Number(n).toLocaleString('es-CO')
const fmtDate = (s) => {
  if (!s) return '—'
  const [y, m, d] = s.split('-')
  const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic']
  return `${parseInt(d)} ${meses[parseInt(m)-1]} ${y}`
}
const fmtHora = (s) => (s || '').slice(0, 5)

const ESTADO = {
  pendiente: { label: 'Pendiente', color: '#92400e', bg: '#fef3c7' },
  pagada:    { label: 'Pagada',    color: '#065f46', bg: '#d1fae5' },
  cancelada: { label: 'Cancelada', color: '#991b1b', bg: '#fee2e2' },
}

async function cargar() {
  loading.value = true
  try {
    const params = { page: page.value, per_page: PER_PAGE }
    if (filtroEstado.value) params.estado = filtroEstado.value
    const data = await listarReservasWeb(params)
    items.value = data.data || []
    total.value = data.total || 0
  } finally {
    loading.value = false
  }
}

async function asegurarFacturaSeleccionada() {
  if (selected.value?.fac_servicio_id) return selected.value.fac_servicio_id
  await actualizarReservaWeb(selected.value.id_reserva, { generar_factura: true })
  await cargar()
  selected.value = items.value.find(r => r.id_reserva === selected.value.id_reserva) || selected.value
  if (!selected.value.fac_servicio_id) throw new Error('No se pudo generar la factura de la reserva')
  return selected.value.fac_servicio_id
}

async function generarFactura() {
  if (!selected.value || saving.value) return
  saving.value = true
  actionError.value = ''
  try {
    await asegurarFacturaSeleccionada()
  } catch (e) {
    actionError.value = e.response?.data?.message || e.message || 'Error al generar factura'
  } finally {
    saving.value = false
  }
}

async function registrarAnticipo() {
  if (!selected.value || saving.value) return
  const monto = await promptDialog({
    title: 'Registrar anticipo',
    message: 'Ingresa el nuevo anticipo para la reserva.',
    inputType: 'number',
    placeholder: 'Valor',
    confirmText: 'Continuar',
  })
  if (monto === null) return
  const valor = Number(monto)
  if (!Number.isFinite(valor) || valor < 0 || valor > Number(selected.value.total || 0)) {
    actionError.value = 'Ingresa un anticipo valido'
    return
  }
  const pin = await promptDialog({
    title: 'PIN del empleado',
    message: 'Confirma el ajuste con el PIN del empleado.',
    inputType: 'password',
    placeholder: '4 digitos',
  })
  if (pin === null) return
  if (!pin?.match(/^\d{4}$/)) {
    actionError.value = 'PIN de 4 digitos requerido'
    return
  }
  saving.value = true
  actionError.value = ''
  try {
    const facturaId = await asegurarFacturaSeleccionada()
    const factura = await updateFactura(facturaId, { anticipo: valor, pin })
    await cargar()
    selected.value = items.value.find(r => r.id_reserva === selected.value.id_reserva) || null
    await showStockServiceAlert(factura.servicios_actualizados)
  } catch (e) {
    actionError.value = e.response?.data?.message || 'Error al registrar anticipo'
  } finally {
    saving.value = false
  }
}

async function marcarPagada() {
  if (!selected.value || saving.value) return
  const pin = await promptDialog({
    title: 'PIN del empleado',
    message: 'Confirma el pago con el PIN del empleado.',
    inputType: 'password',
    placeholder: '4 digitos',
    confirmText: 'Marcar pagada',
  })
  if (pin === null) return
  if (!pin?.match(/^\d{4}$/)) {
    actionError.value = 'PIN de 4 digitos requerido'
    return
  }
  saving.value = true
  actionError.value = ''
  try {
    const facturaId = await asegurarFacturaSeleccionada()
    const factura = await updateFactura(facturaId, { anticipo: Number(selected.value.total || 0), pin })
    await cargar()
    selected.value = items.value.find(r => r.id_reserva === selected.value.id_reserva) || null
    await showStockServiceAlert(factura.servicios_actualizados)
  } catch (e) {
    actionError.value = e.response?.data?.message || 'Error al marcar como pagada'
  } finally {
    saving.value = false
  }
}

async function cancelar(id) {
  const ok = await confirmDialog({
    title: 'Cancelar reserva',
    message: 'Cancelar esta reserva?',
    variant: 'danger',
    confirmText: 'Cancelar reserva',
  })
  if (!ok) return
  canceling.value = true
  try {
    await cancelarReservaWeb(id)
    selected.value = null
    await cargar()
  } finally {
    canceling.value = false
  }
}

// ─── impresión ─────────────────────────────────────────────────────────────────
function imprimirFactura(r) {
  const items = r.servicios_items || []
  const totalServicios = items.reduce((s, i) => s + i.precio, 0) || r.total || 0
  const saldo = r.saldo_pendiente || 0

  const filas = items.length
    ? items.map(i => `
        <tr>
          <td>${i.nombre}</td>
          <td style="text-align:right">${fmt(i.precio)}</td>
        </tr>`).join('')
    : `<tr><td>${r.servicios || '—'}</td><td style="text-align:right">${fmt(totalServicios)}</td></tr>`

  const html = `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Recibo Reserva #${r.id_reserva}</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family: 'Segoe UI', Arial, sans-serif; font-size:13px; color:#1a1714; padding:32px; max-width:480px; margin:auto; }
  .brand { text-align:center; margin-bottom:28px; }
  .brand h1 { font-family:Georgia,serif; font-size:26px; font-weight:600; color:#B0455F; letter-spacing:-.01em; }
  .brand p  { font-size:11px; color:#8a7f72; margin-top:4px; }
  .doc-title { text-align:center; font-size:15px; font-weight:600; color:#1a1714; margin-bottom:6px; }
  .doc-sub   { text-align:center; font-size:11px; color:#8a7f72; margin-bottom:24px; }
  .section { margin-bottom:18px; }
  .section-lbl { font-size:10px; font-weight:700; text-transform:uppercase; letter-spacing:.06em; color:#8a7f72; margin-bottom:7px; }
  .info-grid { display:grid; grid-template-columns:1fr 1fr; gap:6px 16px; }
  .info-row  { display:flex; flex-direction:column; }
  .info-key  { font-size:10px; color:#8a7f72; }
  .info-val  { font-size:13px; font-weight:500; color:#1a1714; margin-top:1px; }
  table { width:100%; border-collapse:collapse; margin-top:4px; }
  th { font-size:10px; font-weight:700; text-transform:uppercase; letter-spacing:.05em; color:#8a7f72; border-bottom:1px solid #e5e0db; padding:4px 0; text-align:left; }
  th:last-child { text-align:right; }
  td { padding:7px 0; border-bottom:1px solid #f0ede9; font-size:13px; }
  .totals { margin-top:14px; }
  .total-row { display:flex; justify-content:space-between; font-size:13px; padding:4px 0; color:#6b6258; }
  .total-row.main { font-size:16px; font-weight:700; color:#1a1714; border-top:2px solid #1a1714; padding-top:10px; margin-top:6px; }
  .total-row.paid { color:#16a34a; font-weight:600; }
  .total-row.saldo { color:${saldo > 0 ? '#d97706' : '#16a34a'}; font-weight:600; }
  .ref-box { background:#faf8f6; border-radius:8px; padding:10px 12px; margin-top:18px; font-size:11px; color:#8a7f72; word-break:break-all; }
  .ref-box strong { display:block; font-size:10px; text-transform:uppercase; letter-spacing:.05em; margin-bottom:3px; color:#a59a8d; }
  .footer { margin-top:28px; text-align:center; font-size:11px; color:#a59a8d; border-top:1px dashed #e5e0db; padding-top:16px; }
  .chip { display:inline-block; font-size:11px; font-weight:600; padding:3px 10px; border-radius:20px;
    background:${r.estado === 'pagada' ? '#d1fae5' : r.estado === 'cancelada' ? '#fee2e2' : '#fef3c7'};
    color:${r.estado === 'pagada' ? '#065f46' : r.estado === 'cancelada' ? '#991b1b' : '#92400e'}; }
  @media print { body { padding:0; } }
</style>
</head>
<body>
  <div class="brand">
    <h1>Beutycore</h1>
    <p>Salón de belleza</p>
  </div>

  <div class="doc-title">Recibo de reserva</div>
  <div class="doc-sub">
    #${r.id_reserva} &nbsp;·&nbsp; <span class="chip">${ESTADO[r.estado]?.label || r.estado}</span>
  </div>

  <div class="section">
    <div class="section-lbl">Cliente</div>
    <div class="info-grid">
      <div class="info-row"><span class="info-key">Nombre</span><span class="info-val">${r.cliente || '—'}</span></div>
      <div class="info-row"><span class="info-key">Teléfono</span><span class="info-val">${r.telefono || '—'}</span></div>
    </div>
  </div>

  <div class="section">
    <div class="section-lbl">Cita</div>
    <div class="info-grid">
      <div class="info-row"><span class="info-key">Fecha</span><span class="info-val">${fmtDate(r.fecha)}</span></div>
      <div class="info-row"><span class="info-key">Hora</span><span class="info-val">${fmtHora(r.hora)}</span></div>
      <div class="info-row"><span class="info-key">Estilista</span><span class="info-val">${r.empleado || '—'}</span></div>
    </div>
  </div>

  <div class="section">
    <div class="section-lbl">Servicios</div>
    <table>
      <thead><tr><th>Servicio</th><th>Precio</th></tr></thead>
      <tbody>${filas}</tbody>
    </table>
  </div>

  <div class="totals">
    <div class="total-row paid"><span>Anticipo pagado (Wompi)</span><span>${fmt(r.anticipo)}</span></div>
    <div class="total-row saldo"><span>Saldo pendiente</span><span>${fmt(saldo)}</span></div>
    <div class="total-row main"><span>Total</span><span>${fmt(totalServicios)}</span></div>
  </div>

  ${r.referencia ? `<div class="ref-box"><strong>Referencia de pago</strong>${r.referencia}</div>` : ''}

  <div class="footer">
    Emitido el ${new Date().toLocaleDateString('es-CO', { day:'numeric', month:'long', year:'numeric' })}<br>
    Beutycore — Gracias por tu preferencia
  </div>
</body>
</html>`

  const win = window.open('', '_blank', 'width=560,height=780')
  win.document.write(html)
  win.document.close()
  win.focus()
  win.onload = () => win.print()
}

onMounted(cargar)
watch(filtroEstado, () => { page.value = 1; cargar() })
watch(page, cargar)
</script>

<template>
  <div class="rv">
    <!-- topbar -->
    <div class="rv__top">
      <h1 class="rv__title">Reservas web</h1>
      <div class="rv__filters">
        <select class="rv__select" v-model="filtroEstado">
          <option value="">Todos los estados</option>
          <option value="pendiente">Pendiente</option>
          <option value="pagada">Pagada</option>
          <option value="cancelada">Cancelada</option>
        </select>
      </div>
    </div>

    <!-- tabla -->
    <div class="rv__wrap">
      <div v-if="loading" class="rv__loading">
        <div class="rv__spin"></div>
      </div>

      <table v-else class="rv__table">
        <thead>
          <tr>
            <th>#</th>
            <th>Cliente</th>
            <th>Servicios</th>
            <th>Fecha</th>
            <th>Hora</th>
            <th>Estilista</th>
            <th>Anticipo</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="!items.length">
            <td colspan="8" class="rv__empty">Sin reservas</td>
          </tr>
          <tr
            v-for="r in items" :key="r.id_reserva"
            class="rv__row"
            :class="{ 'rv__row--on': selected?.id_reserva === r.id_reserva }"
            @click="selected = selected?.id_reserva === r.id_reserva ? null : r; actionError = ''"
          >
            <td class="rv__id">{{ r.id_reserva }}</td>
            <td>
              <div class="rv__name">{{ r.cliente || '—' }}</div>
              <div class="rv__phone">{{ r.telefono }}</div>
            </td>
            <td class="rv__svcs">{{ r.servicios || '—' }}</td>
            <td>{{ fmtDate(r.fecha) }}</td>
            <td>{{ fmtHora(r.hora) }}</td>
            <td>{{ r.empleado || '—' }}</td>
            <td class="rv__amt">{{ fmt(r.anticipo) }}</td>
            <td>
              <span class="rv__chip"
                :style="{ color: ESTADO[r.estado]?.color, background: ESTADO[r.estado]?.bg }">
                {{ ESTADO[r.estado]?.label || r.estado }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- paginación -->
    <div v-if="total > PER_PAGE" class="rv__pag">
      <button class="rv__pgbtn" :disabled="page === 1" @click="page--">‹</button>
      <span class="rv__pginfo">{{ page }} / {{ Math.ceil(total / PER_PAGE) }}</span>
      <button class="rv__pgbtn" :disabled="page * PER_PAGE >= total" @click="page++">›</button>
    </div>

    <!-- detalle lateral -->
    <Transition name="sheet">
      <div v-if="selected" class="rv__sheet">
        <button class="rv__close" @click="selected = null">✕</button>
        <div class="rv__sheet-id">Reserva #{{ selected.id_reserva }}</div>
        <span class="rv__chip"
          :style="{ color: ESTADO[selected.estado]?.color, background: ESTADO[selected.estado]?.bg }">
          {{ ESTADO[selected.estado]?.label || selected.estado }}
        </span>

        <div class="rv__dfield"><span>Cliente</span><strong>{{ selected.cliente || '—' }}</strong></div>
        <div class="rv__dfield"><span>Teléfono</span><strong>{{ selected.telefono || '—' }}</strong></div>
        <div class="rv__dfield"><span>Servicios</span><strong>{{ selected.servicios || '—' }}</strong></div>
        <div class="rv__dfield"><span>Fecha</span><strong>{{ fmtDate(selected.fecha) }}</strong></div>
        <div class="rv__dfield"><span>Hora</span><strong>{{ fmtHora(selected.hora) }}</strong></div>
        <div class="rv__dfield"><span>Estilista</span><strong>{{ selected.empleado || '—' }}</strong></div>
        <div class="rv__dfield"><span>Total</span><strong>{{ fmt(selected.total || 0) }}</strong></div>
        <div class="rv__dfield"><span>Anticipo pagado</span><strong style="color:#16a34a">{{ fmt(selected.anticipo) }}</strong></div>
        <div class="rv__dfield">
          <span>Saldo pendiente</span>
          <strong :style="{ color: (selected.saldo_pendiente || 0) > 0 ? '#d97706' : '#16a34a' }">
            {{ fmt(selected.saldo_pendiente || 0) }}
          </strong>
        </div>
        <div class="rv__dfield"><span>Referencia</span><strong class="rv__ref">{{ selected.referencia || '—' }}</strong></div>
        <div class="rv__dfield"><span>Creada</span><strong>{{ selected.created_at?.slice(0,16).replace('T',' ') }}</strong></div>
        <p v-if="actionError" class="rv__error">{{ actionError }}</p>

        <!-- servicios detalle -->
        <div v-if="selected.servicios_items?.length" class="rv__svc-list">
          <div class="rv__svc-lbl">Servicios</div>
          <div v-for="s in selected.servicios_items" :key="s.nombre" class="rv__svc-row">
            <span>{{ s.nombre }}</span>
            <span>{{ fmt(s.precio) }}</span>
          </div>
        </div>

        <button
          v-if="selected.estado !== 'cancelada'"
          class="rv__print-btn"
          @click="imprimirFactura(selected)"
        >
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
          Imprimir recibo
        </button>

        <button
          v-if="selected.estado !== 'cancelada' && !selected.fac_servicio_id"
          class="rv__print-btn"
          :disabled="saving"
          @click="generarFactura"
        >
          {{ saving ? 'Guardando...' : 'Generar factura' }}
        </button>

        <button
          v-if="selected.estado !== 'cancelada' && selected.estado !== 'pagada'"
          class="rv__print-btn"
          :disabled="saving"
          @click="registrarAnticipo"
        >
          Registrar anticipo
        </button>

        <button
          v-if="selected.estado !== 'cancelada' && (selected.saldo_pendiente || 0) > 0"
          class="rv__print-btn"
          :disabled="saving"
          @click="marcarPagada"
        >
          {{ saving ? 'Guardando...' : 'Marcar pagada' }}
        </button>

        <button
          v-if="selected.estado === 'pendiente'"
          class="rv__cancel-btn"
          :disabled="canceling"
          @click="cancelar(selected.id_reserva)"
        >
          {{ canceling ? 'Cancelando…' : 'Cancelar reserva' }}
        </button>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
@keyframes spin { to { transform: rotate(360deg); } }

.rv { position: relative; padding: 28px 24px 60px; min-height: 100%; }

.rv__top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; gap: 12px; flex-wrap: wrap; }
.rv__title { font-family: var(--serif); font-size: 22px; font-weight: 500; color: var(--ink); margin: 0; }
.rv__filters { display: flex; gap: 10px; }
.rv__select { height: 36px; padding: 0 12px; border: 1px solid rgba(26,23,20,.15); border-radius: 10px; background: #fff; font-size: 13px; color: var(--ink); cursor: pointer; }

.rv__wrap { border-radius: 16px; border: 1px solid rgba(26,23,20,.1); overflow-x: auto; background: #fff; }
.rv__loading { display: flex; justify-content: center; padding: 48px; }
.rv__spin { width: 32px; height: 32px; border-radius: 50%; border: 3px solid rgba(176,69,95,.15); border-top-color: #B0455F; animation: spin .8s linear infinite; }

.rv__table { width: 100%; min-width: 860px; border-collapse: collapse; font-size: 13px; }
.rv__table th { padding: 10px 14px; text-align: left; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); border-bottom: 1px solid rgba(26,23,20,.08); background: #faf8f6; }
.rv__table td { padding: 12px 14px; border-bottom: 1px solid rgba(26,23,20,.06); color: var(--ink); vertical-align: middle; }
.rv__row { cursor: pointer; transition: background .15s; }
.rv__row:hover { background: #faf8f6; }
.rv__row--on { background: #fbeef1 !important; }
.rv__empty { text-align: center; color: var(--muted); padding: 40px !important; }
.rv__id { font-family: var(--serif); font-size: 14px; color: var(--muted); }
.rv__name { font-weight: 500; }
.rv__phone { font-size: 11px; color: var(--muted); }
.rv__svcs { max-width: 180px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: var(--muted); }
.rv__amt { font-weight: 600; }
.rv__chip { font-size: 11px; font-weight: 600; padding: 3px 9px; border-radius: 20px; white-space: nowrap; }

.rv__pag { display: flex; align-items: center; justify-content: center; gap: 16px; margin-top: 16px; }
.rv__pgbtn { width: 32px; height: 32px; border: 1px solid rgba(26,23,20,.15); border-radius: 8px; background: #fff; cursor: pointer; font-size: 16px; color: var(--ink); }
.rv__pgbtn:disabled { opacity: .4; cursor: not-allowed; }
.rv__pginfo { font-size: 13px; color: var(--muted); }

/* detail sheet */
.rv__sheet { position: fixed; top: 0; right: 0; bottom: 0; width: 320px; background: #fff; border-left: 1px solid rgba(26,23,20,.1); padding: 28px 22px; overflow-y: auto; z-index: 100; display: flex; flex-direction: column; gap: 14px; box-shadow: -4px 0 24px rgba(20,12,4,.08); }
.rv__close { align-self: flex-end; width: 30px; height: 30px; border: 0; background: rgba(26,23,20,.06); border-radius: 50%; cursor: pointer; font-size: 13px; color: var(--muted); }
.rv__sheet-id { font-family: var(--serif); font-size: 20px; font-weight: 500; color: var(--ink); }
.rv__dfield { display: flex; justify-content: space-between; align-items: baseline; gap: 10px; font-size: 13px; border-bottom: 1px solid rgba(26,23,20,.06); padding-bottom: 10px; }
.rv__dfield span { color: var(--muted); flex: none; }
.rv__dfield strong { text-align: right; }
.rv__ref { font-size: 11px; font-family: monospace; }
.rv__svc-list { border: 1px solid rgba(26,23,20,.08); border-radius: 12px; padding: 12px 14px; background: #faf8f6; }
.rv__svc-lbl { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .05em; color: var(--muted); margin-bottom: 8px; }
.rv__svc-row { display: flex; justify-content: space-between; font-size: 13px; color: var(--ink); padding: 4px 0; border-bottom: 1px solid rgba(26,23,20,.05); }
.rv__svc-row:last-child { border-bottom: 0; }
.rv__error { margin: 0; color: #B0455F; font-size: 12px; }

.rv__print-btn { display: flex; align-items: center; justify-content: center; gap: 7px; width: 100%; height: 42px; border: 1.5px solid #B0455F; border-radius: 12px; background: transparent; color: #B0455F; font-size: 14px; font-weight: 600; cursor: pointer; font-family: inherit; transition: background .15s; }
.rv__print-btn:hover { background: rgba(176,69,95,.06); }
.rv__cancel-btn { width: 100%; height: 40px; border: 0; border-radius: 12px; background: #fee2e2; color: #991b1b; font-size: 13px; font-weight: 600; cursor: pointer; }
.rv__cancel-btn:disabled { opacity: .55; cursor: not-allowed; }

.sheet-enter-active, .sheet-leave-active { transition: transform .25s ease; }
.sheet-enter-from, .sheet-leave-to { transform: translateX(100%); }

@media (max-width: 720px) {
  .rv { padding: 22px 14px 48px; }
  .rv__wrap { border-radius: 12px; }
  .rv__table th, .rv__table td { padding: 10px 12px; }
  .rv__sheet { left: 0; width: auto; border-left: 0; }
}
</style>
