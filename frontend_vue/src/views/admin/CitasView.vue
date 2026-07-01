<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useAlertDialog } from '@/composables/useAlertDialog'
import {
  getDashboardKanban, getDashboardAlertas,
  getClientes, getEmpleados, getServicios,
  getDetallesCitas,
  createCita, updateCita, editarDinamicaCita, deleteCita,
  crearPago, fmtCOP,
} from '@/api/admin'

// ─── estado principal ──────────────────────────────────────────────────────────
const loading  = ref(true)
const kanban   = ref({ pendientes: [], confirmadas: [], completadas: [] })
const alertas  = ref({ productos_stock_bajo: [], citas_retrasadas: [] })
const { alertDialog, confirmDialog } = useAlertDialog()
const search = ref('')
const filtroEstado = ref('')
const filtroFecha = ref(localDate())

async function showStockServiceAlert(changes = []) {
  if (!changes?.length) return
  const inactivos = changes.filter(c => c.estado_nuevo === 'inactivo')
  const reactivados = changes.filter(c => c.estado_nuevo === 'activo')
  const list = changes.map(c => c.nombre).join(', ')
  await alertDialog({
    title: inactivos.length ? 'Servicio inactivado' : 'Servicio actualizado',
    message: inactivos.length
      ? `${list} quedo inactivo por stock bajo o agotado.`
      : `${reactivados.map(c => c.nombre).join(', ')} volvio a estar activo por recuperacion de stock.`,
    variant: inactivos.length ? 'warning' : 'success',
  })
}

function localDate(date = new Date()) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function anticipo30(total) {
  return Math.round(Number(total || 0) * 0.3)
}

async function loadKanban() {
  try {
    const [k, a] = await Promise.all([getDashboardKanban({ fecha: filtroFecha.value }), getDashboardAlertas()])
    kanban.value  = {
      pendientes:  k.pendientes || [],
      confirmadas: k.confirmadas || [],
      completadas: k.completadas || k.finalizadas || [],
    }
    alertas.value = a
  } finally { loading.value = false }
}
onMounted(loadKanban)

watch(filtroFecha, async () => {
  loading.value = true
  await loadKanban()
})

function aplicarFiltros(lista, bucket) {
  if (filtroEstado.value && filtroEstado.value !== bucket) return []
  const q = search.value.trim().toLowerCase()
  return lista.filter(c => {
    const coincideBusqueda =
      !q ||
      [
        c.cliente,
        c.cliente_documento,
        c.cli_documento,
        c.cliente_telefono,
        c.empleado,
        c.servicio,
        c.estado,
        c.factura_estado,
      ]
        .some(v => String(v || '').toLowerCase().includes(q))

    return coincideBusqueda
  })
}

// ─── nueva cita ───────────────────────────────────────────────────────────────
const newOpen   = ref(false)
const newSaving = ref(false)
const newError  = ref('')
const newDraft  = ref({ cliente_id: '', empleado_id: '', fecha: '', hora: '', estado: 'pendiente', anticipo: 0 })
const newClients = ref([])
const newEmpls   = ref([])
const newServices = ref([])
const newServiceIds = ref(new Set())
const newClientSearch = ref('')
const newClientsLoading = ref(false)
const newEmployeesLoading = ref(false)
const newClientFilter = ref('todos')

function normalizeSearch(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
}

function clientSearchText(cliente) {
  return normalizeSearch([
    cliente.nombre,
    cliente.apellido,
    cliente.documento,
    cliente.telefono,
    cliente.direccion,
    cliente.username,
    cliente.email,
  ].join(' '))
}

function clientFieldText(cliente, filter) {
  if (filter === 'nombre') return normalizeSearch([cliente.nombre, cliente.apellido].join(' '))
  if (filter === 'documento') return normalizeSearch(cliente.documento)
  if (filter === 'telefono') return normalizeSearch(cliente.telefono)
  return clientSearchText(cliente)
}

const filteredNewClients = computed(() => {
  const term = normalizeSearch(newClientSearch.value.trim())
  if (!term) return newClients.value
  return newClients.value.filter(c => clientFieldText(c, newClientFilter.value).includes(term))
})

const newSelectedClient = computed(() =>
  newClients.value.find(c => c.id_cliente === Number(newDraft.value.cliente_id))
)

const newSelectedServices = computed(() =>
  newServices.value.filter(s => newServiceIds.value.has(s.id_servicio))
)
const newTotal = computed(() =>
  newSelectedServices.value.reduce((sum, s) => sum + Number(s.precio || 0), 0)
)
const newAnticipo = computed(() => anticipo30(newTotal.value))
const newSaldo = computed(() => Math.max(newTotal.value - newAnticipo.value, 0))

async function openNewCita() {
  newDraft.value = { cliente_id: '', empleado_id: '', fecha: filtroFecha.value || localDate(), hora: '', estado: 'pendiente', anticipo: 0 }
  newServiceIds.value = new Set()
  newClientSearch.value = ''
  newClientFilter.value = 'todos'
  newError.value = ''
  newOpen.value  = true
  newClientsLoading.value = true
  newEmployeesLoading.value = true
  try {
    const [c, e, s] = await Promise.all([getClientes(), getEmpleados(), getServicios({ estado: 'activo' })])
    newClients.value = c; newEmpls.value = e; newServices.value = s
  } finally {
    newClientsLoading.value = false
    newEmployeesLoading.value = false
  }
}
function closeNew() { newOpen.value = false }

function toggleNewService(id) {
  const next = new Set(newServiceIds.value)
  next.has(id) ? next.delete(id) : next.add(id)
  newServiceIds.value = next
}

function selectNewClient(id) {
  newDraft.value.cliente_id = id
}

async function saveNewCita() {
  newError.value = ''
  const d = newDraft.value
  if (!d.cliente_id || !d.empleado_id || !d.fecha || !d.hora) {
    newError.value = 'Todos los campos son requeridos'; return
  }
  if (!newServiceIds.value.size) {
    newError.value = 'Selecciona al menos un servicio'; return
  }
  if (newAnticipo.value < 0 || newAnticipo.value > newTotal.value) {
    newError.value = 'El anticipo no puede ser negativo ni superar el total'; return
  }
  newSaving.value = true
  try {
    await createCita({
      ...d,
      cliente_id: Number(d.cliente_id),
      empleado_id: Number(d.empleado_id),
      anticipo: newAnticipo.value,
      servicios: Array.from(newServiceIds.value),
    })
    closeNew(); loading.value = true; await loadKanban()
  } catch (e) { newError.value = e.response?.data?.message || 'Error al crear la cita' }
  finally { newSaving.value = false }
}

// ─── detalle / drawer ─────────────────────────────────────────────────────────
const open    = ref(false)
const selCard = ref(null)
const selected = computed(() => selCard.value || {})
const facturaPagada = computed(() => selected.value.facEstado === 'pagada')
const canConfirm = computed(() => selected.value.estado === 'pendiente')
const canComplete = computed(() => selected.value.estado === 'confirmada')
const canCancel = computed(() => ['pendiente', 'confirmada'].includes(selected.value.estado))
const canEditServices = computed(() =>
  ['pendiente', 'confirmada'].includes(selected.value.estado) && !facturaPagada.value
)
const canChargeBalance = computed(() =>
  selected.value.estado === 'completada' &&
  selected.value.facturaId &&
  Number(selected.value.saldo || 0) > 0
)
const hasFooterActions = computed(() =>
  canConfirm.value || canComplete.value || canCancel.value || canEditServices.value || canChargeBalance.value
)

function openCard(card) { selCard.value = card; open.value = true; resetDrawerForms() }
function closePanel() { open.value = false; resetDrawerForms() }

function resetDrawerForms() {
  cobrarOpen.value = false
  cambiarEmpleadoOpen.value = false
  editarServiciosOpen.value = false
  editServicesError.value = ''
  cobrarForm.value = { metodo: 'efectivo', monto: '', fecha: new Date().toISOString().slice(0,10) }
  drawerError.value = ''
}

const drawerError = ref('')

async function refreshSelectedCard() {
  loading.value = true
  await loadKanban()
  if (!selCard.value?.id) return
  const cards = [...kanban.value.pendientes, ...kanban.value.confirmadas, ...kanban.value.completadas].map(mapCard)
  const updated = cards.find(c => c.id === selCard.value.id)
  if (updated) selCard.value = updated
}

// ─── completar cita ───────────────────────────────────────────────────────────
async function confirmarCita() {
  if (!selCard.value?.id) return
  const ok = await confirmDialog({
    title: 'Confirmar cita',
    message: 'Cambiar esta cita a confirmada?',
    variant: 'success',
    confirmText: 'Confirmar',
  })
  if (!ok) return
  completing.value = true
  drawerError.value = ''
  try {
    await updateCita(selCard.value.id, { estado: 'confirmada' })
    closePanel(); loading.value = true; await loadKanban()
  } catch (e) { drawerError.value = e.response?.data?.message || 'Error al confirmar' }
  finally { completing.value = false }
}

const completing = ref(false)

async function completarCita() {
  if (!selCard.value?.id) return
  const ok = await confirmDialog({
    title: 'Cita terminada',
    message: 'Marcar esta cita como completada?',
    variant: 'success',
    confirmText: 'Cita terminada',
  })
  if (!ok) return
  completing.value = true
  drawerError.value = ''
  try {
    const cita = await updateCita(selCard.value.id, { estado: 'completada' })
    closePanel(); loading.value = true; await loadKanban()
    await showStockServiceAlert(cita.servicios_actualizados)
  } catch (e) { drawerError.value = e.response?.data?.message || 'Error al completar' }
  finally { completing.value = false }
}

// ─── cancelar cita ────────────────────────────────────────────────────────────
async function cancelarCita() {
  if (!selCard.value?.id) return
  const ok = await confirmDialog({
    title: 'Cancelar cita',
    message: 'Cancelar esta cita?',
    variant: 'danger',
    confirmText: 'Cancelar cita',
  })
  if (!ok) return
  try {
    await deleteCita(selCard.value.id)
    closePanel(); loading.value = true; await loadKanban()
  } catch (e) { drawerError.value = e.response?.data?.message || 'Error al cancelar' }
}

// ─── cambiar estilista ────────────────────────────────────────────────────────
const cambiarEmpleadoOpen = ref(false)
const empleados           = ref([])
const nuevoEmpleadoId     = ref('')
const cambiandoEmpleado   = ref(false)

async function abrirCambioEstilista() {
  if (!empleados.value.length) empleados.value = await getEmpleados()
  nuevoEmpleadoId.value = String(selected.value.empleadoId || '')
  cambiarEmpleadoOpen.value = true
}

async function guardarEstilista() {
  if (!nuevoEmpleadoId.value) return
  cambiandoEmpleado.value = true
  drawerError.value = ''
  try {
    await editarDinamicaCita(selCard.value.id, { empleado_id: Number(nuevoEmpleadoId.value) })
    cambiarEmpleadoOpen.value = false
    loading.value = true; await loadKanban()
    // reabrir con datos nuevos
    const col = [...kanban.value.pendientes, ...kanban.value.confirmadas, ...kanban.value.completadas]
    const updated = col.find(c => c.id === selCard.value.id)
    if (updated) selCard.value = updated
  } catch (e) { drawerError.value = e.response?.data?.message || 'Error al cambiar estilista' }
  finally { cambiandoEmpleado.value = false }
}

// ─── cobrar saldo ─────────────────────────────────────────────────────────────
const editarServiciosOpen = ref(false)
const editServicesLoading = ref(false)
const editServicesSaving = ref(false)
const editServicesError = ref('')
const editServices = ref([])
const editServiceIds = ref(new Set())

const editSelectedServices = computed(() =>
  editServices.value.filter(s => editServiceIds.value.has(s.id_servicio))
)
const editTotal = computed(() =>
  editSelectedServices.value.reduce((sum, s) => sum + Number(s.precio || 0), 0)
)
const editAnticipo = computed(() => anticipo30(editTotal.value))
const editSaldo = computed(() => Math.max(editTotal.value - editAnticipo.value, 0))

async function abrirEditarServicios() {
  if (!canEditServices.value || !selCard.value?.id) return
  editarServiciosOpen.value = true
  editServicesLoading.value = true
  editServicesError.value = ''
  try {
    const [servicios, detalles] = await Promise.all([
      getServicios({ estado: 'activo' }),
      getDetallesCitas({ cita_id: selCard.value.id }),
    ])
    editServices.value = servicios
    editServiceIds.value = new Set((detalles || []).map(d => d.servicio_id))
  } catch (e) {
    editServicesError.value = e.response?.data?.message || 'No se pudieron cargar los servicios'
  } finally {
    editServicesLoading.value = false
  }
}

function toggleEditService(id) {
  const next = new Set(editServiceIds.value)
  next.has(id) ? next.delete(id) : next.add(id)
  editServiceIds.value = next
}

function cerrarEditarServicios() {
  editarServiciosOpen.value = false
  editServicesError.value = ''
}

async function guardarServiciosCita() {
  if (!selCard.value?.id) return
  if (!editServiceIds.value.size) {
    editServicesError.value = 'Selecciona al menos un servicio'
    return
  }
  editServicesSaving.value = true
  editServicesError.value = ''
  try {
    await editarDinamicaCita(selCard.value.id, {
      servicios: Array.from(editServiceIds.value),
      anticipo: editAnticipo.value,
    })
    editarServiciosOpen.value = false
    await refreshSelectedCard()
  } catch (e) {
    editServicesError.value = e.response?.data?.message || 'Error al actualizar servicios'
  } finally {
    editServicesSaving.value = false
  }
}

const cobrarOpen    = ref(false)
const cobrarLoading = ref(false)
const cobrarForm    = ref({ metodo: 'efectivo', monto: '', fecha: new Date().toISOString().slice(0,10) })

function abrirCobro() {
  if (!canChargeBalance.value) return
  cobrarForm.value.monto = selected.value.saldo || ''
  cobrarOpen.value = true
}

async function cobrarSaldo() {
  const f = cobrarForm.value
  if (!f.monto || Number(f.monto) <= 0) { drawerError.value = 'Ingresa un monto válido'; return }
  if (!selected.value.facturaId)        { drawerError.value = 'Esta cita no tiene factura registrada'; return }
  cobrarLoading.value = true
  drawerError.value = ''
  try {
    await crearPago({
      factura_id: selected.value.facturaId,
      metodo:     f.metodo,
      monto:      Number(f.monto),
      fecha:      f.fecha,
      estado:     'completado',
    })
    cobrarOpen.value = false
    closePanel(); loading.value = true; await loadKanban()
  } catch (e) { drawerError.value = e.response?.data?.message || 'Error al registrar pago' }
  finally { cobrarLoading.value = false }
}

// ─── kanban columns ───────────────────────────────────────────────────────────
const initials = (str) => (str || '').split(' ').slice(0,2).map(w => w[0] || '').join('').toUpperCase() || '?'

const COLUMNS = computed(() => [
  {
    id: 'pend', name: 'Pendientes', dot: '#d97706',
    badgeBg: 'rgba(217,119,6,.12)', badgeColor: '#b06407', badge: 'Pendiente',
    cards: aplicarFiltros(kanban.value.pendientes, 'pendientes').map(mapCard),
  },
  {
    id: 'conf', name: 'Confirmadas', dot: '#B0455F',
    badgeBg: 'rgba(176,69,95,.10)', badgeColor: '#B0455F', badge: 'Confirmada',
    cards: aplicarFiltros(kanban.value.confirmadas, 'confirmadas').map(mapCard),
  },
  {
    id: 'comp', name: 'Terminadas', dot: '#16a34a',
    badgeBg: 'rgba(22,163,74,.12)', badgeColor: '#15803d', badge: 'Terminada',
    cards: aplicarFiltros(kanban.value.completadas, 'completadas').map(mapCard),
  },
])

function mapCard(c) {
  return {
    id:          c.id_cita,
    name:        c.cliente,
    initials:    initials(c.cliente),
    service:     c.servicio || '—',
    time:        (c.hora || '').slice(0,5),
    fecha:       c.fecha,
    stylist:     c.empleado,
    empleadoId:  c.empleado_id,
    clienteId:   c.cliente_id,
    documento:   c.cliente_documento,
    telefono:    c.cliente_telefono,
    facturaId:   c.factura_id,
    facEstado:   c.factura_estado,
    saldo:       c.saldo_pendiente,
    anticipo:    c.anticipo,
    total:       c.total,
    estado:      c.estado,
    delay:       c.retraso ? 1 : 0,
  }
}

const totalCitas = computed(() => COLUMNS.value.reduce((s, c) => s + c.cards.length, 0))

const hoy = computed(() => {
  const d = new Date(`${filtroFecha.value || localDate()}T12:00:00`)
  const dias  = ['dom','lun','mar','mié','jue','vie','sáb']
  const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic']
  return `${dias[d.getDay()]} ${d.getDate()} ${meses[d.getMonth()]}`
})

const activeColIdx = ref(0)

// ─── alertas strip (reales) ───────────────────────────────────────────────────
const stockBajo   = computed(() => alertas.value.productos_stock_bajo || [])
const retrasadas  = computed(() => alertas.value.citas_retrasadas || [])
</script>

<template>
  <div class="dash">

    <!-- TOPBAR -->
    <div class="topbar">
      <div class="topbar__left">
        <div class="topbar__date">Día · {{ hoy }}</div>
        <span class="topbar__badge">{{ totalCitas }} citas</span>
      </div>
      <button class="topbar__new" @click="openNewCita">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
        <span>Nueva cita</span>
      </button>
    </div>

    <div class="kanban-tools">
      <input
      v-model="search"
      class="kanban-search"
      placeholder="Buscar cliente, cedula, celular, servicio o empleado..."
      />
      <input
        v-model="filtroFecha"
        class="kanban-date"
        type="date"
      />

      <div class="kanban-chips">
        <button
          class="kanban-chip"
          :class="{ active: filtroEstado === '' }"
          @click="filtroEstado = ''"
          >
           Todas
        </button>

        <button
          class="kanban-chip"
          :class="{ active: filtroEstado === 'pendientes' }"
          @click="filtroEstado = 'pendientes'"
          >
            Pendientes
        </button>

        <button
          class="kanban-chip"
          :class="{ active: filtroEstado === 'confirmadas' }"
          @click="filtroEstado = 'confirmadas'"
          >
            Confirmadas
        </button>

        <button
          class="kanban-chip"
          :class="{ active: filtroEstado === 'completadas' }"
          @click="filtroEstado = 'completadas'"
          >
            Terminadas
        </button>

      </div>
    </div>

    <!-- ALERTS STRIP -->
    <div class="alerts">
      <div class="alert-item alert-item--border">
        <span class="alert-dot" :style="{ background: stockBajo.length ? '#B0455F' : '#16a34a' }"></span>
        <span class="alert-lbl">Stock bajo</span>
        <span class="alert-chip"
          :style="stockBajo.length
            ? { background:'rgba(176,69,95,.10)', color:'#B0455F' }
            : { background:'rgba(22,163,74,.12)', color:'#15803d' }">
          {{ stockBajo.length ? stockBajo.length + ' producto(s)' : 'OK' }}
        </span>
      </div>
      <div class="alert-item alert-item--border">
        <span class="alert-dot" :style="{ background: retrasadas.length ? '#d97706' : '#16a34a' }"></span>
        <span class="alert-lbl">Retrasadas</span>
        <span class="alert-chip"
          :style="retrasadas.length
            ? { background:'rgba(217,119,6,.12)', color:'#b06407' }
            : { background:'rgba(22,163,74,.12)', color:'#15803d' }">
          {{ retrasadas.length ? retrasadas.length + ' cita(s)' : 'Ninguna' }}
        </span>
      </div>
      <div class="alert-item">
        <span class="alert-lbl">Total hoy</span>
        <span class="alert-chip" style="background:rgba(26,23,20,.06);color:#6b6258">{{ totalCitas }} citas</span>
      </div>
    </div>

    <!-- COLUMN TABS (mobile) -->
    <div class="col-tabs scrl">
      <button
        v-for="(col, i) in COLUMNS" :key="col.id"
        class="col-tab" :class="{ 'col-tab--on': activeColIdx === i }"
        @click="activeColIdx = i"
      >
        <span class="col-tab__dot" :style="{ background: col.dot }"></span>
        {{ col.name }}
        <span class="col-tab__count">{{ col.cards.length }}</span>
      </button>
    </div>

    <!-- KANBAN -->
    <div class="board scrl">

      <!-- DESKTOP: 3 columnas -->
      <div class="board__grid">
        <div v-for="col in COLUMNS" :key="col.id" class="col">
          <div class="col__head">
            <span class="col__dot" :style="{ background: col.dot }"></span>
            <span class="col__name">{{ col.name }}</span>
            <span class="col__count">{{ col.cards.length }}</span>
          </div>
          <div class="col__cards">
            <p v-if="loading" class="col__empty">Cargando…</p>
            <p v-else-if="!col.cards.length" class="col__empty">Sin citas</p>
            <div v-for="card in col.cards" :key="card.id" class="card"
              :class="{ 'card--delay': card.delay > 0 }" @click="openCard(card)">
              <div class="card__top">
                <div class="card__avatar">{{ card.initials }}</div>
                <div class="card__info">
                  <div class="card__name">{{ card.name }}</div>
                  <div class="card__svc">{{ card.service }}</div>
                </div>
                <div class="card__more">···</div>
              </div>
              <div class="card__meta">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>
                {{ card.time }} · {{ card.stylist }}
              </div>
              <div class="card__foot">
                <span class="badge" :style="{ background: col.badgeBg, color: col.badgeColor }">{{ col.badge }}</span>
                <span v-if="card.delay > 0" class="delay-chip">
                  <span class="delay-chip__dot"></span>retrasada
                </span>
                <span v-if="card.saldo > 0" class="saldo-chip">Saldo {{ fmtCOP(card.saldo) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- MOBILE: columna activa -->
      <div class="board__mobile">
        <div v-for="(col, i) in COLUMNS" :key="col.id" class="mob-col" :class="{ 'mob-col--hidden': activeColIdx !== i }">
          <p v-if="loading" class="col__empty">Cargando…</p>
          <p v-else-if="!col.cards.length" class="col__empty" style="text-align:center;padding:32px 0;font-size:13px;color:#a59a8d">Sin citas</p>
          <div v-for="card in col.cards" :key="card.id" class="card"
            :class="{ 'card--delay': card.delay > 0 }" @click="openCard(card)">
            <div class="card__top">
              <div class="card__avatar">{{ card.initials }}</div>
              <div class="card__info">
                <div class="card__name">{{ card.name }}</div>
                <div class="card__svc">{{ card.service }}</div>
              </div>
            </div>
            <div class="card__meta">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>
              {{ card.time }} · {{ card.stylist }}
            </div>
            <div class="card__foot">
              <span class="badge" :style="{ background: col.badgeBg, color: col.badgeColor }">{{ col.badge }}</span>
              <span v-if="card.saldo > 0" class="saldo-chip">{{ fmtCOP(card.saldo) }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- SCRIM -->
    <Transition name="scrim">
      <div v-if="open || newOpen" class="scrim" @click="open ? closePanel() : closeNew()"></div>
    </Transition>

    <!-- ═══ DRAWER (desktop) ══════════════════════════════════════════════════ -->
    <Transition name="drawer">
      <div v-if="open" class="drawer">
        <div class="drawer__scroll scrl">

          <!-- header -->
          <div class="drawer__header">
            <div>
              <div class="drawer__cname">{{ selected.name }}</div>
              <div class="drawer__phone">{{ selected.fecha }} · {{ selected.time }}</div>
              <span class="state-badge" :class="`state-badge--${selected.estado}`">
                {{ selected.estado === 'pendiente' ? 'Pendiente' : selected.estado === 'confirmada' ? 'Confirmada' : 'Terminada' }}
              </span>
            </div>
            <button class="drawer__close" @click="closePanel">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
            </button>
          </div>

          <!-- servicios -->
          <div class="panel-section-lbl">Servicios</div>
          <div class="svc-list">
            <div class="svc-row">
              <span class="svc-row__name">{{ selected.service }}</span>
              <span class="svc-row__price">{{ selected.total ? fmtCOP(selected.total) : '—' }}</span>
            </div>
          </div>

          <!-- estilista -->
          <div v-if="!cambiarEmpleadoOpen" class="stylist-row" @click="abrirCambioEstilista">
            <div class="stylist-avatar"></div>
            <div class="stylist-info">
              <div class="stylist-lbl">Estilista</div>
              <div class="stylist-name">{{ selected.stylist || '—' }}</div>
            </div>
            <span class="stylist-change">Cambiar</span>
          </div>

          <!-- cambiar estilista form -->
          <div v-else class="stylist-edit">
            <label class="nc-label">Nueva estilista</label>
            <select class="nc-select" v-model="nuevoEmpleadoId">
              <option value="">Seleccionar…</option>
              <option v-for="e in empleados" :key="e.id_empleado" :value="String(e.id_empleado)">
                {{ e.nombre }} {{ e.apellido }}
              </option>
            </select>
            <div class="stylist-edit__btns">
              <button class="btn-sec" @click="cambiarEmpleadoOpen = false">Cancelar</button>
              <button class="btn-pri" :disabled="cambiandoEmpleado || !nuevoEmpleadoId" @click="guardarEstilista">
                {{ cambiandoEmpleado ? 'Guardando…' : 'Guardar' }}
              </button>
            </div>
          </div>

          <div class="divider"></div>

          <!-- factura box -->
          <div class="invoice-box">
            <div class="invoice-row">
              <span>Anticipo pagado</span>
              <span style="color:#16a34a;font-weight:500">{{ fmtCOP(selected.anticipo || 0) }}</span>
            </div>
            <div class="invoice-row">
              <span>Saldo pendiente</span>
              <span :style="{ color: selected.saldo > 0 ? '#d97706' : '#16a34a', fontWeight: 500 }">
                {{ fmtCOP(selected.saldo || 0) }}
              </span>
            </div>
            <div class="invoice-divider"></div>
            <div class="invoice-total">
              <span>Total</span>
              <span class="invoice-total__amount">{{ fmtCOP(selected.total || 0) }}</span>
            </div>
          </div>

          <!-- cobrar form inline -->
          <div v-if="cobrarOpen" class="cobrar-form">
            <div class="panel-section-lbl" style="margin-top:0">Registrar pago</div>
            <div class="nc-group">
              <label class="nc-label">Método</label>
              <select class="nc-select" v-model="cobrarForm.metodo">
                <option value="efectivo">Efectivo</option>
                <option value="transferencia">Transferencia</option>
                <option value="tarjeta">Tarjeta</option>
              </select>
            </div>
            <div class="nc-group" style="margin-top:10px">
              <label class="nc-label">Monto</label>
              <input class="nc-input" type="number" v-model="cobrarForm.monto" :placeholder="String(selected.saldo || '')" />
            </div>
            <div class="nc-group" style="margin-top:10px">
              <label class="nc-label">Fecha</label>
              <input class="nc-input" type="date" v-model="cobrarForm.fecha" />
            </div>
            <div class="stylist-edit__btns" style="margin-top:14px">
              <button class="btn-sec" @click="cobrarOpen = false">Cancelar</button>
              <button class="btn-pri" :disabled="cobrarLoading" @click="cobrarSaldo">
                {{ cobrarLoading ? 'Guardando…' : 'Confirmar pago' }}
              </button>
            </div>
          </div>

          <!-- editar servicios form inline (desktop drawer) -->
          <div v-if="editarServiciosOpen" class="edit-svc-form">
            <div class="panel-section-lbl" style="margin-top:0">Editar servicios</div>
            <p v-if="editServicesLoading" class="col__empty" style="padding:12px 0">Cargando servicios…</p>
            <template v-else>
              <div class="nc-services" style="max-height:190px">
                <button
                  v-for="s in editServices" :key="s.id_servicio"
                  type="button"
                  class="nc-service"
                  :class="{ 'nc-service--on': editServiceIds.has(s.id_servicio) }"
                  @click="toggleEditService(s.id_servicio)"
                >
                  <span>
                    <strong>{{ s.nombre }}</strong>
                    <small>{{ s.duracion }} min</small>
                  </span>
                  <b>{{ fmtCOP(s.precio) }}</b>
                </button>
              </div>
              <div class="invoice-box" style="margin-top:14px">
                <div class="invoice-row">
                  <span>Total</span>
                  <span>{{ fmtCOP(editTotal) }}</span>
                </div>
                <div class="invoice-row">
                  <span>Anticipo (30%)</span>
                  <span style="color:#16a34a;font-weight:500">{{ fmtCOP(editAnticipo) }}</span>
                </div>
                <div class="invoice-divider"></div>
                <div class="invoice-total">
                  <span>Saldo pendiente</span>
                  <span class="invoice-total__amount">{{ fmtCOP(editSaldo) }}</span>
                </div>
              </div>
              <p v-if="editServicesError" class="drawer__error" style="margin-top:8px">{{ editServicesError }}</p>
              <div class="stylist-edit__btns" style="margin-top:14px">
                <button class="btn-sec" @click="cerrarEditarServicios">Cancelar</button>
                <button class="btn-pri" :disabled="editServicesSaving || !editServiceIds.size" @click="guardarServiciosCita">
                  {{ editServicesSaving ? 'Guardando…' : 'Guardar cambios' }}
                </button>
              </div>
            </template>
          </div>

          <p v-if="drawerError" class="drawer__error">{{ drawerError }}</p>
        </div>

        <!-- footer actions — condicional por estado -->
        <div v-if="hasFooterActions" class="drawer__footer">
          <!-- PENDIENTE: confirmar + cancelar -->
          <template v-if="canConfirm">
            <button class="cta-btn" :disabled="completing" @click="confirmarCita">
              {{ completing ? 'Guardando…' : 'Confirmar cita' }}
            </button>
            <button class="cancel-link" @click="cancelarCita">Cancelar cita</button>
          </template>
          <!-- CONFIRMADA: terminar + editar servicios + cancelar -->
          <template v-else-if="canComplete">
            <button class="cta-btn" :disabled="completing" @click="completarCita">
              {{ completing ? 'Guardando…' : 'Cita terminada' }}
            </button>
            <button v-if="canEditServices && !editarServiciosOpen" class="cobrar-btn" @click="abrirEditarServicios">
              Editar servicios
            </button>
            <button class="cancel-link" @click="cancelarCita">Cancelar cita</button>
          </template>
          <!-- COMPLETADA con saldo pendiente: cobrar -->
          <template v-else-if="canChargeBalance && !cobrarOpen">
            <button class="cobrar-btn" @click="abrirCobro">
              Cobrar saldo · {{ fmtCOP(selected.saldo) }}
            </button>
          </template>
          <!-- TERMINADA (saldo=0 o pagada): sin acciones -->
        </div>
      </div>
    </Transition>

    <!-- ═══ BOTTOM SHEET (mobile) ═════════════════════════════════════════════ -->
    <Transition name="sheet">
      <div v-if="open" class="sheet">
        <div class="sheet__handle"></div>
        <div class="sheet__scroll scrl">
          <div class="drawer__cname" style="padding:0 22px;margin-top:14px">{{ selected.name }}</div>
          <div class="drawer__phone" style="padding:0 22px;margin-top:3px">{{ selected.fecha }} · {{ selected.time }}</div>

          <div class="panel-section-lbl" style="padding:0 22px;margin-top:20px">Servicios</div>
          <div class="svc-list" style="padding:0 22px">
            <div class="svc-row">
              <span class="svc-row__name">{{ selected.service }}</span>
              <span class="svc-row__price">{{ selected.total ? fmtCOP(selected.total) : '—' }}</span>
            </div>
          </div>

          <div style="margin:0 22px">
            <div v-if="!cambiarEmpleadoOpen" class="stylist-row" @click="abrirCambioEstilista">
              <div class="stylist-avatar"></div>
              <div class="stylist-info">
                <div class="stylist-lbl">Estilista</div>
                <div class="stylist-name">{{ selected.stylist || '—' }}</div>
              </div>
              <span class="stylist-change">Cambiar</span>
            </div>
            <div v-else class="stylist-edit">
              <select class="nc-select" v-model="nuevoEmpleadoId" style="width:100%">
                <option value="">Seleccionar…</option>
                <option v-for="e in empleados" :key="e.id_empleado" :value="String(e.id_empleado)">
                  {{ e.nombre }} {{ e.apellido }}
                </option>
              </select>
              <div class="stylist-edit__btns">
                <button class="btn-sec" @click="cambiarEmpleadoOpen = false">Cancelar</button>
                <button class="btn-pri" :disabled="cambiandoEmpleado || !nuevoEmpleadoId" @click="guardarEstilista">
                  {{ cambiandoEmpleado ? '…' : 'Guardar' }}
                </button>
              </div>
            </div>
          </div>

          <div class="invoice-box" style="margin:18px 22px 0">
            <div class="invoice-row">
              <span>Anticipo</span>
              <span style="color:#16a34a;font-weight:500">{{ fmtCOP(selected.anticipo || 0) }}</span>
            </div>
            <div class="invoice-row">
              <span>Saldo pendiente</span>
              <span :style="{ color: selected.saldo > 0 ? '#d97706' : '#16a34a', fontWeight: 500 }">
                {{ fmtCOP(selected.saldo || 0) }}
              </span>
            </div>
            <div class="invoice-divider"></div>
            <div class="invoice-total">
              <span>Total</span>
              <span class="invoice-total__amount">{{ fmtCOP(selected.total || 0) }}</span>
            </div>
          </div>

          <div v-if="cobrarOpen" class="cobrar-form" style="margin:16px 22px 0">
            <div class="panel-section-lbl" style="margin-top:0">Registrar pago</div>
            <select class="nc-select" v-model="cobrarForm.metodo" style="width:100%;margin-bottom:10px">
              <option value="efectivo">Efectivo</option>
              <option value="transferencia">Transferencia</option>
              <option value="tarjeta">Tarjeta</option>
            </select>
            <input class="nc-input" type="number" v-model="cobrarForm.monto" :placeholder="String(selected.saldo || '')" style="width:100%;margin-bottom:10px" />
            <input class="nc-input" type="date" v-model="cobrarForm.fecha" style="width:100%" />
            <div class="stylist-edit__btns" style="margin-top:12px">
              <button class="btn-sec" @click="cobrarOpen = false">Cancelar</button>
              <button class="btn-pri" :disabled="cobrarLoading" @click="cobrarSaldo">
                {{ cobrarLoading ? '…' : 'Confirmar' }}
              </button>
            </div>
          </div>

          <!-- editar servicios form inline (mobile sheet) -->
          <div v-if="editarServiciosOpen" class="edit-svc-form" style="margin:16px 22px 0">
            <div class="panel-section-lbl" style="margin-top:0">Editar servicios</div>
            <p v-if="editServicesLoading" class="col__empty" style="padding:12px 0">Cargando servicios…</p>
            <template v-else>
              <div class="nc-services" style="max-height:180px">
                <button
                  v-for="s in editServices" :key="s.id_servicio"
                  type="button"
                  class="nc-service"
                  :class="{ 'nc-service--on': editServiceIds.has(s.id_servicio) }"
                  @click="toggleEditService(s.id_servicio)"
                >
                  <span>
                    <strong>{{ s.nombre }}</strong>
                    <small>{{ s.duracion }} min</small>
                  </span>
                  <b>{{ fmtCOP(s.precio) }}</b>
                </button>
              </div>
              <div class="invoice-box" style="margin-top:14px">
                <div class="invoice-row">
                  <span>Total</span>
                  <span>{{ fmtCOP(editTotal) }}</span>
                </div>
                <div class="invoice-row">
                  <span>Anticipo (30%)</span>
                  <span style="color:#16a34a;font-weight:500">{{ fmtCOP(editAnticipo) }}</span>
                </div>
                <div class="invoice-divider"></div>
                <div class="invoice-total">
                  <span>Saldo pendiente</span>
                  <span class="invoice-total__amount">{{ fmtCOP(editSaldo) }}</span>
                </div>
              </div>
              <p v-if="editServicesError" class="drawer__error" style="margin-top:8px">{{ editServicesError }}</p>
              <div class="stylist-edit__btns" style="margin-top:14px">
                <button class="btn-sec" @click="cerrarEditarServicios">Cancelar</button>
                <button class="btn-pri" :disabled="editServicesSaving || !editServiceIds.size" @click="guardarServiciosCita">
                  {{ editServicesSaving ? 'Guardando…' : 'Guardar cambios' }}
                </button>
              </div>
            </template>
          </div>

          <p v-if="drawerError" class="drawer__error" style="margin:10px 22px 0">{{ drawerError }}</p>
        </div>

        <div v-if="hasFooterActions" class="sheet__footer">
          <!-- PENDIENTE: confirmar + cancelar -->
          <template v-if="canConfirm">
            <button class="cta-btn" :disabled="completing" @click="confirmarCita">
              {{ completing ? 'Guardando…' : 'Confirmar cita' }}
            </button>
            <button class="cancel-link" @click="cancelarCita">Cancelar cita</button>
          </template>
          <!-- CONFIRMADA: terminar + editar servicios + cancelar -->
          <template v-else-if="canComplete">
            <button class="cta-btn" :disabled="completing" @click="completarCita">
              {{ completing ? 'Guardando…' : 'Cita terminada' }}
            </button>
            <button v-if="canEditServices && !editarServiciosOpen" class="cobrar-btn" @click="abrirEditarServicios">
              Editar servicios
            </button>
            <button class="cancel-link" @click="cancelarCita">Cancelar cita</button>
          </template>
          <!-- COMPLETADA con saldo pendiente: cobrar -->
          <template v-else-if="canChargeBalance && !cobrarOpen">
            <button class="cobrar-btn" @click="abrirCobro">
              Cobrar · {{ fmtCOP(selected.saldo) }}
            </button>
          </template>
          <!-- TERMINADA (saldo=0 o pagada): sin acciones -->
        </div>
      </div>
    </Transition>

    <!-- ═══ NUEVA CITA SCRIM + SHEET ══════════════════════════════════════════ -->
    <Transition name="scrim">
      <div v-if="newOpen" class="scrim" style="z-index:50" @click="closeNew"></div>
    </Transition>
    <Transition name="sheet">
      <div v-if="newOpen" class="sheet nc-sheet">
        <div class="sheet__handle"></div>
        <div class="nc-scroll scrl">
          <div class="nc-title">Nueva cita</div>
          <div class="nc-form">
            <div class="nc-group">
              <label class="nc-label">Cliente *</label>
              <div class="client-filter">
                <input
                  v-model="newClientSearch"
                  class="kanban-search client-filter__search"
                  placeholder="Buscar cliente por nombre, cedula o celular..."
                />
                <div class="kanban-chips client-filter__chips">
                  <button
                    v-for="f in ['todos','nombre','documento','telefono']"
                    :key="f"
                    type="button"
                    class="kanban-chip"
                    :class="{ active: newClientFilter === f }"
                    @click="newClientFilter = f"
                  >
                    {{ f === 'todos' ? 'Todos' : f === 'nombre' ? 'Nombre' : f === 'documento' ? 'Cedula' : 'Celular' }}
                  </button>
                </div>
                <div class="client-results">
                  <button
                    v-for="c in filteredNewClients"
                    :key="c.id_cliente"
                    type="button"
                    class="client-option"
                    :class="{ 'client-option--on': Number(newDraft.cliente_id) === c.id_cliente }"
                    @click="selectNewClient(c.id_cliente)"
                  >
                    <span class="client-option__avatar">{{ initials(`${c.nombre || ''} ${c.apellido || ''}`) }}</span>
                    <span class="client-option__body">
                      <strong>{{ c.nombre }} {{ c.apellido }}</strong>
                      <small>{{ c.documento ? 'CC ' + c.documento : 'Sin documento' }} · {{ c.telefono || 'Sin celular' }}</small>
                    </span>
                  </button>
                  <p v-if="newClientsLoading" class="client-empty">Buscando clientes...</p>
                  <p v-else-if="!filteredNewClients.length" class="client-empty">Sin clientes encontrados</p>
                </div>
                <div v-if="newSelectedClient" class="client-selected">
                  {{ newSelectedClient.nombre }} {{ newSelectedClient.apellido }}
                </div>
              </div>
            </div>
            <div class="nc-group">
              <label class="nc-label">Empleada *</label>
              <select class="nc-select" v-model="newDraft.empleado_id">
                <option value="">{{ newEmployeesLoading ? 'Buscando...' : 'Seleccionar empleada...' }}</option>
                <option v-for="e in newEmpls" :key="e.id_empleado" :value="e.id_empleado">
                  {{ e.nombre }} {{ e.apellido }}{{ e.documento ? ' - CC ' + e.documento : '' }}{{ e.telefono ? ' - ' + e.telefono : '' }}{{ e.cargo ? ' - ' + e.cargo : '' }}
                </option>
              </select>
            </div>
            <div class="nc-row">
              <div class="nc-group">
                <label class="nc-label">Fecha *</label>
                <input class="nc-input" type="date" v-model="newDraft.fecha" />
              </div>
              <div class="nc-group">
                <label class="nc-label">Hora *</label>
                <input class="nc-input" type="time" v-model="newDraft.hora" />
              </div>
            </div>
            <div class="nc-group">
              <label class="nc-label">Servicios *</label>
              <div class="nc-services">
                <button
                  v-for="s in newServices"
                  :key="s.id_servicio"
                  type="button"
                  class="nc-service"
                  :class="{ 'nc-service--on': newServiceIds.has(s.id_servicio) }"
                  @click="toggleNewService(s.id_servicio)"
                >
                  <span>
                    <strong>{{ s.nombre }}</strong>
                    <small>{{ s.duracion }} min</small>
                  </span>
                  <b>{{ fmtCOP(s.precio) }}</b>
                </button>
              </div>
            </div>
            <div class="invoice-box nc-summary">
              <div class="invoice-row">
                <span>Total servicios</span>
                <span>{{ fmtCOP(newTotal) }}</span>
              </div>
              <div class="invoice-row">
                <span>Anticipo (30%)</span>
                <span style="font-weight:600;color:#1A1714">{{ fmtCOP(newAnticipo) }}</span>
              </div>
              <div class="invoice-row">
                <span>Saldo pendiente</span>
                <span>{{ fmtCOP(newSaldo) }}</span>
              </div>
              <div class="invoice-divider"></div>
              <div class="invoice-total">
                <span>Total factura</span>
                <span class="invoice-total__amount">{{ fmtCOP(newTotal) }}</span>
              </div>
            </div>
            <div class="nc-group">
              <label class="nc-label">Estado</label>
              <select class="nc-select" v-model="newDraft.estado">
                <option value="pendiente">Pendiente</option>
                <option value="confirmada">Confirmada</option>
              </select>
            </div>
          </div>
          <p v-if="newError" class="nc-error">{{ newError }}</p>
        </div>
        <div class="nc-footer">
          <button class="cta-btn" :disabled="newSaving" @click="saveNewCita">
            {{ newSaving ? 'Guardando…' : 'Crear cita' }}
          </button>
          <button class="nc-cancel" @click="closeNew">Cancelar</button>
        </div>
      </div>
    </Transition>

  </div>
</template>

<style scoped>
.dash { flex:1; display:flex; flex-direction:column; min-height:100vh; position:relative; font-family:Inter,system-ui,sans-serif; background:#FBF6F4; }

/* topbar */
.topbar { display:flex; align-items:center; justify-content:space-between; padding:20px 20px 14px; }
.topbar__left { display:flex; align-items:center; gap:10px; }
.topbar__date { font-family:Fraunces,Georgia,serif; font-size:19px; font-weight:500; color:#1A1714; letter-spacing:-.01em; }
.topbar__badge { font-size:12px; font-weight:600; padding:4px 11px; border-radius:20px; background:rgba(176,69,95,.10); color:#B0455F; }
.topbar__new { display:flex; align-items:center; gap:7px; height:38px; padding:0 14px; border-radius:11px; border:none; background:#B0455F; color:#FBF6F4; font-size:13px; font-weight:500; font-family:inherit; cursor:pointer; transition:filter .2s; }
.topbar__new:hover { filter:brightness(1.07); }

.kanban-tools{
  display:flex;
  flex-wrap:wrap;
  gap:12px;
  align-items:center;
  margin:0 20px 16px;
}

.kanban-search,
.kanban-date{
  height:40px;
  min-width:260px;
  padding:0 14px;
  border-radius:12px;
  border:1px solid rgba(26,23,20,.08);
  background:#fff;
  color:#1A1714;
  font-size:13px;
  font-family:inherit;
}

.kanban-date{
  min-width:160px;
}

.kanban-search:focus,
.kanban-date:focus{
  outline:none;
  border-color:#B0455F;
}

.kanban-chips{
  display:flex;
  gap:8px;
  flex-wrap:wrap;
}

.kanban-chip{
  height:34px;
  padding:0 14px;
  border-radius:20px;
  border:1px solid rgba(26,23,20,.10);
  background:#fff;
  color:#6b6258;
  font-size:12px;
  font-weight:500;
  cursor:pointer;
  transition:.2s;
}

.kanban-chip:hover{
  background:#F6F0ED;
}

.kanban-chip.active{
  background:#1A1714;
  color:#FBF6F4;
  border-color:#1A1714;
}

/* alerts */
.alerts { display:flex; align-items:center; gap:0; margin:0 20px 14px; padding:11px 14px; border-radius:13px; background:#fff; border:1px solid rgba(26,23,20,.08); overflow-x:auto; flex-wrap:nowrap; }
.alerts::-webkit-scrollbar { display:none; }
.alert-item { display:flex; align-items:center; gap:8px; white-space:nowrap; flex:none; }
.alert-item--border { padding-right:14px; margin-right:14px; border-right:1px solid rgba(26,23,20,.08); }
.alert-dot { width:8px; height:8px; border-radius:50%; flex:none; }
.alert-lbl { font-size:12px; color:#6b6258; }
.alert-chip { font-size:11px; font-weight:600; padding:2px 9px; border-radius:20px; }

/* col tabs */
.col-tabs { display:flex; gap:8px; overflow-x:auto; padding:0 20px 12px; }
.col-tab { display:flex; align-items:center; gap:6px; flex:none; padding:7px 13px; border-radius:20px; border:1px solid rgba(26,23,20,.10); background:#fff; font-size:12.5px; font-weight:500; color:#1A1714; font-family:inherit; cursor:pointer; transition:background .15s; }
.col-tab--on { background:#1A1714; color:#FBF6F4; border-color:#1A1714; }
.col-tab__dot { width:8px; height:8px; border-radius:50%; flex:none; }
.col-tab__count { font-size:11px; font-weight:600; color:#a59a8d; }
.col-tab--on .col-tab__count { color:rgba(255,255,255,.6); }

/* board */
.board { flex:1; overflow-y:auto; padding:0 20px 20px; }
.board__grid { display:none; }
.board__mobile { display:flex; flex-direction:column; gap:10px; }
.mob-col { display:flex; flex-direction:column; gap:10px; }
.mob-col--hidden { display:none; }
.col__empty { font-size:13px; color:#a59a8d; text-align:center; padding:24px 0; }

/* columns */
.col { border-radius:16px; background:#fff; border:1px solid rgba(26,23,20,.08); padding:16px; }
.col__head { display:flex; align-items:center; gap:9px; padding-bottom:14px; }
.col__dot { width:9px; height:9px; border-radius:50%; flex:none; }
.col__name { font-family:Fraunces,Georgia,serif; font-size:16px; font-weight:500; color:#1A1714; flex:1; }
.col__count { font-size:11px; font-weight:600; padding:2px 9px; border-radius:20px; background:#F1ECE8; color:#8a7f72; }
.col__cards { display:flex; flex-direction:column; gap:12px; }

/* card */
.card { border-radius:12px; padding:16px; background:#fff; box-shadow:0 2px 8px rgba(20,12,4,.06); border:1px solid rgba(26,23,20,.08); cursor:pointer; transition:box-shadow .2s,transform .15s; border-left-width:3px; }
.card:hover { box-shadow:0 4px 16px rgba(20,12,4,.12); transform:translateY(-1px); }
.card--delay { border-color:rgba(220,50,50,.3); }
.card__top { display:flex; gap:11px; align-items:flex-start; }
.card__avatar { flex:none; width:36px; height:36px; border-radius:50%; background:#F1E5E3; display:flex; align-items:center; justify-content:center; font-size:12px; font-weight:600; color:#7a3a4f; }
.card__info { flex:1; min-width:0; }
.card__name { font-family:Fraunces,Georgia,serif; font-size:15px; color:#1A1714; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.card__svc { font-size:12px; color:#8a7f72; margin-top:1px; }
.card__more { font-size:15px; color:#c2b6a8; letter-spacing:1px; line-height:.6; }
.card__meta { display:flex; align-items:center; gap:6px; margin-top:12px; font-size:12px; color:#6b6258; }
.card__foot { display:flex; align-items:center; justify-content:space-between; margin-top:12px; flex-wrap:wrap; gap:6px; }

/* badges */
.badge { font-size:11px; font-weight:500; padding:3px 10px; border-radius:20px; }
.delay-chip { display:inline-flex; align-items:center; gap:5px; font-size:11px; font-weight:600; padding:3px 9px; border-radius:20px; background:#FBE9E7; color:#c0392b; }
.delay-chip__dot { width:5px; height:5px; border-radius:50%; background:#c0392b; flex:none; }
.saldo-chip { font-size:11px; font-weight:600; padding:3px 9px; border-radius:20px; background:rgba(217,119,6,.12); color:#b06407; }

/* scrim */
.scrim { position:fixed; inset:0; z-index:30; background:rgba(26,23,20,.18); }

/* drawer (desktop) — oculto mobile */
.drawer { display:none; }
@media (min-width:1024px){
  .kanban-tools{
    margin:0 28px 18px;
  }
}

/* bottom sheet */
.sheet { position:fixed; left:0; right:0; bottom:0; z-index:40; background:#FBF6F4; border-radius:24px 24px 0 0; max-height:88vh; display:flex; flex-direction:column; padding-bottom:64px; }
.sheet__handle { width:40px; height:4px; border-radius:4px; background:rgba(26,23,20,.15); margin:12px auto 0; flex:none; }
.sheet__scroll { flex:1; overflow-y:auto; padding-bottom:8px; }
.sheet__footer { flex:none; padding:14px 22px 20px; border-top:1px solid rgba(26,23,20,.07); }

/* drawer + sheet shared */
.drawer__scroll { flex:1; overflow-y:auto; padding:24px 24px 16px; }
.drawer__header { display:flex; align-items:flex-start; justify-content:space-between; margin-bottom:20px; }
.drawer__cname { font-family:Fraunces,Georgia,serif; font-size:20px; font-weight:500; color:#1A1714; }
.drawer__phone { font-size:13px; color:#8a7f72; margin-top:3px; }
.drawer__close { width:32px; height:32px; border-radius:9px; border:1px solid rgba(26,23,20,.1); background:#fff; cursor:pointer; display:flex; align-items:center; justify-content:center; }
.drawer__footer { flex:none; padding:16px 24px 22px; border-top:1px solid rgba(26,23,20,.07); display:flex; flex-direction:column; gap:10px; }
.drawer__error { font-size:12px; color:#B0455F; margin-top:12px; }

.panel-section-lbl { font-size:11px; font-weight:600; letter-spacing:.05em; text-transform:uppercase; color:#a59a8d; margin-bottom:11px; }
.svc-list { display:flex; flex-direction:column; gap:10px; margin-bottom:18px; }
.svc-row { display:flex; align-items:baseline; justify-content:space-between; }
.svc-row__name { font-family:Fraunces,Georgia,serif; font-size:14px; color:#1A1714; }
.svc-row__price { font-size:13px; font-weight:500; color:#1A1714; }

.stylist-row { display:flex; align-items:center; gap:11px; padding:12px 14px; border-radius:12px; background:#fff; border:1px solid rgba(26,23,20,.08); cursor:pointer; margin-bottom:18px; }
.stylist-row:hover { border-color:rgba(176,69,95,.25); }
.stylist-avatar { width:34px; height:34px; border-radius:50%; background:radial-gradient(circle at 35% 30%,#B89BB0,#9a7d92); flex:none; }
.stylist-info { flex:1; }
.stylist-lbl { font-size:11px; color:#a59a8d; }
.stylist-name { font-size:13.5px; font-weight:500; color:#1A1714; margin-top:1px; }
.stylist-change { font-size:12px; font-weight:600; color:#B0455F; }
.stylist-edit { border-radius:12px; border:1px solid rgba(176,69,95,.2); padding:14px; margin-bottom:18px; }
.stylist-edit__btns { display:flex; gap:10px; margin-top:12px; }

.divider { height:1px; background:rgba(26,23,20,.08); margin:0 0 18px; }

.invoice-box { border-radius:14px; background:#fff; border:1px solid rgba(26,23,20,.08); padding:18px; }
.invoice-row { display:flex; justify-content:space-between; font-size:13px; color:#8a7f72; margin-bottom:11px; }
.invoice-divider { height:1px; background:rgba(26,23,20,.08); margin-bottom:13px; }
.invoice-total { display:flex; justify-content:space-between; align-items:baseline; }
.invoice-total span:first-child { font-size:13px; font-weight:600; color:#1A1714; }
.invoice-total__amount { font-family:Fraunces,Georgia,serif; font-size:22px; font-weight:600; color:#B0455F; }

.cobrar-form { border-radius:12px; border:1px solid rgba(217,119,6,.25); background:rgba(254,243,199,.4); padding:14px; margin-top:16px; }

/* buttons */
.cta-btn { display:flex; align-items:center; justify-content:center; width:100%; height:50px; border-radius:13px; border:none; background:#1A1714; color:#FBF6F4; font-family:Fraunces,Georgia,serif; font-size:16px; font-weight:500; cursor:pointer; transition:filter .2s; }
.cta-btn:disabled { opacity:.55; cursor:not-allowed; }
.cta-btn:not(:disabled):hover { filter:brightness(1.12); }
.cobrar-btn { display:flex; align-items:center; justify-content:center; width:100%; height:46px; border-radius:13px; border:2px solid #B0455F; background:transparent; color:#B0455F; font-size:14px; font-weight:600; font-family:inherit; cursor:pointer; transition:background .15s; }
.cobrar-btn:hover { background:rgba(176,69,95,.06); }
.cancel-link { display:block; width:100%; text-align:center; font-size:13px; color:#8a7f72; background:none; border:none; cursor:pointer; font-family:inherit; }
.cancel-link:hover { color:#c0392b; }

.btn-pri { flex:1; height:38px; border-radius:10px; border:none; background:#B0455F; color:#fff; font-size:13px; font-weight:600; font-family:inherit; cursor:pointer; }
.btn-pri:disabled { opacity:.55; cursor:not-allowed; }
.btn-sec { flex:1; height:38px; border-radius:10px; border:1.5px solid rgba(26,23,20,.14); background:transparent; color:#6b6258; font-size:13px; font-weight:500; font-family:inherit; cursor:pointer; }

/* form inputs */
.nc-select,.nc-input { height:44px; padding:0 12px; border-radius:11px; border:1.5px solid rgba(26,23,20,.14); background:#fff; font-size:14px; font-family:inherit; color:#1A1714; transition:border-color .2s; box-sizing:border-box; }
.nc-select:focus,.nc-input:focus { outline:none; border-color:#B0455F; }
.nc-label { font-size:11px; font-weight:600; color:#a59a8d; text-transform:uppercase; letter-spacing:.04em; }
.nc-group { display:flex; flex-direction:column; gap:5px; }
.nc-row { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
.nc-form { display:flex; flex-direction:column; gap:14px; }
.nc-title { font-family:Fraunces,Georgia,serif; font-size:19px; font-weight:500; color:#1A1714; padding-top:18px; margin-bottom:20px; }
.nc-error { font-size:12px; color:#B0455F; margin-top:4px; }
.nc-footer { flex:none; padding:14px 22px 20px; border-top:1px solid rgba(26,23,20,.07); }
.nc-cancel { display:flex; align-items:center; justify-content:center; width:100%; height:44px; border-radius:11px; margin-top:10px; border:1.5px solid rgba(26,23,20,.12); background:transparent; color:#6b6258; font-family:inherit; font-size:14px; font-weight:500; cursor:pointer; }
.nc-cancel:hover { background:rgba(26,23,20,.04); }
.nc-scroll { flex:1; overflow-y:auto; padding:0 22px 8px; }
.nc-scroll::-webkit-scrollbar { display:none; }
.nc-services { display:flex; flex-direction:column; gap:8px; max-height:230px; overflow-y:auto; padding-right:2px; }
.nc-service { width:100%; display:flex; align-items:center; justify-content:space-between; gap:12px; padding:12px 13px; border-radius:12px; border:1.5px solid rgba(26,23,20,.10); background:#fff; color:#1A1714; text-align:left; font-family:inherit; cursor:pointer; transition:border-color .18s, background .18s, box-shadow .18s; }
.nc-service strong { display:block; font-family:Fraunces,Georgia,serif; font-size:14px; font-weight:500; }
.nc-service small { display:block; margin-top:2px; font-size:11px; color:#8a7f72; }
.nc-service b { flex:none; font-size:12px; font-weight:700; color:#1A1714; }
.nc-service--on { border-color:#B0455F; background:#fff7f9; box-shadow:0 0 0 2px rgba(176,69,95,.08); }
.nc-summary { margin-top:2px; }
.nc-money { width:130px; height:34px; padding:0 10px; border-radius:9px; border:1px solid rgba(26,23,20,.14); background:#fff; color:#1A1714; font-family:inherit; font-size:13px; text-align:right; }
.nc-money:focus { outline:none; border-color:#B0455F; }
.client-filter { display:flex; flex-direction:column; gap:8px; }
.client-filter__search { width:100%; min-width:0; box-sizing:border-box; }
.client-filter__chips { gap:6px; }
.client-filter__chips .kanban-chip { height:30px; padding:0 11px; font-size:11.5px; }
.client-results { display:flex; flex-direction:column; gap:7px; max-height:210px; overflow-y:auto; padding-right:2px; }
.client-results::-webkit-scrollbar { display:none; }
.client-option {
  width:100%;
  display:flex;
  align-items:center;
  gap:10px;
  padding:10px 11px;
  border-radius:12px;
  border:1.5px solid rgba(26,23,20,.10);
  background:#fff;
  text-align:left;
  font-family:inherit;
  cursor:pointer;
  transition:border-color .18s, background .18s, box-shadow .18s;
}
.client-option--on { border-color:#B0455F; background:#fff7f9; box-shadow:0 0 0 2px rgba(176,69,95,.08); }
.client-option__avatar {
  flex:none;
  width:34px;
  height:34px;
  border-radius:50%;
  background:#F1E5E3;
  color:#7a3a4f;
  display:flex;
  align-items:center;
  justify-content:center;
  font-size:11px;
  font-weight:700;
}
.client-option__body { min-width:0; display:flex; flex-direction:column; gap:2px; }
.client-option__body strong { font-family:Fraunces,Georgia,serif; font-size:14px; font-weight:500; color:#1A1714; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.client-option__body small { font-size:11px; color:#8a7f72; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.client-empty { margin:8px 0; text-align:center; color:#a59a8d; font-size:12px; }
.client-selected { border-radius:10px; background:rgba(22,163,74,.10); color:#15803d; padding:7px 10px; font-size:12px; font-weight:600; }

/* transitions */
.scrim-enter-active,.scrim-leave-active { transition:opacity .3s ease; }
.scrim-enter-from,.scrim-leave-to { opacity:0; }
.sheet-enter-active,.sheet-leave-active { transition:transform .38s cubic-bezier(.4,0,.2,1); }
.sheet-enter-from,.sheet-leave-to { transform:translateY(100%); }
.drawer-enter-active,.drawer-leave-active { transition:transform .38s cubic-bezier(.4,0,.2,1); }
.drawer-enter-from,.drawer-leave-to { transform:translateX(100%); }
.scrl::-webkit-scrollbar { display:none; }
.scrl { -ms-overflow-style:none; scrollbar-width:none; }

/* desktop */
@media (min-width:1024px) {
  .topbar { padding:22px 28px 18px; }
  .topbar__date { font-size:22px; }
  .alerts { margin:0 28px 18px; }
  .col-tabs { display:none; }
  .board { padding:0 28px 28px; overflow:visible; }
  .board__grid { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:16px; align-items:start; }
  .board__mobile { display:none; }
  .sheet { display:none; }
  .nc-sheet { display:flex; }
  .drawer {
    display:flex; flex-direction:column; position:fixed;
    top:0; right:0; bottom:0; width:380px; z-index:40;
    background:#FBF6F4; border-left:1px solid rgba(26,23,20,.08);
    box-shadow:-12px 0 34px rgba(20,12,4,.10);
  }
  .nc-sheet { width:420px; left:auto; right:0; top:0; bottom:0; border-radius:0; max-height:none; border-left:1px solid rgba(26,23,20,.08); z-index:51; }
  .nc-footer { padding:16px 24px 24px; }
}

/* badge de estado en header del drawer */
.state-badge { display:inline-block; margin-top:7px; font-size:11px; font-weight:600; padding:3px 11px; border-radius:20px; }
.state-badge--pendiente { background:rgba(217,119,6,.12); color:#b06407; }
.state-badge--confirmada { background:rgba(176,69,95,.10); color:#B0455F; }
.state-badge--completada { background:rgba(22,163,74,.12); color:#15803d; }

/* formulario edición de servicios inline */
.edit-svc-form { border-radius:12px; border:1.5px solid rgba(176,69,95,.18); background:rgba(176,69,95,.03); padding:16px; margin-top:16px; }
</style>
