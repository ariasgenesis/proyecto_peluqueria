<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useAlertDialog } from '@/composables/useAlertDialog'
import {
  getServicios,
  getProductos,
  getServiciosProductos,
  getDashboardAlertas,
  createServicio,
  updateServicio,
  toggleServicio,
  createServicioProducto,
  updateServicioProducto,
  deleteServicioProducto,
  fmtCOP,
} from '@/api/admin'

const loading      = ref(true)
const allServicios = ref([])
const q            = ref('')
const filtroEstado = ref('todos')
const selected     = ref(null)
const mode         = ref('view') // 'view' | 'create' | 'edit'
const draft        = ref({})
const productos    = ref([])
const relaciones   = ref({})
const saving       = ref(false)
const formError    = ref('')
const productLinkSearch = ref('')
const stockAlerts = ref([])
const { alertDialog, confirmDialog } = useAlertDialog()
let pollBusy = false
let pollTimer = null

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

function stateChanges(next) {
  const current = new Map(allServicios.value.map(s => [s.id_servicio, s]))
  return next
    .filter(s => current.has(s.id_servicio) && current.get(s.id_servicio).estado !== s.estado)
    .map(s => ({
      id_servicio: s.id_servicio,
      nombre: s.nombre,
      estado_anterior: current.get(s.id_servicio).estado,
      estado_nuevo: s.estado,
      productos_bloqueados: [],
    }))
}

async function refreshServicios({ notify = false } = {}) {
  const [serviciosData, alertasData] = await Promise.all([getServicios(), getDashboardAlertas()])
  const cambios = notify ? stateChanges(serviciosData) : []
  allServicios.value = serviciosData
  stockAlerts.value = alertasData.servicios_inactivos_stock || []
  if (selected.value) {
    selected.value = serviciosData.find(s => s.id_servicio === selected.value.id_servicio) || selected.value
  }
  await showStockServiceAlert(cambios)
}

async function pollServicios() {
  if (pollBusy) return
  pollBusy = true
  try { await refreshServicios({ notify: true }) }
  catch (_) {}
  finally { pollBusy = false }
}

onMounted(async () => {
  try {
    await refreshServicios()
    pollTimer = window.setInterval(pollServicios, 8000)
  }
  finally { loading.value = false }
})

onBeforeUnmount(() => {
  if (pollTimer) window.clearInterval(pollTimer)
})

const servicios = computed(() => {
  let list = allServicios.value
  const s = q.value.trim().toLowerCase()
  if (s) list = list.filter(sv =>
    (sv.nombre || '').toLowerCase().includes(s) ||
    (sv.descripcion || '').toLowerCase().includes(s)
  )
  if (filtroEstado.value !== 'todos') list = list.filter(sv => sv.estado === filtroEstado.value)
  return list
})

const stats = computed(() => ({
  total:    allServicios.value.length,
  activos:  allServicios.value.filter(s => s.estado === 'activo').length,
  inactivos: allServicios.value.filter(s => s.estado === 'inactivo').length,
}))

const sheetOpen = computed(() => selected.value !== null || mode.value === 'create')
const productosActivos = computed(() => productos.value.filter(p => p.estado !== 'inactivo'))
const productosFiltrados = computed(() => {
  const term = productLinkSearch.value.trim().toLowerCase()
  if (!term) return productosActivos.value
  return productosActivos.value.filter(p =>
    String(p.id_producto).includes(term) ||
    (p.nombre || '').toLowerCase().includes(term)
  )
})
const productosSeleccionados = computed(() => {
  const serviceId = selected.value?.id_servicio
  return serviceId ? relaciones.value[serviceId] || [] : []
})

function productoNombre(id) {
  const p = productos.value.find(x => x.id_producto === Number(id))
  return p ? p.nombre : `Producto #${id}`
}

async function loadProductos() {
  if (!productos.value.length) productos.value = await getProductos({ estado: 'activo' })
}

async function loadStockAlerts() {
  const alertas = await getDashboardAlertas()
  stockAlerts.value = alertas.servicios_inactivos_stock || []
}

async function loadRelaciones(servicioId, force = false) {
  if (!servicioId || (!force && relaciones.value[servicioId])) return relaciones.value[servicioId] || []
  const rows = await getServiciosProductos({ servicio_id: servicioId })
  relaciones.value = { ...relaciones.value, [servicioId]: rows }
  return rows
}

function normalizeProductosDraft(rows) {
  const merged = new Map()
  for (const row of rows || []) {
    const productoId = Number(row.producto_id)
    if (!productoId) continue
    merged.set(productoId, { producto_id: productoId, cantidad: 1 })
  }
  return Array.from(merged.values())
}

async function syncProductos(servicioId, rows) {
  const next = normalizeProductosDraft(rows)
  const current = await loadRelaciones(servicioId, true)
  const currentByProduct = new Map(current.map(r => [Number(r.producto_id), r]))
  const nextByProduct = new Map(next.map(r => [Number(r.producto_id), r]))
  const cambios = []

  for (const rel of current) {
    if (!nextByProduct.has(Number(rel.producto_id))) {
      const result = await deleteServicioProducto(rel.id_servicio_producto)
      cambios.push(...(result.servicios_actualizados || []))
    }
  }
  for (const rel of next) {
    const existing = currentByProduct.get(Number(rel.producto_id))
    const payload = { servicio_id: servicioId, producto_id: rel.producto_id, cantidad: rel.cantidad }
    if (!existing) {
      const result = await createServicioProducto(payload)
      cambios.push(...(result.servicios_actualizados || []))
    } else if (Number(existing.cantidad) !== rel.cantidad) {
      const result = await updateServicioProducto(existing.id_servicio_producto, payload)
      cambios.push(...(result.servicios_actualizados || []))
    }
  }

  await loadRelaciones(servicioId, true)
  return cambios
}

function addProductoRow() {
  draft.value.productos = [...(draft.value.productos || []), { producto_id: '' }]
}

function removeProductoRow(index) {
  draft.value.productos = (draft.value.productos || []).filter((_row, i) => i !== index)
}

async function open(s) {
  selected.value = s; mode.value = 'view'; formError.value = ''
  await Promise.all([loadProductos(), loadRelaciones(s.id_servicio)])
}
async function openCreate() {
  selected.value = null
  productLinkSearch.value = ''
  draft.value = { nombre: '', descripcion: '', imagen: '', precio: '', duracion: 60, estado: 'activo', productos: [] }
  mode.value = 'create'; formError.value = ''
  await loadProductos()
}
async function openEdit() {
  await Promise.all([loadProductos(), loadRelaciones(selected.value.id_servicio)])
  productLinkSearch.value = ''
  draft.value = {
    nombre: selected.value.nombre,
    descripcion: selected.value.descripcion || '',
    imagen: selected.value.imagen || '',
    precio: selected.value.precio,
    duracion: selected.value.duracion,
    estado: selected.value.estado,
    productos: productosSeleccionados.value.map(r => ({ producto_id: r.producto_id })),
  }
  mode.value = 'edit'; formError.value = ''
}
function cancelForm() { mode.value === 'edit' ? (mode.value = 'view') : close() }
function close() { selected.value = null; mode.value = 'view'; formError.value = '' }

async function save() {
  formError.value = ''
  if (!draft.value.nombre?.trim()) { formError.value = 'El nombre es requerido'; return }
  if (!draft.value.precio && draft.value.precio !== 0) { formError.value = 'El precio es requerido'; return }
  if (!draft.value.duracion || draft.value.duracion < 1) { formError.value = 'La duración mínima es 1 minuto'; return }
  saving.value = true
  try {
    const payload = {
      nombre: draft.value.nombre.trim(),
      descripcion: draft.value.descripcion || '',
      imagen: draft.value.imagen || '',
      precio: Number(draft.value.precio),
      duracion: Number(draft.value.duracion),
      estado: draft.value.estado,
    }
    if (mode.value === 'create') {
      const sv = await createServicio(payload)
      const cambios = await syncProductos(sv.id_servicio, draft.value.productos)
      allServicios.value = await getServicios()
      await loadStockAlerts()
      close()
      await showStockServiceAlert(cambios)
    } else {
      const sv = await updateServicio(selected.value.id_servicio, payload)
      const cambios = await syncProductos(sv.id_servicio, draft.value.productos)
      allServicios.value = await getServicios()
      const refreshed = allServicios.value.find(x => x.id_servicio === sv.id_servicio) || sv
      await loadStockAlerts()
      selected.value = refreshed; mode.value = 'view'
      await showStockServiceAlert(cambios)
    }
  } catch (e) { formError.value = e.response?.data?.message || 'Error al guardar' }
  finally { saving.value = false }
}

async function toggleEstado() {
  if (!selected.value) return
  const nombre = selected.value.nombre
  const accion = selected.value.estado === 'activo' ? 'desactivar' : 'activar'
  const ok = await confirmDialog({
    title: `${accion.charAt(0).toUpperCase() + accion.slice(1)} servicio`,
    message: `${accion.charAt(0).toUpperCase() + accion.slice(1)} el servicio "${nombre}"?`,
    variant: 'warning',
    confirmText: accion.charAt(0).toUpperCase() + accion.slice(1),
  })
  if (!ok) return
  try {
    const sv = await toggleServicio(selected.value.id_servicio)
    const idx = allServicios.value.findIndex(x => x.id_servicio === sv.id_servicio)
    if (idx !== -1) allServicios.value[idx] = sv
    selected.value = sv
    await loadStockAlerts()
  } catch (e) { await alertDialog({ title: 'No se pudo cambiar el estado', message: e.response?.data?.message || 'Error al cambiar estado', variant: 'danger' }) }
}
</script>

<template>
  <div class="svc">

    <div class="topbar">
      <h1 class="topbar__title">Servicios</h1>
      <button class="topbar__btn" @click="openCreate">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
        Nuevo
      </button>
    </div>

    <!-- stats strip -->
    <div class="stats">
      <div class="stat-card">
        <div class="stat-card__val">{{ stats.total }}</div>
        <div class="stat-card__lbl">Total</div>
      </div>
      <div class="stat-card stat-card--ok">
        <div class="stat-card__val">{{ stats.activos }}</div>
        <div class="stat-card__lbl">Activos</div>
      </div>
      <div class="stat-card stat-card--off">
        <div class="stat-card__val">{{ stats.inactivos }}</div>
        <div class="stat-card__lbl">Inactivos</div>
      </div>
    </div>

    <!-- search + filtros -->
    <div v-if="stockAlerts.length" class="stock-alert">
      <div class="stock-alert__icon">!</div>
      <div class="stock-alert__body">
        <strong>{{ stockAlerts.length }} servicio(s) inactivo(s) por inventario</strong>
        <span>{{ stockAlerts.slice(0, 3).map(a => `${a.nombre} (${a.productos})`).join(' · ') }}</span>
      </div>
    </div>

    <div class="toolbar">
      <div class="search">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.35-4.35"/></svg>
        <input v-model="q" class="search__input" type="text" placeholder="Buscar servicio…" />
        <button v-if="q" class="search__clear" @click="q = ''">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
        </button>
      </div>
      <div class="chips">
        <button v-for="f in ['todos','activo','inactivo']" :key="f"
          class="chip" :class="{ 'chip--on': filtroEstado === f }"
          @click="filtroEstado = f">
          {{ f === 'todos' ? 'Todos' : f === 'activo' ? 'Activos' : 'Inactivos' }}
        </button>
      </div>
    </div>

    <!-- lista -->
    <div class="list-wrap">
      <p v-if="!loading && !servicios.length" class="empty">No se encontraron servicios.</p>

      <!-- tabla desktop -->
      <table class="table">
        <thead>
          <tr>
            <th>Servicio</th>
            <th>Descripción</th>
            <th>Duración</th>
            <th>Precio</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading"><td colspan="5" style="padding:32px;text-align:center;color:#a59a8d">Cargando…</td></tr>
          <tr v-for="sv in servicios" :key="sv.id_servicio" class="table__row" @click="open(sv)">
            <td>
              <div class="svc-cell">
                <div class="svc-icon">✂</div>
                <div class="svc-name">{{ sv.nombre }}</div>
              </div>
            </td>
            <td class="td-muted">{{ sv.descripcion || '—' }}</td>
            <td class="td-muted">{{ sv.duracion }} min</td>
            <td class="td-price">{{ fmtCOP(sv.precio) }}</td>
            <td>
              <span class="estado" :class="'estado--' + sv.estado">
                {{ sv.estado === 'activo' ? 'Activo' : 'Inactivo' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- tarjetas mobile -->
      <div class="card-list">
        <div v-for="sv in servicios" :key="sv.id_servicio" class="svc-card" @click="open(sv)">
          <div class="svc-card__top">
            <div class="svc-card__icon">✂</div>
            <div class="svc-card__info">
              <div class="svc-card__name">{{ sv.nombre }}</div>
              <div class="svc-card__desc">{{ sv.descripcion || '—' }}</div>
            </div>
            <span class="estado" :class="'estado--' + sv.estado">{{ sv.estado === 'activo' ? 'Activo' : 'Inactivo' }}</span>
          </div>
          <div class="svc-card__meta">
            <span>{{ sv.duracion }} min</span>
            <span class="svc-card__price">{{ fmtCOP(sv.precio) }}</span>
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
            <div class="form-title">{{ mode === 'create' ? 'Nuevo servicio' : 'Editar servicio' }}</div>
            <div class="form">
              <div class="form-group">
                <label class="form-label">Nombre *</label>
                <input class="form-input" v-model="draft.nombre" placeholder="Ej: Corte de cabello" />
              </div>
              <div class="form-group">
                <label class="form-label">Descripción</label>
                <textarea class="form-input form-textarea" v-model="draft.descripcion" placeholder="Descripción del servicio…" rows="3"></textarea>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">Precio *</label>
                  <input class="form-input" v-model="draft.precio" type="number" min="0" step="1000" placeholder="0" />
                </div>
                <div class="form-group">
                  <label class="form-label">Duración (min) *</label>
                  <input class="form-input" v-model="draft.duracion" type="number" min="1" placeholder="60" />
                </div>
              </div>
              <div class="form-group">
                <label class="form-label">Estado</label>
                <select class="form-select" v-model="draft.estado">
                  <option value="activo">Activo</option>
                  <option value="inactivo">Inactivo</option>
                </select>
              </div>
              <div class="form-group">
                <label class="form-label">Productos vinculados</label>
                <div class="product-links">
                  <div class="search search--products">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.35-4.35"/></svg>
                    <input v-model="productLinkSearch" class="search__input" type="text" placeholder="Buscar producto por nombre o ID..." />
                  </div>
                  <div v-for="(row, index) in draft.productos" :key="index" class="product-link-row">
                    <select class="form-select" v-model.number="row.producto_id">
                      <option value="">Seleccionar producto...</option>
                      <option v-for="p in productosFiltrados" :key="p.id_producto" :value="p.id_producto">
                        #{{ p.id_producto }} · {{ p.nombre }} · stock {{ p.stock }}
                      </option>
                    </select>
                    <button class="icon-btn" type="button" @click="removeProductoRow(index)">×</button>
                  </div>
                  <button class="add-link-btn" type="button" @click="addProductoRow">Agregar producto</button>
                </div>
              </div>
            </div>
            <p v-if="formError" class="form-error">{{ formError }}</p>
          </template>

          <!-- VIEW MODE -->
          <template v-else>
            <div class="sheet__head">
              <div class="svc-icon-lg">✂</div>
              <div class="sheet__headinfo">
                <div class="sheet__name">{{ selected.nombre }}</div>
                <div class="sheet__esp">{{ selected.duracion }} min</div>
              </div>
              <button class="sheet__close" @click="close">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
              </button>
            </div>

            <div class="price-box">
              <div class="price-box__lbl">Precio</div>
              <div class="price-box__val">{{ fmtCOP(selected.precio) }}</div>
            </div>

            <div class="fields">
              <div class="field-row">
                <span class="field-lbl">Descripción</span>
                <span class="field-val">{{ selected.descripcion || '—' }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Duración</span>
                <span class="field-val">{{ selected.duracion }} minutos</span>
              </div>
              <div class="field-row field-row--block">
                <span class="field-lbl">Productos</span>
                <span class="field-val">
                  <template v-if="productosSeleccionados.length">
                    <span v-for="p in productosSeleccionados" :key="p.id_servicio_producto" class="product-pill">
                      {{ productoNombre(p.producto_id) }}
                    </span>
                  </template>
                  <template v-else>Sin productos vinculados</template>
                </span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Estado</span>
                <span class="estado" :class="'estado--' + selected.estado">
                  {{ selected.estado === 'activo' ? 'Activo' : 'Inactivo' }}
                </span>
              </div>
            </div>
          </template>

        </div>

        <div class="sheet__footer">
          <template v-if="mode === 'view'">
            <button class="cta-btn" @click="openEdit">Editar servicio</button>
            <button class="toggle-btn" :class="selected?.estado === 'activo' ? 'toggle-btn--off' : 'toggle-btn--on'" @click="toggleEstado">
              {{ selected?.estado === 'activo' ? 'Desactivar servicio' : 'Activar servicio' }}
            </button>
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
.svc {
  flex: 1;
  display: flex;
  flex-direction: column;
  font-family: Inter, system-ui, sans-serif;
  background: #FBF6F4;
  min-height: 100vh;
  position: relative;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 22px 20px 14px;
}
.topbar__title {
  margin: 0;
  font-family: Fraunces, Georgia, serif;
  font-size: 22px;
  font-weight: 500;
  color: #1A1714;
  letter-spacing: -.01em;
}
.topbar__btn {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  height: 38px;
  padding: 0 16px;
  border-radius: 11px;
  border: none;
  background: #B0455F;
  color: #FBF6F4;
  font-size: 13px;
  font-weight: 500;
  font-family: inherit;
  cursor: pointer;
  transition: filter .2s;
}
.topbar__btn:hover { filter: brightness(1.08); }

/* stats */
.stats {
  display: flex;
  gap: 10px;
  padding: 0 20px 14px;
  overflow-x: auto;
}
.stat-card {
  flex: 1;
  min-width: 80px;
  background: #fff;
  border-radius: 14px;
  border: 1px solid rgba(26,23,20,.08);
  padding: 14px 16px;
  text-align: center;
}
.stat-card--ok   { border-color: rgba(22,163,74,.2); }
.stat-card--off  { border-color: rgba(26,23,20,.12); }
.stat-card__val { font-family: Fraunces, Georgia, serif; font-size: 24px; font-weight: 600; color: #1A1714; }
.stat-card__lbl { font-size: 11px; color: #a59a8d; margin-top: 3px; }

/* toolbar */
.toolbar { padding: 0 20px 14px; display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }
.stock-alert {
  display: flex;
  gap: 10px;
  align-items: flex-start;
  margin: 0 20px 14px;
  padding: 12px 14px;
  border-radius: 13px;
  background: #fff7f2;
  border: 1px solid rgba(217,119,6,.18);
  color: #6b3d05;
}
.stock-alert__icon {
  flex: none;
  width: 22px;
  height: 22px;
  border-radius: 999px;
  background: rgba(217,119,6,.14);
  color: #b45309;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 700;
}
.stock-alert__body {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 12px;
}
.stock-alert__body strong { color: #1A1714; font-size: 13px; }
.stock-alert__body span { color: #8a5b12; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.search {
  flex: 1;
  min-width: 200px;
  display: flex;
  align-items: center;
  gap: 10px;
  height: 44px;
  padding: 0 14px;
  border-radius: 13px;
  background: #fff;
  border: 1.5px solid rgba(26,23,20,.12);
  transition: border-color .2s;
}
.search:focus-within { border-color: #B0455F; }
.search__input {
  flex: 1;
  border: none;
  background: transparent;
  font-size: 14px;
  font-family: inherit;
  color: #1A1714;
}
.search__input:focus { outline: none; }
.search__clear {
  display: flex; align-items: center;
  border: none; background: none; cursor: pointer; padding: 2px;
}
.search--products {
  min-width: 0;
  width: 100%;
  height: 40px;
}
.chips { display: flex; gap: 8px; }
.chip {
  height: 34px; padding: 0 14px;
  border-radius: 20px; border: 1px solid rgba(26,23,20,.10);
  background: #fff; color: #6b6258; font-size: 12px; font-weight: 500;
  cursor: pointer; transition: .18s; font-family: inherit;
}
.chip:hover { background: #F6F0ED; }
.chip--on { background: #1A1714; color: #FBF6F4; border-color: #1A1714; }

/* lista */
.list-wrap { flex: 1; padding: 0 20px 28px; }
.empty { text-align: center; color: #a59a8d; font-size: 14px; padding: 40px 0; }
.table { display: none; }

/* tarjetas mobile */
.card-list { display: flex; flex-direction: column; gap: 10px; }
.svc-card {
  background: #fff;
  border-radius: 14px;
  border: 1px solid rgba(26,23,20,.08);
  padding: 14px 16px;
  cursor: pointer;
  transition: box-shadow .2s;
}
.svc-card:hover { box-shadow: 0 4px 16px rgba(20,12,4,.10); }
.svc-card__top { display: flex; align-items: center; gap: 12px; }
.svc-card__icon { font-size: 20px; flex: none; width: 40px; height: 40px; border-radius: 12px; background: rgba(176,69,95,.1); display: flex; align-items: center; justify-content: center; }
.svc-card__info { flex: 1; min-width: 0; }
.svc-card__name { font-size: 14px; font-weight: 600; color: #1A1714; }
.svc-card__desc { font-size: 12px; color: #8a7f72; margin-top: 1px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.svc-card__meta { display: flex; align-items: center; justify-content: space-between; margin-top: 10px; font-size: 12px; color: #a59a8d; }
.svc-card__price { font-weight: 700; color: #B0455F; font-size: 13px; }

/* estado badges */
.estado {
  display: inline-block;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 9px;
  border-radius: 20px;
}
.estado--activo   { background: rgba(22,163,74,.12); color: #15803d; }
.estado--inactivo { background: rgba(26,23,20,.08); color: #8a7f72; }

/* tabla desktop */
.svc-cell { display: flex; align-items: center; gap: 10px; }
.svc-icon { font-size: 16px; width: 32px; height: 32px; border-radius: 10px; background: rgba(176,69,95,.1); display: flex; align-items: center; justify-content: center; flex: none; }
.svc-name { font-size: 13.5px; font-weight: 600; color: #1A1714; }
.td-muted { color: #8a7f72 !important; font-size: 13px; }
.td-price { font-weight: 700; color: #B0455F; font-size: 13px; }

/* scrim */
.scrim {
  position: fixed;
  inset: 0;
  z-index: 30;
  background: rgba(26,23,20,.28);
}

/* sheet */
.sheet {
  position: fixed;
  left: 0; right: 0; bottom: 0;
  z-index: 40;
  background: #FBF6F4;
  border-radius: 24px 24px 0 0;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  padding-bottom: 64px;
}
.sheet__handle {
  width: 40px; height: 4px;
  border-radius: 4px;
  background: rgba(26,23,20,.15);
  margin: 12px auto 0;
  flex: none;
}
.sheet__scroll {
  flex: 1;
  overflow-y: auto;
  padding: 16px 22px 8px;
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.sheet__scroll::-webkit-scrollbar { display: none; }

.sheet__head { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 16px; }
.svc-icon-lg { font-size: 24px; width: 52px; height: 52px; border-radius: 16px; background: rgba(176,69,95,.12); display: flex; align-items: center; justify-content: center; flex: none; }
.sheet__headinfo { flex: 1; min-width: 0; }
.sheet__name { font-family: Fraunces, Georgia, serif; font-size: 19px; font-weight: 500; color: #1A1714; }
.sheet__esp { font-size: 13px; color: #8a7f72; margin-top: 2px; }
.sheet__close {
  flex: none; width: 32px; height: 32px;
  border-radius: 9px; border: 1px solid rgba(26,23,20,.1);
  background: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center;
}

.price-box {
  background: linear-gradient(135deg, rgba(176,69,95,.08), rgba(176,69,95,.04));
  border: 1px solid rgba(176,69,95,.15);
  border-radius: 14px; padding: 16px 20px; margin-bottom: 18px; text-align: center;
}
.price-box__lbl { font-size: 11px; font-weight: 600; letter-spacing: .05em; text-transform: uppercase; color: #a59a8d; }
.price-box__val { font-family: Fraunces, Georgia, serif; font-size: 32px; font-weight: 600; color: #B0455F; margin-top: 4px; }

.fields { display: flex; flex-direction: column; margin-bottom: 18px; }
.field-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 9px 0;
  border-bottom: 1px solid rgba(26,23,20,.06);
}
.field-row:last-child { border-bottom: none; }
.field-row--block { align-items: flex-start; gap: 12px; }
.field-row--block .field-val { display: flex; flex-wrap: wrap; justify-content: flex-end; gap: 6px; }
.field-lbl { font-size: 12px; color: #a59a8d; }
.field-val { font-size: 13.5px; font-weight: 500; color: #1A1714; max-width: 65%; text-align: right; }
.product-pill { display: inline-flex; align-items: center; padding: 4px 9px; border-radius: 999px; background: rgba(26,23,20,.06); color: #6b6258; font-size: 12px; }

.sheet__footer {
  flex: none;
  padding: 14px 22px 20px;
  border-top: 1px solid rgba(26,23,20,.07);
  display: flex;
  flex-direction: column;
  gap: 10px;
}

/* form */
.form-title { font-family: Fraunces, Georgia, serif; font-size: 19px; font-weight: 500; color: #1A1714; margin-bottom: 18px; }
.form { display: flex; flex-direction: column; gap: 14px; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 600; color: #a59a8d; text-transform: uppercase; letter-spacing: .04em; }
.form-input, .form-select {
  height: 44px; padding: 0 12px; border-radius: 11px;
  border: 1.5px solid rgba(26,23,20,.14); background: #fff;
  font-size: 14px; font-family: inherit; color: #1A1714; transition: border-color .2s;
  box-sizing: border-box; width: 100%;
}
.form-textarea {
  height: auto;
  padding: 10px 12px;
  resize: vertical;
  min-height: 80px;
}
.product-links { display: flex; flex-direction: column; gap: 8px; }
.product-link-row { display: grid; grid-template-columns: minmax(0, 1fr) 36px; gap: 8px; align-items: center; }
.icon-btn {
  width: 36px; height: 36px; border-radius: 10px; border: 1px solid rgba(26,23,20,.12);
  background: #fff; color: #8a7f72; cursor: pointer; font-size: 18px; line-height: 1;
}
.icon-btn:hover { border-color: rgba(176,69,95,.35); color: #B0455F; }
.add-link-btn {
  height: 38px; border-radius: 11px; border: 1.5px dashed rgba(176,69,95,.35);
  background: rgba(176,69,95,.04); color: #B0455F; font-family: inherit; font-weight: 600; cursor: pointer;
}
.add-link-btn:hover { background: rgba(176,69,95,.08); }
.form-input:focus, .form-select:focus { outline: none; border-color: #B0455F; }
.form-error { font-size: 12px; color: #B0455F; margin-top: 8px; }

/* buttons */
.cta-btn {
  display: flex; align-items: center; justify-content: center;
  width: 100%; height: 48px; border-radius: 13px; border: none;
  background: #B0455F; color: #FBF6F4;
  font-family: Fraunces, Georgia, serif; font-size: 15px; font-weight: 500;
  cursor: pointer; transition: filter .2s;
}
.cta-btn:hover { filter: brightness(1.07); }
.cta-btn:disabled { opacity: .55; cursor: not-allowed; }

.toggle-btn {
  display: flex; align-items: center; justify-content: center;
  width: 100%; height: 44px; border-radius: 11px; cursor: pointer;
  font-family: inherit; font-size: 14px; font-weight: 500; transition: background .15s;
}
.toggle-btn--off {
  border: 1.5px solid rgba(176,69,95,.3); background: transparent; color: #B0455F;
}
.toggle-btn--off:hover { background: rgba(176,69,95,.06); }
.toggle-btn--on {
  border: 1.5px solid rgba(22,163,74,.3); background: transparent; color: #15803d;
}
.toggle-btn--on:hover { background: rgba(22,163,74,.06); }

.sec-btn {
  display: flex; align-items: center; justify-content: center;
  width: 100%; height: 44px; border-radius: 13px;
  border: 1.5px solid rgba(26,23,20,.14); background: transparent;
  color: #1A1714; font-size: 13.5px; font-weight: 500; font-family: inherit; cursor: pointer;
  transition: background .15s;
}
.sec-btn:hover { background: rgba(26,23,20,.04); }

/* transitions */
.scrim-enter-active, .scrim-leave-active { transition: opacity .28s ease; }
.scrim-enter-from, .scrim-leave-to { opacity: 0; }
.sheet-enter-active, .sheet-leave-active { transition: transform .36s cubic-bezier(.4,0,.2,1); }
.sheet-enter-from, .sheet-leave-to { transform: translateY(100%); }

/* ===== DESKTOP ===== */
@media (min-width: 1024px) {
  .topbar   { padding: 24px 28px 18px; }
  .topbar__title { font-size: 26px; }
  .stats    { padding: 0 28px 16px; }
  .stock-alert { margin: 0 28px 14px; }
  .toolbar  { padding: 0 28px 14px; }
  .list-wrap { padding: 0 28px 32px; }
  .card-list { display: none; }

  .table {
    display: table;
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    background: #fff;
    border-radius: 16px;
    border: 1px solid rgba(26,23,20,.08);
    overflow: hidden;
  }
  .table thead th {
    text-align: left;
    padding: 12px 16px;
    font-size: 11px;
    font-weight: 600;
    letter-spacing: .04em;
    text-transform: uppercase;
    color: #a59a8d;
    background: #FBF6F4;
    border-bottom: 1px solid rgba(26,23,20,.07);
  }
  .table__row { cursor: pointer; transition: background .15s; }
  .table__row:hover td { background: #fdf7f5; }
  .table__row td {
    padding: 13px 16px;
    border-bottom: 1px solid rgba(26,23,20,.06);
    vertical-align: middle;
    font-size: 13.5px;
    color: #1A1714;
  }
  .table__row:last-child td { border-bottom: none; }

  /* drawer desktop */
  .sheet {
    left: auto; right: 0; top: 0; bottom: 0;
    width: 400px;
    max-height: none;
    border-radius: 0;
    border-left: 1px solid rgba(26,23,20,.08);
    box-shadow: -12px 0 34px rgba(20,12,4,.10);
    padding-bottom: 0;
  }
  .sheet__handle { display: none; }
  .sheet-enter-from, .sheet-leave-to { transform: translateX(100%); }
}
</style>
