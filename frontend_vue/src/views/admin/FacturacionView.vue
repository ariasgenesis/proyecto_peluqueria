<script setup>
import { computed, onMounted, ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import {
  getFacturas,
  getFactura,
  getReservaWeb,
  getServicios,
  getEmpleados,
  getCita,
  getDetallesCitas,
  getPagos,
  crearPago,
  fmtCOP,
} from '@/api/admin'
import { useAlertDialog } from '@/composables/useAlertDialog'

const loading = ref(true)
const allFacturas = ref([])
const allServicios = ref([])
const allEmpleados = ref([])
const q = ref('')
const filtroTipo = ref('todos')
const filtroEstado = ref('todos')
const selected = ref(null)
const detail = ref(emptyDetail())
const paymentOpen = ref(false)
const paymentSaving = ref(false)
const paymentError = ref('')
const paymentDraft = ref({ metodo: 'efectivo', monto: '', referencia: '' })
const fullDetailOpen = ref(false)
const { alertDialog } = useAlertDialog()

const auth = useAuthStore()
const isEmpleado = computed(() => auth.rol === 'empleado')

let detailToken = 0

function emptyDetail() {
  return {
    loading: false,
    error: '',
    servicios: [],
    pagos: [],
    reserva: null,
    cita: null,
  }
}

function localDate(date = new Date()) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

onMounted(loadInitialData)

async function loadInitialData() {
  loading.value = true
  try {
    const [facturas, servicios, empleados] = await Promise.all([
      getFacturas(),
      getServicios(),
      getEmpleados(),
    ])
    allFacturas.value = facturas
    allServicios.value = servicios
    allEmpleados.value = empleados
  } finally {
    loading.value = false
  }
}

const facturas = computed(() => {
  let list = allFacturas.value
  // Empleado: solo ve facturas del día actual
  if (isEmpleado.value) {
    const hoy = localDate()
    list = list.filter(f => (f.fecha || '').startsWith(hoy))
  }
  const s = q.value.trim().toLowerCase()
  if (s) {
    list = list.filter(f =>
      String(f.id_factura).includes(s) ||
      String(f.reserva_id || '').includes(s) ||
      String(f.cita_id || '').includes(s) ||
      (f.cliente || '').toLowerCase().includes(s) ||
      (f.empleado_confirmo || '').toLowerCase().includes(s) ||
      (f.confirmada_por_nombre || '').toLowerCase().includes(s)
    )
  }
  if (filtroTipo.value === 'wompi') list = list.filter(f => !!f.reserva_id)
  else if (filtroTipo.value !== 'todos') list = list.filter(f => f.tipo === filtroTipo.value)
  if (filtroEstado.value !== 'todos') list = list.filter(f => f.estado === filtroEstado.value)
  return list
})

const stats = computed(() => {
  const hoy = new Date().toISOString().slice(0, 10)
  const deHoy = allFacturas.value.filter(f => (f.fecha || '').startsWith(hoy))
  const facturasPagadas = allFacturas.value.filter(f => f.estado === 'pagada')
  const pagadasHoy = deHoy.filter(f => f.estado === 'pagada')
  const wompiTotal = facturasPagadas
    .filter(f => f.reserva_id)
    .reduce((s, f) => s + Number(f.total || 0), 0)
  return {
    citasHoy: deHoy.length,
    ingresosHoy: fmtCOP(pagadasHoy.reduce((s, f) => s + Number(f.total || 0), 0)),
    pendientes: allFacturas.value.filter(f => f.estado === 'pendiente').length,
    wompiTotal: fmtCOP(wompiTotal),
  }
})

const statsEmpleado = computed(() => {
  const hoy = localDate()
  const deHoy = allFacturas.value.filter(f => (f.fecha || '').startsWith(hoy))
  return {
    citasHoy: deHoy.length,
    pendientesHoy: deHoy.filter(f => Number(f.saldo_pendiente || 0) > 0).length,
  }
})

const subtotalSeleccionado = computed(() => {
  const totalServicios = detail.value.servicios.reduce((sum, s) => sum + Number(s.precio || 0), 0)
  return totalServicios || Number(selected.value?.total || 0)
})

const empleadoSeleccionado = computed(() => {
  const empleadoId = detail.value.cita?.empleado_id || detail.value.reserva?.empleado_id
  return empleadoId ? empleadoName(empleadoId) : empleadoLabel(selected.value)
})

const estadoLabel = {
  pagada: 'Pagada',
  pendiente: 'Pendiente',
  parcial: 'Parcial',
  anulada: 'Anulada',
  cancelada: 'Cancelada',
}
const tipoLabel = { servicio: 'Servicio', anticipo: 'Anticipo' }
const metodoLabel = {
  efectivo: 'Efectivo',
  transferencia: 'Transferencia',
  tarjeta: 'Tarjeta',
  wompi: 'Wompi',
}

function refLabel(f) {
  if (f?.cita_id) return 'Cita #' + f.cita_id
  if (f?.reserva_id) return 'Reserva web #' + f.reserva_id
  return '-'
}

function clienteLabel(f) {
  return f?.cliente || 'Cliente sin nombre'
}

function empleadoLabel(f) {
  return f?.empleado_confirmo || f?.confirmada_por_nombre || f?.generada_por_nombre || 'Pendiente'
}

function empleadoName(id) {
  const empleado = allEmpleados.value.find(e => e.id_empleado === Number(id))
  if (!empleado) return 'Empleado #' + id
  return `${empleado.nombre || ''} ${empleado.apellido || ''}`.trim() || empleado.username || `Empleado #${id}`
}

function servicioName(id) {
  const servicio = allServicios.value.find(s => s.id_servicio === Number(id))
  return servicio?.nombre || `Servicio #${id}`
}

function moneyValue(value) {
  return Number(value || 0)
}

function isSelected(f) {
  return selected.value?.id_factura === f.id_factura
}

async function selectFactura(f) {
  selected.value = f
  paymentOpen.value = false
  fullDetailOpen.value = false
  await loadDetail(f)
}

async function loadDetail(f) {
  const token = ++detailToken
  detail.value = { ...emptyDetail(), loading: true }
  try {
    let reserva = null
    let cita = null
    let servicios = []

    if (f.reserva_id) {
      reserva = await getReservaWeb(f.reserva_id)
      servicios = (reserva.servicios || []).map(s => ({
        id: s.id_servicio || s.id,
        nombre: s.nombre || servicioName(s.id_servicio || s.id),
        precio: Number(s.precio || 0),
      }))
    }

    if (f.cita_id) {
      const [citaData, detallesCita] = await Promise.all([
        getCita(f.cita_id).catch(() => null),
        getDetallesCitas({ cita_id: f.cita_id }).catch(() => []),
      ])
      cita = citaData
      if (detallesCita?.length) {
        servicios = detallesCita.map(d => ({
          id: d.servicio_id,
          nombre: servicioName(d.servicio_id),
          precio: Number(d.precio || 0),
        }))
      }
    }

    const pagos = await getPagos({ factura_id: f.id_factura }).catch(() => [])
    if (token !== detailToken) return
    detail.value = {
      loading: false,
      error: '',
      servicios,
      pagos,
      reserva,
      cita,
    }
  } catch (e) {
    if (token !== detailToken) return
    detail.value = {
      ...emptyDetail(),
      loading: false,
      error: e.response?.data?.message || 'No se pudo cargar el detalle de la factura',
    }
  }
}

function openPaymentModal() {
  if (!selected.value || !['pendiente', 'parcial'].includes(selected.value.estado) || moneyValue(selected.value.saldo_pendiente) <= 0) return
  paymentDraft.value = {
    metodo: 'efectivo',
    monto: selected.value.saldo_pendiente || '',
    referencia: '',
  }
  paymentError.value = ''
  paymentOpen.value = true
}

function closePaymentModal() {
  if (paymentSaving.value) return
  paymentOpen.value = false
  paymentError.value = ''
}

async function savePayment() {
  if (!selected.value) return
  const monto = Number(paymentDraft.value.monto)
  const saldo = Number(selected.value.saldo_pendiente || 0)
  paymentError.value = ''

  if (!paymentDraft.value.metodo) {
    paymentError.value = 'Selecciona un metodo de pago'
    return
  }
  if (!monto || monto <= 0) {
    paymentError.value = 'Ingresa un monto valido'
    return
  }
  if (saldo > 0 && monto > saldo) {
    paymentError.value = 'El monto no puede superar el saldo pendiente'
    return
  }

  paymentSaving.value = true
  try {
    const payload = {
      factura_id: selected.value.id_factura,
      metodo: paymentDraft.value.metodo,
      estado: 'completado',
      fecha: localDate(),
      monto,
    }
    if (paymentDraft.value.referencia?.trim()) payload.referencia = paymentDraft.value.referencia.trim()
    await crearPago(payload)

    const updated = await getFactura(selected.value.id_factura)
    const idx = allFacturas.value.findIndex(f => f.id_factura === updated.id_factura)
    if (idx !== -1) allFacturas.value[idx] = updated
    selected.value = updated
    paymentOpen.value = false
    await loadDetail(updated)
    await alertDialog({ title: 'Pago registrado', message: 'La factura fue actualizada correctamente.', variant: 'success' })
  } catch (e) {
    paymentError.value = e.response?.data?.message || 'Error al registrar pago'
  } finally {
    paymentSaving.value = false
  }
}

function openFullDetail() {
  if (selected.value) fullDetailOpen.value = true
}

async function printInvoice() {
  await alertDialog({
    title: 'Imprimir factura',
    message: 'La accion queda preparada para conectar impresion o descarga de PDF.',
    variant: 'warning',
  })
}
</script>

<template>
  <div class="fac">
    <div class="topbar">
      <h1 class="topbar__title">Facturacion</h1>
    </div>

    <!-- Admin: 4 tarjetas con indicadores completos -->
    <div v-if="!isEmpleado" class="stats">
      <div class="stat-card">
        <div class="stat-card__val">{{ stats.citasHoy }}</div>
        <div class="stat-card__lbl">Facturas hoy</div>
      </div>
      <div class="stat-card stat-card--rose">
        <div class="stat-card__val">{{ stats.ingresosHoy }}</div>
        <div class="stat-card__lbl">Ingresos hoy</div>
      </div>
      <div class="stat-card stat-card--warn">
        <div class="stat-card__val">{{ stats.pendientes }}</div>
        <div class="stat-card__lbl">Por cobrar</div>
      </div>
      <div class="stat-card stat-card--wompi">
        <div class="stat-card__val">{{ stats.wompiTotal }}</div>
        <div class="stat-card__lbl">Wompi cobrado</div>
      </div>
    </div>
    <!-- Empleado: solo conteos del día, sin indicadores financieros -->
    <div v-else class="stats stats--empleado">
      <div class="stat-card">
        <div class="stat-card__val">{{ statsEmpleado.citasHoy }}</div>
        <div class="stat-card__lbl">Facturas del día</div>
      </div>
      <div class="stat-card stat-card--warn">
        <div class="stat-card__val">{{ statsEmpleado.pendientesHoy }}</div>
        <div class="stat-card__lbl">Con saldo pendiente</div>
      </div>
    </div>

    <div class="toolbar">
      <div class="search">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.35-4.35"/></svg>
        <input v-model="q" class="search__input" type="search" placeholder="Buscar factura o cliente..." />
        <button v-if="q" class="search__clear" @click="q = ''">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
        </button>
      </div>
      <div class="chips">
        <button v-for="f in (isEmpleado ? ['todos','servicio','anticipo'] : ['todos','servicio','anticipo','wompi'])" :key="f"
          class="chip" :class="{ 'chip--on': filtroTipo === f, 'chip--wompi': f === 'wompi' && filtroTipo === f }"
          @click="filtroTipo = f">
          {{ f === 'todos' ? 'Todos' : f === 'servicio' ? 'Servicio' : f === 'anticipo' ? 'Anticipo' : 'Wompi' }}
        </button>
      </div>
      <div class="chips">
        <button v-for="f in ['todos','pagada','parcial','pendiente']" :key="f"
          class="chip" :class="{ 'chip--on': filtroEstado === f }"
          @click="filtroEstado = f">
          {{ f === 'todos' ? 'Todos' : estadoLabel[f] }}
        </button>
      </div>
    </div>

    <div class="workspace">
      <section class="list-wrap">
        <p v-if="!loading && !facturas.length" class="empty">Sin resultados.</p>

        <table class="table">
          <thead>
            <tr>
              <th>Referencia</th>
              <th>Cliente</th>
              <th>Empleado</th>
              <th>Fecha</th>
              <th>Anticipo</th>
              <th>Total</th>
              <th>Saldo pendiente</th>
              <th>Estado</th>
              <th>Tipo</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading"><td colspan="9" class="table-loading">Cargando...</td></tr>
            <tr v-for="f in facturas" :key="f.id_factura" class="table__row" :class="{ 'table__row--selected': isSelected(f) }" @click="selectFactura(f)">
              <td>
                <div class="td-ref">F-{{ f.id_factura }}</div>
                <div class="td-muted">{{ refLabel(f) }}</div>
              </td>
              <td class="td-bold">{{ clienteLabel(f) }}</td>
              <td class="td-muted">{{ empleadoLabel(f) }}</td>
              <td class="td-muted">{{ f.fecha }}</td>
              <td class="td-muted">{{ fmtCOP(f.anticipo) }}</td>
              <td class="td-bold">{{ fmtCOP(f.total) }}</td>
              <td class="td-balance" :class="{ 'td-balance--due': moneyValue(f.saldo_pendiente) > 0 }">{{ fmtCOP(f.saldo_pendiente) }}</td>
              <td><span class="badge" :class="'badge--' + f.estado">{{ estadoLabel[f.estado] }}</span></td>
              <td>
                <span class="badge" :class="'badge--tipo-' + f.tipo">{{ tipoLabel[f.tipo] }}</span>
                <span v-if="f.reserva_id" class="badge badge--wompi">Wompi</span>
              </td>
            </tr>
          </tbody>
        </table>

        <div class="card-list">
          <div v-if="loading" class="empty">Cargando...</div>
          <div v-for="f in facturas" :key="f.id_factura" class="fac-card" :class="{ 'fac-card--selected': isSelected(f) }" @click="selectFactura(f)">
            <div class="fac-card__top">
              <div class="fac-card__info">
                <div class="fac-card__name">F-{{ f.id_factura }} · {{ clienteLabel(f) }}</div>
                <div class="fac-card__meta">{{ refLabel(f) }} · {{ f.fecha }}</div>
              </div>
              <div class="fac-card__right">
                <div class="fac-card__total">{{ fmtCOP(f.total) }}</div>
                <span class="badge" :class="'badge--' + f.estado">{{ estadoLabel[f.estado] }}</span>
              </div>
            </div>
            <div class="fac-card__svcs">
              <span>{{ empleadoLabel(f) }}</span>
              <span v-if="moneyValue(f.saldo_pendiente) > 0" class="saldo-chip">Saldo {{ fmtCOP(f.saldo_pendiente) }}</span>
            </div>
          </div>
        </div>
      </section>

      <aside class="detail-panel">
        <div v-if="!selected" class="detail-empty">
          <div class="detail-empty__icon">
            <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16v16H4z"/><path d="M8 8h8M8 12h8M8 16h5"/></svg>
          </div>
          <p>Seleccione una factura para visualizar su informacion.</p>
        </div>

        <template v-else>
          <div class="detail-head">
            <div>
              <div class="sheet__id">F-{{ selected.id_factura }}</div>
              <div class="sheet__name">{{ clienteLabel(selected) }}</div>
              <div class="sheet__sub">{{ refLabel(selected) }} · {{ selected.fecha }}</div>
            </div>
            <div class="detail-head__badges">
              <span class="badge" :class="'badge--' + selected.estado">{{ estadoLabel[selected.estado] }}</span>
              <span v-if="selected.reserva_id" class="badge badge--wompi">Wompi</span>
            </div>
          </div>

          <p v-if="detail.loading" class="detail-loading">Cargando detalle...</p>
          <p v-else-if="detail.error" class="form-error">{{ detail.error }}</p>

          <template v-else>
            <div class="section-lbl">Informacion general</div>
            <div class="fields">
              <div class="field-row"><span class="field-lbl">Numero de factura</span><span class="field-val">F-{{ selected.id_factura }}</span></div>
              <div class="field-row"><span class="field-lbl">Cliente</span><span class="field-val">{{ clienteLabel(selected) }}</span></div>
              <div class="field-row"><span class="field-lbl">Empleado</span><span class="field-val">{{ empleadoSeleccionado }}</span></div>
              <div class="field-row"><span class="field-lbl">Fecha</span><span class="field-val">{{ selected.fecha }}</span></div>
              <div class="field-row"><span class="field-lbl">Estado</span><span class="badge" :class="'badge--' + selected.estado">{{ estadoLabel[selected.estado] }}</span></div>
            </div>

            <div class="section-lbl">Servicios</div>
            <div v-if="detail.servicios.length" class="svc-list">
              <div v-for="s in detail.servicios" :key="`${s.id}-${s.nombre}`" class="svc-row">
                <span class="svc-row__name">{{ s.nombre }}</span>
                <span class="svc-row__price">{{ fmtCOP(s.precio) }}</span>
              </div>
            </div>
            <p v-else class="mini-empty">No hay servicios asociados disponibles.</p>

            <div class="section-lbl">Resumen economico</div>
            <div class="invoice-box">
              <div class="invoice-row"><span>Subtotal</span><span>{{ fmtCOP(subtotalSeleccionado) }}</span></div>
              <div class="invoice-row"><span>Anticipo</span><span class="paid">{{ fmtCOP(selected.anticipo) }}</span></div>
              <div class="invoice-row"><span>Total</span><span>{{ fmtCOP(selected.total) }}</span></div>
              <div class="invoice-divider"></div>
              <div class="invoice-total">
                <span>Saldo pendiente</span>
                <span class="invoice-total__amount" :class="{ 'invoice-total__amount--paid': moneyValue(selected.saldo_pendiente) === 0 }">{{ fmtCOP(selected.saldo_pendiente) }}</span>
              </div>
            </div>

            <div class="section-lbl">Pagos realizados</div>
            <div v-if="detail.pagos.length" class="payment-list">
              <div v-for="p in detail.pagos" :key="p.id_pago" class="payment-row">
                <div>
                  <div class="payment-row__method">{{ metodoLabel[p.metodo] || p.metodo }}</div>
                  <div class="payment-row__meta">{{ p.fecha }}<span v-if="p.referencia"> · {{ p.referencia }}</span></div>
                </div>
                <strong>{{ fmtCOP(p.monto) }}</strong>
              </div>
            </div>
            <p v-else class="mini-empty">No hay pagos registrados para esta factura.</p>
          </template>

          <div class="detail-actions">
            <button class="cta-btn" :disabled="!['pendiente', 'parcial'].includes(selected.estado) || moneyValue(selected.saldo_pendiente) <= 0 || detail.loading" @click="openPaymentModal">Registrar pago</button>
            <button class="sec-btn" @click="openFullDetail">Ver detalle completo</button>
            <button class="sec-btn" @click="printInvoice">Imprimir factura</button>
          </div>
        </template>
      </aside>
    </div>

    <Transition name="scrim">
      <div v-if="paymentOpen || fullDetailOpen" class="scrim" @click="paymentOpen ? closePaymentModal() : (fullDetailOpen = false)"></div>
    </Transition>

    <Transition name="modal">
      <div v-if="paymentOpen" class="modal">
        <div class="modal__head">
          <div>
            <div class="form-title">Registrar pago</div>
            <p class="modal__sub">F-{{ selected.id_factura }} · Saldo {{ fmtCOP(selected.saldo_pendiente) }}</p>
          </div>
          <button class="sheet__close" @click="closePaymentModal">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
          </button>
        </div>

        <div class="form">
          <div class="form-group">
            <label class="form-label">Metodo de pago</label>
            <select v-model="paymentDraft.metodo" class="form-select">
              <option value="efectivo">Efectivo</option>
              <option value="transferencia">Transferencia</option>
              <option value="tarjeta">Tarjeta</option>
              <option value="wompi">Wompi</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Monto</label>
            <input v-model="paymentDraft.monto" class="form-input" type="number" min="1" :max="selected.saldo_pendiente" placeholder="0" />
          </div>
          <div class="form-group">
            <label class="form-label">Referencia opcional</label>
            <input v-model="paymentDraft.referencia" class="form-input" type="text" placeholder="Transferencia, voucher o nota" />
          </div>
        </div>

        <p v-if="paymentError" class="form-error">{{ paymentError }}</p>
        <div class="modal__actions">
          <button class="cta-btn" :disabled="paymentSaving" @click="savePayment">{{ paymentSaving ? 'Guardando...' : 'Guardar pago' }}</button>
          <button class="sec-btn" @click="closePaymentModal">Cancelar</button>
        </div>
      </div>
    </Transition>

    <Transition name="modal">
      <div v-if="fullDetailOpen" class="modal modal--wide">
        <div class="modal__head">
          <div>
            <div class="form-title">Detalle completo</div>
            <p class="modal__sub">Factura F-{{ selected.id_factura }}</p>
          </div>
          <button class="sheet__close" @click="fullDetailOpen = false">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
          </button>
        </div>

        <div class="full-grid">
          <div class="field-row"><span class="field-lbl">Factura</span><span class="field-val">F-{{ selected.id_factura }}</span></div>
          <div class="field-row"><span class="field-lbl">Referencia</span><span class="field-val">{{ refLabel(selected) }}</span></div>
          <div class="field-row"><span class="field-lbl">Tipo</span><span class="field-val">{{ tipoLabel[selected.tipo] }}</span></div>
          <div class="field-row"><span class="field-lbl">Origen</span><span class="field-val">{{ selected.reserva_id ? 'Wompi / Reserva web' : 'Caja' }}</span></div>
          <div class="field-row"><span class="field-lbl">Generada por</span><span class="field-val">{{ selected.generada_por_nombre || '-' }}</span></div>
          <div class="field-row"><span class="field-lbl">Modificada por</span><span class="field-val">{{ selected.confirmada_por_nombre || '-' }}</span></div>
          <div class="field-row"><span class="field-lbl">Creada</span><span class="field-val">{{ selected.created_at || '-' }}</span></div>
          <div class="field-row"><span class="field-lbl">Actualizada</span><span class="field-val">{{ selected.updated_at || '-' }}</span></div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.fac {
  flex: 1;
  display: flex;
  flex-direction: column;
  font-family: Inter, system-ui, sans-serif;
  background: #FBF6F4;
  min-height: 100vh;
  position: relative;
}

.topbar { display: flex; align-items: center; justify-content: space-between; padding: 22px 20px 14px; }
.topbar__title { margin: 0; font-family: Fraunces, Georgia, serif; font-size: 22px; font-weight: 500; color: #1A1714; letter-spacing: -.01em; }

.stats { display: grid; grid-template-columns: repeat(2,1fr); gap: 10px; padding: 0 20px 16px; }
.stat-card { background: #fff; border-radius: 14px; border: 1px solid rgba(26,23,20,.08); padding: 14px 16px; }
.stat-card--rose { border-color: rgba(176,69,95,.18); background: #fff5f7; }
.stat-card--warn { border-color: rgba(217,119,6,.18); background: #fffbf0; }
.stat-card--wompi { border-color: rgba(0,168,150,.18); background: #f0fdfa; }
.stat-card__val { font-family: Fraunces, Georgia, serif; font-size: 22px; font-weight: 600; color: #1A1714; line-height: 1.1; }
.stat-card--rose .stat-card__val { color: #B0455F; }
.stat-card--warn .stat-card__val { color: #b45309; }
.stat-card--wompi .stat-card__val { color: #0d7c6e; font-size: 16px; }
.stat-card__lbl { font-size: 12px; color: #a59a8d; margin-top: 3px; }

.toolbar { padding: 0 20px 12px; display: flex; flex-direction: column; gap: 10px; }
.search {
  display: flex; align-items: center; gap: 10px; height: 46px; padding: 0 14px;
  border-radius: 13px; background: #fff; border: 1.5px solid rgba(26,23,20,.12); transition: border-color .2s;
}
.search:focus-within { border-color: #B0455F; }
.search__input { flex: 1; border: none; background: transparent; font-size: 14px; font-family: inherit; color: #1A1714; min-width: 0; }
.search__input::placeholder { color: #b7ab9d; }
.search__input:focus { outline: none; }
.search__clear { flex: none; display: flex; align-items: center; border: none; background: none; cursor: pointer; padding: 2px; }
.chips { display: flex; gap: 7px; flex-wrap: wrap; }
.chip {
  height: 32px; padding: 0 14px; border-radius: 20px; border: 1.5px solid rgba(26,23,20,.12);
  background: #fff; font-size: 12.5px; font-weight: 500; color: #8a7f72; cursor: pointer; transition: all .15s;
}
.chip--on { background: #B0455F; border-color: #B0455F; color: #fff; }
.chip--wompi.chip--on { background: #0d7c6e; border-color: #0d7c6e; }

.workspace { flex: 1; display: grid; gap: 16px; padding: 0 20px 28px; align-items: start; }
.list-wrap { min-width: 0; }
.empty { text-align: center; color: #a59a8d; font-size: 14px; padding: 40px 0; }
.table { display: none; }

.card-list { display: flex; flex-direction: column; gap: 10px; }
.fac-card {
  background: #fff; border-radius: 14px; border: 1px solid rgba(26,23,20,.08);
  padding: 14px 16px; cursor: pointer; transition: box-shadow .2s, border-color .2s, background .2s;
}
.fac-card:hover { box-shadow: 0 4px 16px rgba(20,12,4,.10); }
.fac-card--selected { border-color: rgba(176,69,95,.35); background: #fff8f9; }
.fac-card__top { display: flex; align-items: flex-start; gap: 10px; }
.fac-card__info { flex: 1; min-width: 0; }
.fac-card__name { font-size: 14px; font-weight: 600; color: #1A1714; }
.fac-card__meta { font-size: 12px; color: #a59a8d; margin-top: 1px; }
.fac-card__right { display: flex; flex-direction: column; align-items: flex-end; gap: 5px; }
.fac-card__total { font-family: Fraunces, Georgia, serif; font-size: 15px; font-weight: 600; color: #1A1714; }
.fac-card__svcs { display: flex; justify-content: space-between; gap: 10px; font-size: 12px; color: #8a7f72; margin-top: 8px; }

.td-muted { color: #8a7f72 !important; font-size: 13px; }
.td-bold { font-size: 13.5px; font-weight: 600; color: #1A1714; }
.td-ref { font-size: 12px; color: #1A1714; font-family: 'SF Mono', monospace; font-weight: 600; }
.td-balance { font-size: 13px; font-weight: 600; color: #15803d; }
.td-balance--due { color: #b45309; }
.table-loading { padding: 32px; text-align: center; color: #a59a8d; }

.badge { display: inline-block; font-size: 10px; font-weight: 600; padding: 2px 9px; border-radius: 20px; white-space: nowrap; margin-right: 4px; }
.badge--pagada { background: rgba(22,163,74,.12); color: #15803d; }
.badge--pendiente { background: rgba(220,38,38,.12); color: #dc2626; }
.badge--parcial { background: rgba(217,119,6,.12); color: #b45309; }
.badge--anulada, .badge--cancelada { background: rgba(26,23,20,.08); color: #8a7f72; }
.badge--tipo-servicio { background: rgba(99,102,241,.10); color: #4338ca; }
.badge--tipo-anticipo { background: rgba(14,165,233,.10); color: #0369a1; }
.badge--wompi { background: rgba(0,168,150,.12); color: #0d7c6e; }
.saldo-chip { color: #b45309; font-weight: 600; white-space: nowrap; }

.detail-panel {
  background: #fff;
  border: 1px solid rgba(26,23,20,.08);
  border-radius: 16px;
  min-height: 420px;
  padding: 18px;
  position: sticky;
  top: 16px;
}
.detail-empty { min-height: 380px; display: grid; place-items: center; align-content: center; gap: 12px; text-align: center; color: #a59a8d; font-size: 14px; }
.detail-empty__icon {
  width: 68px; height: 68px; display: grid; place-items: center; border-radius: 18px;
  background: rgba(176,69,95,.08); border: 1px solid rgba(176,69,95,.14);
}
.detail-head { display: flex; justify-content: space-between; gap: 14px; margin-bottom: 18px; }
.detail-head__badges { flex: none; display: flex; flex-direction: column; align-items: flex-end; gap: 5px; }
.detail-loading { font-size: 13px; color: #a59a8d; padding: 18px 0; }
.sheet__id { font-size: 11px; color: #a59a8d; font-family: 'SF Mono', monospace; margin-bottom: 2px; }
.sheet__name { font-family: Fraunces, Georgia, serif; font-size: 19px; font-weight: 500; color: #1A1714; }
.sheet__sub { font-size: 12px; color: #8a7f72; margin-top: 2px; }
.section-lbl { font-size: 11px; font-weight: 600; letter-spacing: .05em; text-transform: uppercase; color: #a59a8d; margin: 18px 0 10px; }

.fields { display: flex; flex-direction: column; }
.field-row { display: flex; justify-content: space-between; align-items: center; gap: 16px; padding: 9px 0; border-bottom: 1px solid rgba(26,23,20,.06); }
.field-lbl { font-size: 12px; color: #a59a8d; }
.field-val { font-size: 13.5px; font-weight: 500; color: #1A1714; text-align: right; overflow-wrap: anywhere; }

.svc-list { display: flex; flex-direction: column; gap: 8px; }
.svc-row { display: flex; align-items: center; justify-content: space-between; gap: 12px; font-size: 13.5px; color: #1A1714; padding: 10px 0; border-bottom: 1px solid rgba(26,23,20,.06); }
.svc-row__name { font-weight: 500; }
.svc-row__price { color: #8a7f72; font-weight: 600; white-space: nowrap; }
.mini-empty { margin: 0; font-size: 13px; color: #a59a8d; }

.invoice-box { border: 1px solid rgba(26,23,20,.08); border-radius: 14px; padding: 12px 14px; background: #FBF6F4; }
.invoice-row { display: flex; justify-content: space-between; gap: 12px; font-size: 13px; color: #6f665d; padding: 6px 0; }
.invoice-row span:last-child { color: #1A1714; font-weight: 600; }
.invoice-row .paid { color: #15803d; }
.invoice-divider { height: 1px; background: rgba(26,23,20,.08); margin: 8px 0; }
.invoice-total { display: flex; justify-content: space-between; gap: 12px; align-items: center; font-size: 13.5px; color: #1A1714; font-weight: 600; }
.invoice-total__amount { font-family: Fraunces, Georgia, serif; font-size: 21px; font-weight: 600; color: #B0455F; }
.invoice-total__amount--paid { color: #15803d; }

.payment-list { display: flex; flex-direction: column; gap: 8px; }
.payment-row { display: flex; justify-content: space-between; gap: 12px; align-items: center; padding: 10px 0; border-bottom: 1px solid rgba(26,23,20,.06); }
.payment-row__method { font-size: 13.5px; font-weight: 600; color: #1A1714; }
.payment-row__meta { font-size: 12px; color: #a59a8d; margin-top: 2px; }
.payment-row strong { font-size: 13.5px; color: #15803d; white-space: nowrap; }

.detail-actions { display: flex; flex-direction: column; gap: 10px; margin-top: 20px; }
.cta-btn {
  display: flex; align-items: center; justify-content: center; width: 100%; height: 48px;
  border-radius: 13px; border: none; background: #B0455F; color: #FBF6F4;
  font-family: Fraunces, Georgia, serif; font-size: 15px; font-weight: 500; cursor: pointer; transition: filter .2s;
}
.cta-btn:hover { filter: brightness(1.07); }
.cta-btn:disabled { opacity: .55; cursor: not-allowed; filter: none; }
.sec-btn {
  display: flex; align-items: center; justify-content: center; width: 100%; height: 44px;
  border-radius: 13px; border: 1.5px solid rgba(26,23,20,.14); background: transparent;
  color: #1A1714; font-size: 13.5px; font-weight: 500; font-family: inherit; cursor: pointer; transition: background .15s;
}
.sec-btn:hover { background: rgba(26,23,20,.04); }

.form-title { font-family: Fraunces, Georgia, serif; font-size: 18px; font-weight: 500; color: #1A1714; margin-bottom: 3px; }
.form { display: flex; flex-direction: column; gap: 14px; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 12px; font-weight: 600; color: #8a7f72; text-transform: uppercase; letter-spacing: .04em; }
.form-input, .form-select {
  height: 42px; padding: 0 12px; border-radius: 10px;
  border: 1.5px solid rgba(26,23,20,.14); background: #fff;
  font-size: 14px; font-family: inherit; color: #1A1714; outline: none; transition: border-color .18s;
  width: 100%; box-sizing: border-box;
}
.form-input:focus, .form-select:focus { border-color: #B0455F; }
.form-error { color: #dc2626; font-size: 12.5px; margin: 10px 0 0; }

.scrim { position: fixed; inset: 0; z-index: 30; background: rgba(26,23,20,.28); }
.modal {
  position: fixed; left: 50%; top: 50%; transform: translate(-50%, -50%); z-index: 40;
  width: min(430px, calc(100vw - 36px)); max-height: calc(100vh - 44px); overflow-y: auto;
  background: #FBF6F4; border-radius: 18px; border: 1px solid rgba(26,23,20,.08);
  box-shadow: 0 18px 50px rgba(20,12,4,.18); padding: 18px;
}
.modal--wide { width: min(620px, calc(100vw - 36px)); }
.modal__head { display: flex; justify-content: space-between; align-items: flex-start; gap: 14px; margin-bottom: 16px; }
.modal__sub { margin: 0; font-size: 12.5px; color: #8a7f72; }
.modal__actions { display: flex; flex-direction: column; gap: 10px; margin-top: 18px; }
.sheet__close {
  flex: none; width: 32px; height: 32px; border-radius: 9px;
  border: 1px solid rgba(26,23,20,.1); background: #fff; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
}
.full-grid { display: grid; gap: 0; }

.scrim-enter-active, .scrim-leave-active { transition: opacity .22s ease; }
.scrim-enter-from, .scrim-leave-to { opacity: 0; }
.modal-enter-active, .modal-leave-active { transition: opacity .2s ease, transform .2s ease; }
.modal-enter-from, .modal-leave-to { opacity: 0; transform: translate(-50%, -48%); }

@media (min-width: 1024px) {
  .topbar { padding: 24px 28px 18px; }
  .topbar__title { font-size: 26px; }
  .stats { padding: 0 28px 18px; grid-template-columns: repeat(4,180px); }
  .stats--empleado { grid-template-columns: repeat(2, 180px); }
  .toolbar { padding: 0 28px 14px; flex-direction: row; align-items: center; flex-wrap: wrap; gap: 10px; }
  .search { max-width: 320px; }
  .workspace { grid-template-columns: minmax(0, 1fr) 390px; padding: 0 28px 32px; }
  .card-list { display: none; }

  .table {
    display: table; width: 100%; border-collapse: separate; border-spacing: 0;
    background: #fff; border-radius: 16px; border: 1px solid rgba(26,23,20,.08); overflow: hidden;
  }
  .table thead th {
    text-align: left; padding: 12px 12px;
    font-size: 11px; font-weight: 600; letter-spacing: .04em; text-transform: uppercase;
    color: #a59a8d; background: #FBF6F4; border-bottom: 1px solid rgba(26,23,20,.07);
  }
  .table__row { cursor: pointer; transition: background .15s; }
  .table__row:hover td { background: #fdf7f5; }
  .table__row--selected td { background: #fff1f4; }
  .table__row td { padding: 11px 12px; border-bottom: 1px solid rgba(26,23,20,.06); vertical-align: middle; }
  .table__row:last-child td { border-bottom: none; }
}
</style>
