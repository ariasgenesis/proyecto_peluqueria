<script setup>
import { computed, onMounted, ref } from 'vue'
import { getFacturas, createFactura, updateFactura, deleteFactura, fmtCOP, getReservaWeb } from '@/api/admin'
import { useAuthStore } from '@/stores/auth'
import { useAlertDialog } from '@/composables/useAlertDialog'

const loading      = ref(true)
const auth         = useAuthStore()
const isAdmin      = computed(() => auth.rol === 'admin')
const allFacturas  = ref([])
const q            = ref('')
const filtroTipo   = ref('todos')
const filtroEstado = ref('todos')
const selected     = ref(null)
const mode         = ref('view') // 'view' | 'create' | 'edit'
const draft        = ref({})
const saving       = ref(false)
const formError    = ref('')
const wompiData    = ref(null)
const loadingWompi = ref(false)
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

onMounted(async () => {
  try { allFacturas.value = await getFacturas() }
  finally { loading.value = false }
})

const facturas = computed(() => {
  let list = allFacturas.value
  const s = q.value.trim().toLowerCase()
  if (s) list = list.filter(f =>
    String(f.id_factura).includes(s) ||
    String(f.reserva_id || '').includes(s) ||
    String(f.cita_id    || '').includes(s) ||
    (f.cliente || '').toLowerCase().includes(s) ||
    (f.empleado_confirmo || '').toLowerCase().includes(s) ||
    (f.confirmada_por_nombre || '').toLowerCase().includes(s)
  )
  if (filtroTipo.value === 'wompi')       list = list.filter(f => !!f.reserva_id)
  else if (filtroTipo.value !== 'todos')  list = list.filter(f => f.tipo === filtroTipo.value)
  if (filtroEstado.value !== 'todos') list = list.filter(f => f.estado === filtroEstado.value)
  return list
})

const stats = computed(() => {
  const hoy = new Date().toISOString().slice(0, 10)
  const deHoy = allFacturas.value.filter(f => (f.fecha || '').startsWith(hoy))
  const pagadas = deHoy.filter(f => f.estado === 'pagada')
  const wompiTotal = allFacturas.value
    .filter(f => f.reserva_id && f.estado === 'pagada')
    .reduce((s, f) => s + Number(f.total || 0), 0)
  return {
    citasHoy:    deHoy.length,
    ingresosHoy: fmtCOP(pagadas.reduce((s, f) => s + Number(f.total || 0), 0)),
    pendientes:  allFacturas.value.filter(f => f.estado === 'pendiente').length,
    wompiTotal:  fmtCOP(wompiTotal),
  }
})

function refLabel(f) {
  if (f?.cita_id)    return 'Cita #' + f.cita_id
  if (f?.reserva_id) return 'Reserva web #' + f.reserva_id
  return '—'
}

const estadoLabel = { pagada: 'Pagada', pendiente: 'Pendiente', parcial: 'Parcial', anulada: 'Anulada', cancelada: 'Cancelada' }
const tipoLabel   = { servicio: 'Servicio', anticipo: 'Anticipo' }

function clienteLabel(f) {
  return f?.cliente || 'Cliente sin nombre'
}

function confirmadorLabel(f) {
  return f?.empleado_confirmo || f?.confirmada_por_nombre || 'Pendiente'
}

const sheetOpen = computed(() => selected.value !== null || mode.value === 'create')

async function open(f) {
  selected.value = f
  mode.value = 'view'
  formError.value = ''
  wompiData.value = null
  if (f.reserva_id) {
    loadingWompi.value = true
    try { wompiData.value = await getReservaWeb(f.reserva_id) }
    catch (_) {}
    finally { loadingWompi.value = false }
  }
}
function openCreate() {
  selected.value = null
  draft.value = { fecha: new Date().toISOString().slice(0,10), tipo: 'servicio', total: '', anticipo: '', cita_id: '', pin: '' }
  mode.value = 'create'; formError.value = ''
}
function openEdit() {
  draft.value = { anticipo: selected.value.anticipo || 0, pin: '' }
  mode.value = 'edit'; formError.value = ''
}
function cancelForm() { mode.value === 'edit' ? (mode.value = 'view') : close() }
function close() { selected.value = null; mode.value = 'view'; formError.value = ''; wompiData.value = null }

async function save() {
  formError.value = ''
  const d = draft.value
  if (!isAdmin.value && !d.pin?.match(/^\d{4}$/)) { formError.value = 'PIN de 4 dígitos requerido'; return }
  if (mode.value === 'create') {
    if (!d.total) { formError.value = 'Total es requerido'; return }
    if (!d.tipo)  { formError.value = 'Tipo es requerido'; return }
  }
  saving.value = true
  try {
    if (mode.value === 'create') {
      const payload = { fecha: d.fecha, tipo: d.tipo, total: Number(d.total), anticipo: Number(d.anticipo) || 0, pin: isAdmin.value ? undefined : d.pin }
      if (d.cita_id) payload.cita_id = Number(d.cita_id)
      const f = await createFactura(payload)
      allFacturas.value.unshift(f); close()
      await showStockServiceAlert(f.servicios_actualizados)
    } else {
      const f = await updateFactura(selected.value.id_factura, { anticipo: Number(d.anticipo), pin: isAdmin.value ? undefined : d.pin })
      const idx = allFacturas.value.findIndex(x => x.id_factura === f.id_factura)
      if (idx !== -1) allFacturas.value[idx] = f
      selected.value = f; mode.value = 'view'
      await showStockServiceAlert(f.servicios_actualizados)
    }
  } catch (e) { formError.value = e.response?.data?.message || 'Error al guardar' }
  finally { saving.value = false }
}

async function anular() {
  if (selected.value.estado === 'pagada') {
    await alertDialog({ title: 'Factura pagada', message: 'Las facturas pagadas no pueden anularse', variant: 'warning' })
    return
  }
  const ok = await confirmDialog({
    title: 'Anular factura',
    message: `Anular factura F-${selected.value.id_factura}?`,
    variant: 'danger',
    confirmText: 'Anular',
  })
  if (!ok) return
  try {
    await deleteFactura(selected.value.id_factura)
    allFacturas.value = allFacturas.value.filter(f => f.id_factura !== selected.value.id_factura)
    close()
  } catch (e) { await alertDialog({ title: 'No se pudo anular', message: e.response?.data?.message || 'Error al anular', variant: 'danger' }) }
}

async function marcarPagada() {
  if (!selected.value || selected.value.estado === 'pagada') return
  const pin = isAdmin.value ? undefined : await promptDialog({
    title: 'PIN del empleado',
    message: 'Ingresa el PIN para marcar esta factura como pagada.',
    inputType: 'password',
    placeholder: '4 digitos',
    confirmText: 'Marcar pagada',
  })
  if (pin === null) return
  if (!isAdmin.value && !pin?.match(/^\d{4}$/)) {
    await alertDialog({ title: 'PIN requerido', message: 'PIN de 4 digitos requerido', variant: 'warning' })
    return
  }
  saving.value = true
  try {
    const f = await updateFactura(selected.value.id_factura, { anticipo: Number(selected.value.total), pin })
    const idx = allFacturas.value.findIndex(x => x.id_factura === f.id_factura)
    if (idx !== -1) allFacturas.value[idx] = f
    selected.value = f
    await showStockServiceAlert(f.servicios_actualizados)
  } catch (e) { await alertDialog({ title: 'No se pudo marcar como pagada', message: e.response?.data?.message || 'Error al marcar como pagada', variant: 'danger' }) }
  finally { saving.value = false }
}
</script>

<template>
  <div class="fac">

    <div class="topbar">
      <h1 class="topbar__title">Facturación</h1>
      <button class="topbar__btn" @click="openCreate">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
        Nueva
      </button>
    </div>

    <!-- stats -->
    <div class="stats">
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

    <!-- toolbar -->
    <div class="toolbar">
      <div class="search">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.35-4.35"/></svg>
        <input v-model="q" class="search__input" type="search" placeholder="Buscar factura o cliente…" />
        <button v-if="q" class="search__clear" @click="q = ''">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
        </button>
      </div>
      <div class="chips">
        <button v-for="f in ['todos','servicio','anticipo','wompi']" :key="f"
          class="chip" :class="{ 'chip--on': filtroTipo === f, 'chip--wompi': f === 'wompi' && filtroTipo === f }"
          @click="filtroTipo = f">
          {{ f === 'todos' ? 'Todos' : f === 'servicio' ? 'Servicio' : f === 'anticipo' ? 'Anticipo' : '💳 Wompi' }}
        </button>
      </div>
      <div class="chips">
        <button v-for="f in ['todos','pagada','parcial','pendiente','anulada']" :key="f"
          class="chip" :class="{ 'chip--on': filtroEstado === f }"
          @click="filtroEstado = f">
          {{ f === 'todos' ? 'Todos' : estadoLabel[f] }}
        </button>
      </div>
    </div>

    <!-- lista -->
    <div class="list-wrap">
      <p v-if="!loading && !facturas.length" class="empty">Sin resultados.</p>

      <!-- tabla desktop -->
      <table class="table">
        <thead>
          <tr>
            <th>#</th>
            <th>Referencia</th>
            <th>Cliente</th>
            <th>Fecha</th>
            <th>Anticipo</th>
            <th>Total</th>
            <th>Tipo</th>
            <th>Origen</th>
            <th>Confirmo</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading"><td colspan="10" style="padding:32px;text-align:center;color:#a59a8d">Cargando…</td></tr>
          <tr v-for="f in facturas" :key="f.id_factura" class="table__row" @click="open(f)">
            <td class="td-id">F-{{ f.id_factura }}</td>
            <td class="td-bold">{{ refLabel(f) }}</td>
            <td class="td-muted">{{ clienteLabel(f) }}</td>
            <td class="td-muted">{{ f.fecha }}</td>
            <td class="td-muted">{{ fmtCOP(f.anticipo) }}</td>
            <td class="td-bold">{{ fmtCOP(f.total) }}</td>
            <td>
              <span class="badge" :class="'badge--tipo-' + f.tipo">{{ tipoLabel[f.tipo] }}</span>
            </td>
            <td>
              <span v-if="f.reserva_id" class="badge badge--wompi">Wompi</span>
              <span v-else class="td-muted">Caja</span>
            </td>
            <td class="td-muted">{{ confirmadorLabel(f) }}</td>
            <td>
              <span class="badge" :class="'badge--' + f.estado">{{ estadoLabel[f.estado] }}</span>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- tarjetas mobile -->
      <div class="card-list">
        <div v-for="f in facturas" :key="f.id_factura" class="fac-card" @click="open(f)">
          <div class="fac-card__top">
            <div class="fac-card__info">
              <div class="fac-card__name">{{ refLabel(f) }}</div>
              <div class="fac-card__meta">F-{{ f.id_factura }} · {{ clienteLabel(f) }} · {{ f.fecha }}</div>
            </div>
            <div class="fac-card__right">
              <div class="fac-card__total">{{ fmtCOP(f.total) }}</div>
              <span class="badge" :class="'badge--' + f.estado">{{ estadoLabel[f.estado] }}</span>
            </div>
          </div>
          <div class="fac-card__svcs">
            <span class="badge" :class="'badge--tipo-' + f.tipo">{{ tipoLabel[f.tipo] }}</span>
            <span v-if="f.reserva_id" class="badge badge--wompi" style="margin-left:6px">Wompi</span>
            <span v-if="f.saldo_pendiente > 0" style="font-size:12px;color:#b45309;margin-left:8px">Saldo: {{ fmtCOP(f.saldo_pendiente) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- SCRIM -->
    <Transition name="scrim">
      <div v-if="sheetOpen" class="scrim" @click="close"></div>
    </Transition>

    <!-- SHEET / DRAWER -->
    <Transition name="sheet">
      <div v-if="sheetOpen" class="sheet">
        <div class="sheet__handle"></div>
        <div class="sheet__scroll">

          <!-- FORM MODE -->
          <template v-if="mode !== 'view'">
            <div class="form-title">{{ mode === 'create' ? 'Nueva factura' : 'Registrar anticipo' }}</div>
            <div class="form">
              <template v-if="mode === 'create'">
                <div class="form-group">
                  <label class="form-label">Fecha *</label>
                  <input class="form-input" type="date" v-model="draft.fecha" />
                </div>
                <div class="form-row">
                  <div class="form-group">
                    <label class="form-label">Tipo *</label>
                    <select class="form-select" v-model="draft.tipo">
                      <option value="servicio">Servicio</option>
                      <option value="anticipo">Anticipo</option>
                    </select>
                  </div>
                  <div class="form-group">
                    <label class="form-label">Cita ID</label>
                    <input class="form-input" v-model="draft.cita_id" type="number" min="1" placeholder="Opcional" />
                  </div>
                </div>
                <div class="form-row">
                  <div class="form-group">
                    <label class="form-label">Total *</label>
                    <input class="form-input" v-model="draft.total" type="number" min="0" placeholder="0" />
                  </div>
                  <div class="form-group">
                    <label class="form-label">Anticipo</label>
                    <input class="form-input" v-model="draft.anticipo" type="number" min="0" placeholder="0" />
                  </div>
                </div>
              </template>
              <template v-else>
                <div class="fields" style="margin-bottom:14px">
                  <div class="field-row"><span class="field-lbl">Factura</span><span class="field-val">F-{{ selected.id_factura }}</span></div>
                  <div class="field-row"><span class="field-lbl">Total</span><span class="field-val">{{ fmtCOP(selected.total) }}</span></div>
                </div>
                <div class="form-group">
                  <label class="form-label">Nuevo anticipo</label>
                  <input class="form-input" v-model="draft.anticipo" type="number" min="0" :max="selected.total" placeholder="0" />
                </div>
              </template>
              <div v-if="!isAdmin" class="form-group">
                <label class="form-label">PIN del empleado *</label>
                <input class="form-input pin-input" v-model="draft.pin" type="text" maxlength="4" placeholder="••••" inputmode="numeric" autocomplete="off" />
              </div>
            </div>
            <p v-if="formError" class="form-error">{{ formError }}</p>
          </template>

          <!-- VIEW MODE -->
          <template v-else>
            <div class="sheet__head">
              <div class="sheet__headinfo">
                <div class="sheet__id">F-{{ selected.id_factura }}</div>
                <div class="sheet__name">{{ refLabel(selected) }}</div>
                <div class="sheet__sub">{{ selected.fecha }}</div>
              </div>
              <div class="sheet__badges">
                <span v-if="selected.reserva_id" class="badge badge--wompi">Wompi</span>
                <span class="badge" :class="'badge--tipo-' + selected.tipo">{{ tipoLabel[selected.tipo] }}</span>
                <span class="badge" :class="'badge--' + selected.estado">{{ estadoLabel[selected.estado] }}</span>
              </div>
              <button class="sheet__close" @click="close">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
              </button>
            </div>
            <div class="fields">
              <div class="field-row">
                <span class="field-lbl">Cliente</span>
                <span class="field-val">{{ clienteLabel(selected) }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Confirmo pago</span>
                <span class="field-val">{{ confirmadorLabel(selected) }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Anticipo</span>
                <span class="field-val">{{ fmtCOP(selected.anticipo) }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Saldo pendiente</span>
                <span class="field-val">{{ fmtCOP(selected.saldo_pendiente) }}</span>
              </div>
              <div class="field-row field-row--total">
                <span class="field-lbl field-lbl--total">Total</span>
                <span class="field-val field-val--total">{{ fmtCOP(selected.total) }}</span>
              </div>
            </div>

            <!-- Wompi payment block -->
            <template v-if="selected.reserva_id">
              <div class="wompi-block">
                <div class="section-lbl" style="margin-top:18px">Pago Wompi (sandbox)</div>
                <p v-if="loadingWompi" class="wompi-loading">Cargando datos de pago…</p>
                <template v-else-if="wompiData">
                  <div class="wompi-ref" v-if="wompiData.referencia_pago">
                    <span class="wompi-ref__label">Referencia</span>
                    <code class="wompi-ref__val">{{ wompiData.referencia_pago }}</code>
                  </div>
                  <div class="wompi-ref" v-if="wompiData.transaccion_id">
                    <span class="wompi-ref__label">Transacción ID</span>
                    <code class="wompi-ref__val">{{ wompiData.transaccion_id }}</code>
                  </div>
                  <div class="fields" style="margin-top:8px">
                    <div class="field-row">
                      <span class="field-lbl">Fecha reserva</span>
                      <span class="field-val">{{ wompiData.fecha }}</span>
                    </div>
                    <div class="fields">
                      <div class="field-row">
                        <span class="field-lbl">Cliente</span>
                        <span class="field-val">{{ clienteLabel(selected) }}</span>
                      </div>
                      <div class="field-row">
                        <span class="field-lbl">Despachado por</span>
                        <span class="field-val">{{ confirmadorLabel(selected) }}</span>
                      </div>
                    </div>
                    <div class="field-row">
                      <span class="field-lbl">Hora</span>
                      <span class="field-val">{{ wompiData.hora }}</span>
                    </div>
                    <div class="field-row">
                      <span class="field-lbl">Estado reserva</span>
                      <span class="badge" :class="'badge--' + wompiData.estado">{{ wompiData.estado }}</span>
                    </div>
                  </div>
                </template>
                <p v-else style="font-size:13px;color:#a59a8d;margin:8px 0 0">Sin datos de pago disponibles.</p>
              </div>
            </template>
          </template>

        </div>
        <div class="sheet__footer">
          <template v-if="mode === 'view'">
            <button v-if="['pendiente','parcial'].includes(selected.estado)" class="cta-btn" @click="openEdit">Registrar anticipo</button>
            <button v-else class="cta-btn" @click="close">Cerrar</button>
            <button v-if="['pendiente','parcial'].includes(selected.estado)" class="sec-btn" :disabled="saving" @click="marcarPagada">Marcar pagada</button>
            <button v-if="selected.estado !== 'pagada'" class="del-btn" @click="anular">Anular factura</button>
          </template>
          <template v-else>
            <button class="cta-btn" :disabled="saving" @click="save">{{ saving ? 'Guardando…' : 'Guardar' }}</button>
            <button class="sec-btn" @click="cancelForm">Cancelar</button>
          </template>
        </div>
      </div>
    </Transition>

  </div>
</template>

<style scoped>
.fac {
  flex: 1; display: flex; flex-direction: column;
  font-family: Inter, system-ui, sans-serif; background: #FBF6F4; min-height: 100vh; position: relative;
}

.topbar { display: flex; align-items: center; justify-content: space-between; padding: 22px 20px 14px; }
.topbar__title { margin: 0; font-family: Fraunces, Georgia, serif; font-size: 22px; font-weight: 500; color: #1A1714; letter-spacing: -.01em; }
.topbar__btn {
  display: flex; align-items: center; gap: 6px; height: 38px; padding: 0 16px;
  border-radius: 12px; border: none; background: #B0455F; color: #FBF6F4;
  font-size: 13.5px; font-weight: 500; font-family: inherit; cursor: pointer; transition: filter .18s;
}
.topbar__btn:hover { filter: brightness(1.08); }

.stats { display: grid; grid-template-columns: repeat(2,1fr); gap: 10px; padding: 0 20px 16px; }
.stat-card { background: #fff; border-radius: 14px; border: 1px solid rgba(26,23,20,.08); padding: 14px 16px; }
.stat-card--rose   { border-color: rgba(176,69,95,.18); background: #fff5f7; }
.stat-card--warn  { border-color: rgba(217,119,6,.18); background: #fffbf0; }
.stat-card--wompi { border-color: rgba(0,168,150,.18); background: #f0fdfa; }
.stat-card__val { font-family: Fraunces, Georgia, serif; font-size: 22px; font-weight: 600; color: #1A1714; line-height: 1.1; }
.stat-card--rose  .stat-card__val { color: #B0455F; }
.stat-card--warn  .stat-card__val { color: #b45309; }
.stat-card--wompi .stat-card__val { color: #0d7c6e; font-size: 16px; }
.stat-card__lbl { font-size: 12px; color: #a59a8d; margin-top: 3px; }

.toolbar { padding: 0 20px 12px; display: flex; flex-direction: column; gap: 10px; }
.search {
  display: flex; align-items: center; gap: 10px; height: 46px; padding: 0 14px;
  border-radius: 13px; background: #fff; border: 1.5px solid rgba(26,23,20,.12); transition: border-color .2s;
}
.search:focus-within { border-color: #B0455F; }
.search__input { flex: 1; border: none; background: transparent; font-size: 14px; font-family: inherit; color: #1A1714; }
.search__input::placeholder { color: #b7ab9d; }
.search__input:focus { outline: none; }
.search__clear { flex: none; display: flex; align-items: center; border: none; background: none; cursor: pointer; padding: 2px; }
.chips { display: flex; gap: 7px; flex-wrap: wrap; }
.chip {
  height: 32px; padding: 0 14px; border-radius: 20px; border: 1.5px solid rgba(26,23,20,.12);
  background: #fff; font-size: 12.5px; font-weight: 500; color: #8a7f72; cursor: pointer; transition: all .15s;
}
.chip--on { background: #B0455F; border-color: #B0455F; color: #fff; }

.list-wrap { flex: 1; padding: 0 20px 28px; }
.empty { text-align: center; color: #a59a8d; font-size: 14px; padding: 40px 0; }
.table { display: none; }

.card-list { display: flex; flex-direction: column; gap: 10px; }
.fac-card {
  background: #fff; border-radius: 14px; border: 1px solid rgba(26,23,20,.08);
  padding: 14px 16px; cursor: pointer; transition: box-shadow .2s;
}
.fac-card:hover { box-shadow: 0 4px 16px rgba(20,12,4,.10); }
.fac-card__top { display: flex; align-items: flex-start; gap: 10px; }
.fac-card__info { flex: 1; min-width: 0; }
.fac-card__name { font-size: 14px; font-weight: 600; color: #1A1714; }
.fac-card__meta { font-size: 12px; color: #a59a8d; margin-top: 1px; }
.fac-card__right { display: flex; flex-direction: column; align-items: flex-end; gap: 5px; }
.fac-card__total { font-family: Fraunces, Georgia, serif; font-size: 15px; font-weight: 600; color: #1A1714; }
.fac-card__svcs  { font-size: 12px; color: #8a7f72; margin-top: 8px; }

.td-muted { color: #8a7f72 !important; font-size: 13px; }
.td-bold  { font-size: 13.5px; font-weight: 600; color: #1A1714; }
.td-id    { font-size: 12px; color: #a59a8d; font-family: 'SF Mono', monospace; }

.badge { display: inline-block; font-size: 10px; font-weight: 600; padding: 2px 9px; border-radius: 20px; white-space: nowrap; }
.badge--pagada    { background: rgba(22,163,74,.12);  color: #15803d; }
.badge--pendiente { background: rgba(217,119,6,.14);  color: #b45309; }
.badge--parcial   { background: rgba(217,119,6,.10);  color: #b45309; }
.badge--anulada   { background: rgba(26,23,20,.08);   color: #8a7f72; }
.badge--cancelada { background: rgba(26,23,20,.08);   color: #8a7f72; }
.badge--tipo-servicio { background: rgba(99,102,241,.10); color: #4338ca; }
.badge--tipo-anticipo { background: rgba(14,165,233,.10); color: #0369a1; }
.badge--wompi { background: rgba(0,168,150,.12); color: #0d7c6e; }

.wompi-block { margin-top: 4px; }
.wompi-loading { font-size: 13px; color: #a59a8d; margin: 6px 0; }
.wompi-ref {
  display: flex; flex-direction: column; gap: 3px;
  background: rgba(0,168,150,.07); border-radius: 10px; padding: 10px 12px; margin-bottom: 8px;
  border: 1px solid rgba(0,168,150,.15);
}
.wompi-ref__label { font-size: 10px; font-weight: 600; text-transform: uppercase; letter-spacing: .05em; color: #0d7c6e; }
.wompi-ref__val { font-family: 'SF Mono', 'Fira Mono', monospace; font-size: 12px; color: #1A1714; word-break: break-all; margin-top: 1px; }

.chip--wompi.chip--on { background: #0d7c6e; border-color: #0d7c6e; }

.scrim { position: fixed; inset: 0; z-index: 30; background: rgba(26,23,20,.28); }

.sheet {
  position: fixed; left: 0; right: 0; bottom: 0; z-index: 40;
  background: #FBF6F4; border-radius: 24px 24px 0 0; max-height: 92vh;
  display: flex; flex-direction: column; padding-bottom: 64px;
}
.sheet__handle { width: 40px; height: 4px; border-radius: 4px; background: rgba(26,23,20,.15); margin: 12px auto 0; flex: none; }
.sheet__scroll { flex: 1; overflow-y: auto; padding: 16px 22px 8px; scrollbar-width: none; }
.sheet__scroll::-webkit-scrollbar { display: none; }

.sheet__head { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 18px; }
.sheet__headinfo { flex: 1; min-width: 0; }
.sheet__id   { font-size: 11px; color: #a59a8d; font-family: 'SF Mono', monospace; margin-bottom: 2px; }
.sheet__name { font-family: Fraunces, Georgia, serif; font-size: 19px; font-weight: 500; color: #1A1714; }
.sheet__sub  { font-size: 12px; color: #8a7f72; margin-top: 2px; }
.sheet__badges { display: flex; flex-direction: column; align-items: flex-end; gap: 5px; }
.sheet__close {
  flex: none; width: 32px; height: 32px; border-radius: 9px;
  border: 1px solid rgba(26,23,20,.1); background: #fff; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
}

.section-lbl { font-size: 11px; font-weight: 600; letter-spacing: .05em; text-transform: uppercase; color: #a59a8d; margin-bottom: 10px; }
.svc-list { display: flex; flex-direction: column; gap: 8px; margin-bottom: 18px; }
.svc-row { display: flex; align-items: center; gap: 8px; font-size: 13.5px; color: #1A1714; }

.fields { display: flex; flex-direction: column; }
.field-row { display: flex; justify-content: space-between; align-items: center; padding: 9px 0; border-bottom: 1px solid rgba(26,23,20,.06); }
.field-row--total { border-bottom: none; padding-top: 14px; }
.field-lbl { font-size: 12px; color: #a59a8d; }
.field-val  { font-size: 13.5px; font-weight: 500; color: #1A1714; }
.field-lbl--total { font-size: 14px; font-weight: 600; color: #1A1714; }
.field-val--total { font-family: Fraunces, Georgia, serif; font-size: 22px; font-weight: 600; color: #B0455F; }

.form-title { font-family: Fraunces, Georgia, serif; font-size: 18px; font-weight: 500; color: #1A1714; margin-bottom: 16px; }
.form { display: flex; flex-direction: column; gap: 14px; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; min-width: 0; }
.form-row > .form-group { min-width: 0; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 12px; font-weight: 600; color: #8a7f72; text-transform: uppercase; letter-spacing: .04em; }
.form-input, .form-select {
  height: 42px; padding: 0 12px; border-radius: 10px;
  border: 1.5px solid rgba(26,23,20,.14); background: #fff;
  font-size: 14px; font-family: inherit; color: #1A1714; outline: none; transition: border-color .18s;
  width: 100%; box-sizing: border-box;
}
.form-input:focus, .form-select:focus { border-color: #B0455F; }
.pin-input { -webkit-text-security: disc; letter-spacing: 4px; }
.form-error { color: #dc2626; font-size: 12.5px; margin-top: 6px; }

.sheet__footer { flex: none; padding: 14px 22px 20px; border-top: 1px solid rgba(26,23,20,.07); display: flex; flex-direction: column; gap: 10px; }
.cta-btn {
  display: flex; align-items: center; justify-content: center; width: 100%; height: 48px;
  border-radius: 13px; border: none; background: #B0455F; color: #FBF6F4;
  font-family: Fraunces, Georgia, serif; font-size: 15px; font-weight: 500; cursor: pointer; transition: filter .2s;
}
.cta-btn:hover { filter: brightness(1.07); }
.cta-btn:disabled { opacity: .55; cursor: not-allowed; filter: none; }
.del-btn {
  display: flex; align-items: center; justify-content: center; width: 100%; height: 44px;
  border-radius: 13px; border: 1.5px solid rgba(220,38,38,.3); background: transparent;
  color: #dc2626; font-size: 13.5px; font-weight: 500; font-family: inherit; cursor: pointer; transition: background .15s;
}
.del-btn:hover { background: rgba(220,38,38,.06); }
.sec-btn {
  display: flex; align-items: center; justify-content: center; width: 100%; height: 44px;
  border-radius: 13px; border: 1.5px solid rgba(26,23,20,.14); background: transparent;
  color: #1A1714; font-size: 13.5px; font-weight: 500; font-family: inherit; cursor: pointer; transition: background .15s;
}
.sec-btn:hover { background: rgba(26,23,20,.04); }
.sec-btn--danger { border-color: rgba(220,38,38,.3); color: #dc2626; }
.sec-btn--danger:hover { background: rgba(220,38,38,.06); }

.scrim-enter-active, .scrim-leave-active { transition: opacity .28s ease; }
.scrim-enter-from, .scrim-leave-to { opacity: 0; }
.sheet-enter-active, .sheet-leave-active { transition: transform .36s cubic-bezier(.4,0,.2,1); }
.sheet-enter-from, .sheet-leave-to { transform: translateY(100%); }

@media (min-width: 1024px) {
  .topbar   { padding: 24px 28px 18px; }
  .topbar__title { font-size: 26px; }
  .stats    { padding: 0 28px 18px; grid-template-columns: repeat(4,180px); }
  .toolbar  { padding: 0 28px 14px; flex-direction: row; align-items: center; flex-wrap: wrap; gap: 10px; }
  .search   { max-width: 320px; }
  .list-wrap { padding: 0 28px 32px; }
  .card-list { display: none; }

  .table {
    display: table; width: 100%; border-collapse: separate; border-spacing: 0;
    background: #fff; border-radius: 16px; border: 1px solid rgba(26,23,20,.08); overflow: hidden;
  }
  .table thead th {
    text-align: left; padding: 12px 14px;
    font-size: 11px; font-weight: 600; letter-spacing: .04em; text-transform: uppercase;
    color: #a59a8d; background: #FBF6F4; border-bottom: 1px solid rgba(26,23,20,.07);
  }
  .table__row { cursor: pointer; transition: background .15s; }
  .table__row:hover td { background: #fdf7f5; }
  .table__row td { padding: 11px 14px; border-bottom: 1px solid rgba(26,23,20,.06); vertical-align: middle; }
  .table__row:last-child td { border-bottom: none; }

  .sheet {
    left: auto; right: 0; top: 0; bottom: 0; width: 420px; max-height: none;
    border-radius: 0; border-left: 1px solid rgba(26,23,20,.08);
    box-shadow: -12px 0 34px rgba(20,12,4,.10); padding-bottom: 0;
  }
  .sheet__handle { display: none; }
  .sheet-enter-from, .sheet-leave-to { transform: translateX(100%); }
}
</style>
