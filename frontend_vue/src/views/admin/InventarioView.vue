<script setup>
import { computed, onMounted, ref } from 'vue'
import { getProductos, agregarStock, descontarStock, createProducto, updateProducto, deleteProducto, fmtCOP } from '@/api/admin'

const loading      = ref(true)
const allProductos = ref([])
const q            = ref('')
const filtroEstado = ref('todos')
const selected     = ref(null)
const mode         = ref('view') // 'view' | 'create' | 'edit'
const draft        = ref({})
const saving       = ref(false)
const formError    = ref('')
const ajuste       = ref(0)
const pinAjuste    = ref('')
const ajusteError  = ref('')

onMounted(async () => {
  try { allProductos.value = await getProductos() }
  finally { loading.value = false }
})

function estadoStock(p) {
  if (p.stock === 0)            return 'agotado'
  if (p.stock < p.stock_minimo) return 'bajo'
  return 'ok'
}

const productos = computed(() => {
  let list = allProductos.value
  const s = q.value.trim().toLowerCase()
  if (s) list = list.filter(p => p.nombre.toLowerCase().includes(s) || (p.tipo_control || '').toLowerCase().includes(s))
  if (filtroEstado.value !== 'todos') list = list.filter(p => estadoStock(p) === filtroEstado.value)
  return list
})

const stats = computed(() => ({
  total:   allProductos.value.length,
  bajo:    allProductos.value.filter(p => estadoStock(p) === 'bajo').length,
  agotado: allProductos.value.filter(p => estadoStock(p) === 'agotado').length,
}))

const sheetOpen = computed(() => selected.value !== null || mode.value === 'create')

function open(p) { selected.value = p; mode.value = 'view'; ajuste.value = 0; pinAjuste.value = ''; ajusteError.value = ''; formError.value = '' }
function openCreate() {
  selected.value = null
  draft.value = { nombre: '', precio: '', stock: 0, stock_minimo: 5, tipo_control: 'manual', estado: 'activo' }
  mode.value = 'create'; formError.value = ''
}
function openEdit() {
  draft.value = { nombre: selected.value.nombre, precio: selected.value.precio, stock_minimo: selected.value.stock_minimo, tipo_control: selected.value.tipo_control, estado: selected.value.estado }
  mode.value = 'edit'; formError.value = ''
}
function cancelForm() { mode.value === 'edit' ? (mode.value = 'view') : close() }
function close() { selected.value = null; mode.value = 'view'; formError.value = '' }

async function save() {
  formError.value = ''
  if (!draft.value.nombre?.trim()) { formError.value = 'Nombre es requerido'; return }
  if (!draft.value.precio && draft.value.precio !== 0) { formError.value = 'Precio es requerido'; return }
  saving.value = true
  try {
    const payload = { ...draft.value, precio: Number(draft.value.precio), stock_minimo: Number(draft.value.stock_minimo) }
    if (mode.value === 'create') {
      payload.stock = Number(draft.value.stock) || 0
      const p = await createProducto(payload)
      allProductos.value.unshift(p); close()
    } else {
      const p = await updateProducto(selected.value.id_producto, payload)
      const idx = allProductos.value.findIndex(x => x.id_producto === p.id_producto)
      if (idx !== -1) allProductos.value[idx] = p
      selected.value = p; mode.value = 'view'
    }
  } catch (e) { formError.value = e.response?.data?.message || 'Error al guardar' }
  finally { saving.value = false }
}

async function remove() {
  if (!confirm(`¿Desactivar "${selected.value.nombre}"?`)) return
  try {
    await deleteProducto(selected.value.id_producto)
    allProductos.value = allProductos.value.filter(p => p.id_producto !== selected.value.id_producto)
    close()
  } catch (e) { alert(e.response?.data?.message || 'Error al eliminar') }
}

async function guardarAjuste() {
  ajusteError.value = ''
  if (!ajuste.value) return
  if (!pinAjuste.value.match(/^\d{4}$/)) { ajusteError.value = 'PIN de 4 dígitos requerido'; return }
  saving.value = true
  try {
    const id = selected.value.id_producto
    const fn = ajuste.value > 0 ? agregarStock : descontarStock
    const updated = await fn(id, Math.abs(ajuste.value), pinAjuste.value)
    const nuevoStock = updated.stock ?? (selected.value.stock + ajuste.value)
    const idx = allProductos.value.findIndex(p => p.id_producto === id)
    if (idx !== -1) allProductos.value[idx] = { ...allProductos.value[idx], stock: nuevoStock }
    selected.value = { ...selected.value, stock: nuevoStock }
    ajuste.value = 0; pinAjuste.value = ''
  } catch (e) { ajusteError.value = e.response?.data?.message || 'Error al ajustar stock' }
  finally { saving.value = false }
}
</script>

<template>
  <div class="inv">

    <div class="topbar">
      <h1 class="topbar__title">Inventario</h1>
      <button class="topbar__btn" @click="openCreate">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
        Agregar
      </button>
    </div>

    <!-- stats strip -->
    <div class="stats">
      <div class="stat-card">
        <div class="stat-card__val">{{ stats.total }}</div>
        <div class="stat-card__lbl">Productos</div>
      </div>
      <div class="stat-card stat-card--warn">
        <div class="stat-card__val">{{ stats.bajo }}</div>
        <div class="stat-card__lbl">Stock bajo</div>
      </div>
      <div class="stat-card stat-card--danger">
        <div class="stat-card__val">{{ stats.agotado }}</div>
        <div class="stat-card__lbl">Agotados</div>
      </div>
    </div>

    <!-- search + filtros -->
    <div class="toolbar">
      <div class="search">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.35-4.35"/></svg>
        <input v-model="q" class="search__input" type="text" readonly spellcheck="false" placeholder="Buscar producto o categoría…" @focus="$event.target.removeAttribute('readonly')" />
        <button v-if="q" class="search__clear" @click="q = ''">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
        </button>
      </div>
      <div class="chips">
        <button v-for="f in ['todos','ok','bajo','agotado']" :key="f"
          class="chip" :class="{ 'chip--on': filtroEstado === f }"
          @click="filtroEstado = f">
          {{ f === 'todos' ? 'Todos' : f === 'ok' ? 'En stock' : f === 'bajo' ? 'Stock bajo' : 'Agotados' }}
        </button>
      </div>
    </div>

    <!-- lista -->
    <div class="list-wrap">
      <p v-if="!loading && !productos.length" class="empty">Sin resultados.</p>

      <!-- tabla desktop -->
      <table class="table">
        <thead>
          <tr>
            <th>Producto</th>
            <th>Tipo control</th>
            <th class="tc">Stock</th>
            <th class="tc">Mínimo</th>
            <th>Precio unit.</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading"><td colspan="6" style="padding:32px;text-align:center;color:#a59a8d">Cargando…</td></tr>
          <tr v-for="p in productos" :key="p.id_producto" class="table__row" @click="open(p)">
            <td class="td-name">{{ p.nombre }}</td>
            <td class="td-muted">{{ p.tipo_control || '—' }}</td>
            <td class="tc" :class="{ 'td-danger': p.stock === 0, 'td-warn': p.stock < p.stock_minimo && p.stock > 0 }">
              <strong>{{ p.stock }}</strong>
            </td>
            <td class="tc td-muted">{{ p.stock_minimo }}</td>
            <td class="td-muted">{{ fmtCOP(p.precio) }}</td>
            <td>
              <span class="badge" :class="'badge--' + estadoStock(p)">
                {{ estadoStock(p) === 'ok' ? 'En stock' : estadoStock(p) === 'bajo' ? 'Stock bajo' : 'Agotado' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- tarjetas mobile -->
      <div class="card-list">
        <div v-for="p in productos" :key="p.id_producto" class="prod-card" @click="open(p)">
          <div class="prod-card__top">
            <div class="prod-card__info">
              <div class="prod-card__name">{{ p.nombre }}</div>
              <div class="prod-card__cat">{{ p.tipo_control || '—' }}</div>
            </div>
            <span class="badge" :class="'badge--' + estadoStock(p)">
              {{ estadoStock(p) === 'ok' ? 'En stock' : estadoStock(p) === 'bajo' ? 'Bajo' : 'Agotado' }}
            </span>
          </div>
          <div class="prod-card__meta">
            <span :class="{ 'text-danger': p.stock === 0, 'text-warn': p.stock < p.stock_minimo && p.stock > 0 }">
              {{ p.stock }} uds
            </span>
            <span class="dot">·</span>
            <span class="td-muted">mín {{ p.stock_minimo }}</span>
            <span class="dot">·</span>
            <span class="td-muted">{{ fmtCOP(p.precio) }}</span>
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
            <div class="form-title">{{ mode === 'create' ? 'Nuevo producto' : 'Editar producto' }}</div>
            <div class="form">
              <div class="form-group">
                <label class="form-label">Nombre *</label>
                <input class="form-input" v-model="draft.nombre" placeholder="Nombre del producto" />
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">Precio *</label>
                  <input class="form-input" v-model="draft.precio" type="number" min="0" placeholder="0" />
                </div>
                <div class="form-group" v-if="mode === 'create'">
                  <label class="form-label">Stock inicial</label>
                  <input class="form-input" v-model="draft.stock" type="number" min="0" placeholder="0" />
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">Stock mínimo</label>
                  <input class="form-input" v-model="draft.stock_minimo" type="number" min="0" placeholder="5" />
                </div>
                <div class="form-group">
                  <label class="form-label">Tipo control</label>
                  <select class="form-select" v-model="draft.tipo_control">
                    <option value="manual">Manual</option>
                    <option value="unitario">Unitario</option>
                  </select>
                </div>
              </div>
              <div class="form-group">
                <label class="form-label">Estado</label>
                <select class="form-select" v-model="draft.estado">
                  <option value="activo">Activo</option>
                  <option value="inactivo">Inactivo</option>
                </select>
              </div>
            </div>
            <p v-if="formError" class="form-error">{{ formError }}</p>
          </template>

          <!-- VIEW MODE -->
          <template v-else>
            <div class="sheet__head">
              <div class="sheet__icon">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="M3 8l9 5 9-5M12 13v8"/></svg>
              </div>
              <div class="sheet__headinfo">
                <div class="sheet__name">{{ selected.nombre }}</div>
                <div class="sheet__sub">{{ selected.tipo_control || '—' }}</div>
              </div>
              <button class="sheet__close" @click="close">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
              </button>
            </div>

            <div class="fields">
              <div class="field-row">
                <span class="field-lbl">Stock actual</span>
                <span class="field-val" :class="{ 'text-danger': selected.stock === 0, 'text-warn': selected.stock < selected.stock_minimo && selected.stock > 0 }">
                  {{ selected.stock }} uds
                </span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Stock mínimo</span>
                <span class="field-val">{{ selected.stock_minimo }} uds</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Precio unitario</span>
                <span class="field-val">{{ fmtCOP(selected.precio) }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Estado</span>
                <span class="badge" :class="'badge--' + estadoStock(selected)">
                  {{ estadoStock(selected) === 'ok' ? 'En stock' : estadoStock(selected) === 'bajo' ? 'Stock bajo' : 'Agotado' }}
                </span>
              </div>
            </div>

            <div class="section-lbl">Ajuste de stock</div>
            <div class="ajuste">
              <button class="ajuste__btn" @click="ajuste--">−</button>
              <div class="ajuste__val">{{ ajuste >= 0 ? '+' : '' }}{{ ajuste }}</div>
              <button class="ajuste__btn" @click="ajuste++">+</button>
            </div>
            <p class="ajuste__note">Nuevo stock: <strong>{{ selected.stock + ajuste }}</strong> uds</p>
            <div class="form-group" style="margin-top:10px">
              <label class="form-label">PIN del empleado</label>
              <input class="form-input pin-input" v-model="pinAjuste" type="text" maxlength="4" placeholder="••••" inputmode="numeric" autocomplete="off" />
            </div>
            <p v-if="ajusteError" class="form-error">{{ ajusteError }}</p>
          </template>

        </div>

        <div class="sheet__footer">
          <template v-if="mode === 'view'">
            <button class="cta-btn" :disabled="ajuste === 0 || saving" @click="guardarAjuste">
              {{ saving ? 'Guardando…' : 'Guardar ajuste' }}
            </button>
            <button class="sec-btn" @click="openEdit">Editar producto</button>
            <button class="del-btn" @click="remove">Desactivar</button>
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
.inv {
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
.topbar__btn {
  display: inline-flex; align-items: center; gap: 7px; height: 38px; padding: 0 16px;
  border-radius: 11px; border: none; background: #B0455F; color: #FBF6F4;
  font-size: 13px; font-weight: 500; font-family: inherit; cursor: pointer; transition: filter .2s;
}
.topbar__btn:hover { filter: brightness(1.08); }

/* stats */
.stats { display: grid; grid-template-columns: repeat(3,1fr); gap: 10px; padding: 0 20px 16px; }
.stat-card {
  background: #fff; border-radius: 14px; border: 1px solid rgba(26,23,20,.08);
  padding: 14px 16px;
}
.stat-card--warn   { border-color: rgba(217,119,6,.18); background: #fffbf0; }
.stat-card--danger { border-color: rgba(220,38,38,.15); background: #fff5f5; }
.stat-card__val { font-family: Fraunces, Georgia, serif; font-size: 26px; font-weight: 600; color: #1A1714; }
.stat-card--warn   .stat-card__val { color: #b45309; }
.stat-card--danger .stat-card__val { color: #dc2626; }
.stat-card__lbl { font-size: 12px; color: #a59a8d; margin-top: 2px; }

/* toolbar */
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

/* lista */
.list-wrap { flex: 1; padding: 0 20px 28px; }
.empty { text-align: center; color: #a59a8d; font-size: 14px; padding: 40px 0; }
.table { display: none; }

.card-list { display: flex; flex-direction: column; gap: 10px; }
.prod-card {
  background: #fff; border-radius: 14px; border: 1px solid rgba(26,23,20,.08);
  padding: 14px 16px; cursor: pointer; transition: box-shadow .2s;
}
.prod-card:hover { box-shadow: 0 4px 16px rgba(20,12,4,.10); }
.prod-card__top { display: flex; align-items: flex-start; gap: 10px; }
.prod-card__info { flex: 1; min-width: 0; }
.prod-card__name { font-size: 14px; font-weight: 600; color: #1A1714; }
.prod-card__cat  { font-size: 12px; color: #8a7f72; margin-top: 2px; }
.prod-card__meta { display: flex; align-items: center; gap: 6px; margin-top: 8px; font-size: 12.5px; color: #1A1714; }
.dot { color: #c9bfb7; }
.td-muted { color: #8a7f72 !important; font-size: 13px; }
.td-name  { font-size: 13.5px; font-weight: 500; color: #1A1714; max-width: 280px; }
.tc { text-align: center; }
.td-danger, .text-danger { color: #dc2626 !important; font-weight: 700; }
.td-warn,   .text-warn   { color: #b45309 !important; font-weight: 700; }

.badge { display: inline-block; font-size: 10px; font-weight: 600; padding: 2px 9px; border-radius: 20px; white-space: nowrap; }
.badge--ok      { background: rgba(22,163,74,.12);  color: #15803d; }
.badge--bajo    { background: rgba(217,119,6,.14);  color: #b45309; }
.badge--agotado { background: rgba(220,38,38,.12);  color: #dc2626; }

/* scrim */
.scrim { position: fixed; inset: 0; z-index: 30; background: rgba(26,23,20,.28); }

/* sheet */
.sheet {
  position: fixed; left: 0; right: 0; bottom: 0; z-index: 40;
  background: #FBF6F4; border-radius: 24px 24px 0 0; max-height: 90vh;
  display: flex; flex-direction: column; padding-bottom: 64px;
}
.sheet__handle { width: 40px; height: 4px; border-radius: 4px; background: rgba(26,23,20,.15); margin: 12px auto 0; flex: none; }
.sheet__scroll { flex: 1; overflow-y: auto; padding: 16px 22px 8px; scrollbar-width: none; }
.sheet__scroll::-webkit-scrollbar { display: none; }

.sheet__head { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 16px; }
.sheet__icon {
  flex: none; width: 44px; height: 44px; border-radius: 13px;
  background: rgba(176,69,95,.08); display: flex; align-items: center; justify-content: center;
}
.sheet__headinfo { flex: 1; min-width: 0; }
.sheet__name { font-family: Fraunces, Georgia, serif; font-size: 17px; font-weight: 500; color: #1A1714; line-height: 1.3; }
.sheet__sub  { font-size: 12px; color: #8a7f72; margin-top: 3px; }
.sheet__close {
  flex: none; width: 32px; height: 32px; border-radius: 9px;
  border: 1px solid rgba(26,23,20,.1); background: #fff; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
}

.fields { display: flex; flex-direction: column; margin-bottom: 20px; }
.field-row { display: flex; justify-content: space-between; align-items: center; padding: 9px 0; border-bottom: 1px solid rgba(26,23,20,.06); }
.field-row:last-child { border-bottom: none; }
.field-lbl { font-size: 12px; color: #a59a8d; }
.field-val  { font-size: 13.5px; font-weight: 500; color: #1A1714; }

.section-lbl { font-size: 11px; font-weight: 600; letter-spacing: .05em; text-transform: uppercase; color: #a59a8d; margin-bottom: 14px; }

.ajuste { display: flex; align-items: center; gap: 18px; justify-content: center; margin-bottom: 10px; }
.ajuste__btn {
  width: 44px; height: 44px; border-radius: 50%; border: 1.5px solid rgba(26,23,20,.14);
  background: #fff; font-size: 20px; color: #1A1714; cursor: pointer; display: flex; align-items: center; justify-content: center;
  transition: background .15s;
}
.ajuste__btn:hover { background: rgba(26,23,20,.06); }
.ajuste__val { font-family: Fraunces, Georgia, serif; font-size: 28px; font-weight: 600; color: #B0455F; min-width: 56px; text-align: center; }
.ajuste__note { text-align: center; font-size: 13px; color: #8a7f72; margin: 0 0 4px; }

.sheet__footer { flex: none; padding: 14px 22px 20px; border-top: 1px solid rgba(26,23,20,.07); display: flex; flex-direction: column; gap: 10px; }
.cta-btn {
  display: flex; align-items: center; justify-content: center; width: 100%; height: 48px;
  border-radius: 13px; border: none; background: #B0455F; color: #FBF6F4;
  font-family: Fraunces, Georgia, serif; font-size: 15px; font-weight: 500; cursor: pointer; transition: filter .2s;
}
.cta-btn:disabled { background: #d0bfc1; cursor: not-allowed; }
.cta-btn:not(:disabled):hover { filter: brightness(1.07); }
.sec-btn {
  display: flex; align-items: center; justify-content: center; width: 100%; height: 44px;
  border-radius: 13px; border: 1.5px solid rgba(26,23,20,.14); background: transparent;
  color: #1A1714; font-size: 13.5px; font-weight: 500; font-family: inherit; cursor: pointer; transition: background .15s;
}
.sec-btn:hover { background: rgba(26,23,20,.04); }

/* form */
.form-title { font-family: Fraunces, Georgia, serif; font-size: 19px; font-weight: 500; color: #1A1714; margin: 18px 0 16px; }
.form { display: flex; flex-direction: column; gap: 14px; margin-bottom: 8px; }
.form-row  { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 600; color: #a59a8d; text-transform: uppercase; letter-spacing: .04em; }
.form-input, .form-select {
  height: 44px; padding: 0 12px; border-radius: 11px;
  border: 1.5px solid rgba(26,23,20,.14); background: #fff;
  font-size: 14px; font-family: inherit; color: #1A1714; transition: border-color .2s;
}
.form-input:focus, .form-select:focus { outline: none; border-color: #B0455F; }
.form-input::placeholder { color: #c0b4aa; }
.pin-input { -webkit-text-security: disc; letter-spacing: 4px; }
.form-error { font-size: 12px; color: #B0455F; margin: 4px 0 0; }
.del-btn {
  display: flex; align-items: center; justify-content: center;
  width: 100%; height: 40px; border-radius: 11px; margin-top: 8px;
  border: 1.5px solid rgba(176,69,95,.3); background: transparent;
  color: #B0455F; font-family: inherit; font-size: 13px; font-weight: 500; cursor: pointer;
}
.del-btn:hover { background: rgba(176,69,95,.06); }

.scrim-enter-active, .scrim-leave-active { transition: opacity .28s ease; }
.scrim-enter-from, .scrim-leave-to { opacity: 0; }
.sheet-enter-active, .sheet-leave-active { transition: transform .36s cubic-bezier(.4,0,.2,1); }
.sheet-enter-from, .sheet-leave-to { transform: translateY(100%); }

/* ===== DESKTOP ===== */
@media (min-width: 1024px) {
  .topbar   { padding: 24px 28px 18px; }
  .topbar__title { font-size: 26px; }
  .stats    { padding: 0 28px 18px; grid-template-columns: repeat(3,160px); }
  .toolbar  { padding: 0 28px 14px; flex-direction: row; align-items: center; gap: 14px; }
  .search   { max-width: 340px; }
  .list-wrap { padding: 0 28px 32px; }
  .card-list { display: none; }

  .table {
    display: table; width: 100%; border-collapse: separate; border-spacing: 0;
    background: #fff; border-radius: 16px; border: 1px solid rgba(26,23,20,.08); overflow: hidden;
  }
  .table thead th {
    text-align: left; padding: 12px 16px;
    font-size: 11px; font-weight: 600; letter-spacing: .04em; text-transform: uppercase;
    color: #a59a8d; background: #FBF6F4; border-bottom: 1px solid rgba(26,23,20,.07);
  }
  .table thead th.tc { text-align: center; }
  .table__row { cursor: pointer; transition: background .15s; }
  .table__row:hover td { background: #fdf7f5; }
  .table__row td { padding: 12px 16px; border-bottom: 1px solid rgba(26,23,20,.06); vertical-align: middle; }
  .table__row:last-child td { border-bottom: none; }

  .sheet {
    left: auto; right: 0; top: 0; bottom: 0; width: 400px; max-height: none;
    border-radius: 0; border-left: 1px solid rgba(26,23,20,.08);
    box-shadow: -12px 0 34px rgba(20,12,4,.10); padding-bottom: 0;
  }
  .sheet__handle { display: none; }
  .sheet-enter-from, .sheet-leave-to { transform: translateX(100%); }
}
</style>
