<script setup>
import { computed, onMounted, ref } from 'vue'
import { getClientes, createCliente, updateCliente, deleteCliente } from '@/api/admin'

const loading     = ref(true)
const allClientes = ref([])
const q           = ref('')
const selected    = ref(null)
const mode        = ref('view') // 'view' | 'create' | 'edit'
const draft       = ref({})
const saving      = ref(false)
const formError   = ref('')

onMounted(async () => {
  try { allClientes.value = await getClientes() }
  finally { loading.value = false }
})

const initials = (c) => ((c.nombre?.[0] || '') + (c.apellido?.[0] || '')).toUpperCase() || '?'

const clientes = computed(() => {
  const s = q.value.trim().toLowerCase()
  if (!s) return allClientes.value
  return allClientes.value.filter(c =>
    `${c.nombre} ${c.apellido}`.toLowerCase().includes(s) ||
    (c.telefono || '').includes(s) ||
    (c.direccion || '').toLowerCase().includes(s)
  )
})

const sheetOpen = computed(() => selected.value !== null || mode.value === 'create')

function openCliente(c) { selected.value = c; mode.value = 'view'; formError.value = '' }
function openCreate() {
  selected.value = null
  draft.value = { nombre: '', apellido: '', documento: '', telefono: '', direccion: '', estado: 'activo' }
  mode.value = 'create'; formError.value = ''
}
function openEdit() { draft.value = { ...selected.value }; mode.value = 'edit'; formError.value = '' }
function cancelForm() { mode.value === 'edit' ? (mode.value = 'view') : closeSheet() }
function closeSheet() { selected.value = null; mode.value = 'view'; formError.value = '' }

async function save() {
  formError.value = ''
  if (!draft.value.nombre?.trim() || !draft.value.apellido?.trim() || !draft.value.documento?.trim()) {
    formError.value = 'Nombre, apellido y documento son requeridos'; return
  }
  saving.value = true
  try {
    if (mode.value === 'create') {
      const c = await createCliente(draft.value)
      allClientes.value.unshift(c); closeSheet()
    } else {
      const c = await updateCliente(selected.value.id_cliente, draft.value)
      const idx = allClientes.value.findIndex(x => x.id_cliente === c.id_cliente)
      if (idx !== -1) allClientes.value[idx] = c
      selected.value = c; mode.value = 'view'
    }
  } catch (e) { formError.value = e.response?.data?.message || 'Error al guardar' }
  finally { saving.value = false }
}

async function remove() {
  if (!confirm(`¿Eliminar a ${selected.value.nombre} ${selected.value.apellido}?`)) return
  try {
    await deleteCliente(selected.value.id_cliente)
    allClientes.value = allClientes.value.filter(c => c.id_cliente !== selected.value.id_cliente)
    closeSheet()
  } catch (e) { alert(e.response?.data?.message || 'Error al eliminar') }
}
</script>

<template>
  <div class="clientes">

    <!-- TOPBAR -->
    <div class="topbar">
      <h1 class="topbar__title">Clientes</h1>
      <button class="topbar__btn" @click="openCreate">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
        Nuevo
      </button>
    </div>

    <!-- BUSCADOR -->
    <div class="search-wrap">
      <div class="search">
        <svg class="search__ico" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.35-4.35"/></svg>
        <input v-model="q" class="search__input" type="search" placeholder="Buscar por nombre, correo o teléfono…" />
        <button v-if="q" class="search__clear" @click="q = ''">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
        </button>
      </div>
    </div>

    <!-- LISTA -->
    <div class="list-wrap">
      <div v-if="!loading && clientes.length === 0" class="empty">No se encontraron clientes.</div>

      <!-- tabla desktop -->
      <table class="table">
        <thead>
          <tr>
            <th>Cliente</th>
            <th>Teléfono</th>
            <th>Dirección</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading"><td colspan="4" style="padding:32px;text-align:center;color:#a59a8d">Cargando…</td></tr>
          <tr
            v-for="c in clientes"
            :key="c.id_cliente"
            class="table__row"
            @click="openCliente(c)"
          >
            <td>
              <div class="cli-cell">
                <div class="cli-avatar">{{ initials(c) }}</div>
                <span class="cli-name">{{ c.nombre }} {{ c.apellido }}</span>
              </div>
            </td>
            <td class="td-muted">{{ c.telefono || '—' }}</td>
            <td class="td-muted">{{ c.direccion || '—' }}</td>
            <td>
              <span class="estado-badge" :class="'estado-badge--' + c.estado">
                {{ c.estado === 'activo' ? 'Activo' : 'Inactivo' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- tarjetas mobile -->
      <div v-if="loading" class="card-list">
        <div v-for="k in 5" :key="k" class="cli-card">
          <div class="cli-card__top">
            <div class="shimmer cli-avatar"></div>
            <div class="cli-card__info">
              <div class="shimmer sk-line" style="width:60%;height:13px"></div>
              <div class="shimmer sk-line" style="width:40%;height:11px;margin-top:5px"></div>
            </div>
          </div>
        </div>
      </div>
      <div v-else class="card-list">
        <div
          v-for="c in clientes"
          :key="c.id_cliente"
          class="cli-card"
          @click="openCliente(c)"
        >
          <div class="cli-card__top">
            <div class="cli-avatar">{{ initials(c) }}</div>
            <div class="cli-card__info">
              <div class="cli-card__name">{{ c.nombre }} {{ c.apellido }}</div>
              <div class="cli-card__email">{{ c.telefono || c.direccion || '—' }}</div>
            </div>
            <span class="estado-badge" :class="'estado-badge--' + c.estado">{{ c.estado }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- SCRIM -->
    <Transition name="scrim">
      <div v-if="sheetOpen" class="scrim" @click="closeSheet"></div>
    </Transition>

    <!-- BOTTOM SHEET / DRAWER -->
    <Transition name="sheet">
      <div v-if="sheetOpen" class="sheet">
        <div class="sheet__handle"></div>
        <div class="sheet__scroll scrl">

          <!-- FORM MODE -->
          <template v-if="mode !== 'view'">
            <div class="form-title">{{ mode === 'create' ? 'Nuevo cliente' : 'Editar cliente' }}</div>
            <div class="form">
              <div class="form-group">
                <label class="form-label">Nombre *</label>
                <input class="form-input" v-model="draft.nombre" placeholder="Nombre" />
              </div>
              <div class="form-group">
                <label class="form-label">Apellido *</label>
                <input class="form-input" v-model="draft.apellido" placeholder="Apellido" />
              </div>
              <div class="form-group">
                <label class="form-label">Documento *</label>
                <input class="form-input" v-model="draft.documento" placeholder="CC / Pasaporte" />
              </div>
              <div class="form-group">
                <label class="form-label">Teléfono</label>
                <input class="form-input" v-model="draft.telefono" placeholder="+57 300 000 0000" />
              </div>
              <div class="form-group">
                <label class="form-label">Dirección</label>
                <input class="form-input" v-model="draft.direccion" placeholder="Dirección" />
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
            <div class="sheet__header">
              <div class="cli-avatar cli-avatar--lg">{{ initials(selected) }}</div>
              <div>
                <div class="sheet__name">{{ selected.nombre }} {{ selected.apellido }}</div>
                <span class="estado-badge" :class="'estado-badge--' + selected.estado">{{ selected.estado }}</span>
              </div>
              <button class="sheet__close" @click="closeSheet">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
              </button>
            </div>
            <div class="sheet__fields">
              <div class="field-row">
                <span class="field-lbl">Documento</span>
                <span class="field-val">{{ selected.documento || '—' }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Teléfono</span>
                <span class="field-val">{{ selected.telefono || '—' }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Dirección</span>
                <span class="field-val">{{ selected.direccion || '—' }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Estado</span>
                <span class="field-val">{{ selected.estado }}</span>
              </div>
            </div>
          </template>

        </div>

        <div class="sheet__footer">
          <template v-if="mode === 'view'">
            <button class="cta-btn" @click="openEdit">Editar cliente</button>
            <button class="del-btn" @click="remove">Eliminar cliente</button>
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
.clientes {
  flex: 1;
  display: flex;
  flex-direction: column;
  font-family: Inter, system-ui, sans-serif;
  background: #FBF6F4;
  min-height: 100vh;
  position: relative;
}

.sk-line { border-radius:5px; }

/* topbar */
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

/* search */
.search-wrap { padding: 0 20px 14px; }
.search {
  display: flex;
  align-items: center;
  gap: 10px;
  height: 46px;
  padding: 0 14px;
  border-radius: 13px;
  background: #fff;
  border: 1.5px solid rgba(26,23,20,.12);
  transition: border-color .2s;
}
.search:focus-within { border-color: #B0455F; }
.search__ico { flex: none; }
.search__input {
  flex: 1;
  border: none;
  background: transparent;
  font-size: 14px;
  font-family: inherit;
  color: #1A1714;
}
.search__input::placeholder { color: #b7ab9d; }
.search__input:focus { outline: none; }
.search__clear {
  flex: none;
  display: flex;
  align-items: center;
  border: none;
  background: none;
  cursor: pointer;
  padding: 2px;
}

.list-wrap { flex: 1; padding: 0 20px 28px; }
.empty { text-align: center; color: #a59a8d; font-size: 14px; padding: 40px 0; }

/* tabla: oculta mobile */
.table { display: none; }

/* tarjetas mobile */
.card-list { display: flex; flex-direction: column; gap: 10px; }
.cli-card {
  background: #fff;
  border-radius: 14px;
  border: 1px solid rgba(26,23,20,.08);
  padding: 14px 16px;
  cursor: pointer;
  transition: box-shadow .2s;
}
.cli-card:hover { box-shadow: 0 4px 16px rgba(20,12,4,.10); }
.cli-card__top {
  display: flex;
  align-items: center;
  gap: 11px;
}
.cli-card__info { flex: 1; min-width: 0; }
.cli-card__name { font-size: 14px; font-weight: 600; color: #1A1714; }
.cli-card__email { font-size: 12px; color: #8a7f72; margin-top: 1px; }
.cli-card__meta {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 10px;
  font-size: 12px;
  color: #a59a8d;
}
.cli-card__gasto { font-weight: 600; color: #B0455F; }

/* avatar */
.cli-avatar {
  flex: none;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #F1E5E3;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  color: #7a3a4f;
}
.cli-avatar--lg { width: 48px; height: 48px; font-size: 16px; }
.cli-cell { display: flex; align-items: center; gap: 10px; }
.cli-name { font-size: 13.5px; font-weight: 500; color: #1A1714; }

/* badges */
.estado-badge {
  display: inline-block;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 9px;
  border-radius: 20px;
  text-transform: capitalize;
}
.estado-badge--activo   { background: rgba(22,163,74,.12);  color: #15803d; }
.estado-badge--inactivo { background: rgba(26,23,20,.08);   color: #8a7f72; }

/* scrim */
.scrim {
  position: fixed;
  inset: 0;
  z-index: 30;
  background: rgba(26,23,20,.28);
}

/* bottom sheet */
.sheet {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 40;
  background: #FBF6F4;
  border-radius: 24px 24px 0 0;
  max-height: 88vh;
  display: flex;
  flex-direction: column;
  padding-bottom: 64px;
}
.sheet__handle {
  width: 40px;
  height: 4px;
  border-radius: 4px;
  background: rgba(26,23,20,.15);
  margin: 12px auto 0;
  flex: none;
}
.sheet__scroll {
  flex: 1;
  overflow-y: auto;
  padding: 16px 22px 8px;
}
.sheet__scroll::-webkit-scrollbar { display: none; }
.sheet__scroll { -ms-overflow-style: none; scrollbar-width: none; }

.sheet__header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
}
.sheet__name {
  font-family: Fraunces, Georgia, serif;
  font-size: 19px;
  font-weight: 500;
  color: #1A1714;
}
.sheet__close {
  margin-left: auto;
  width: 32px;
  height: 32px;
  border-radius: 9px;
  border: 1px solid rgba(26,23,20,.1);
  background: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.sheet__fields { display: flex; flex-direction: column; gap: 0; margin-bottom: 20px; }
.field-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  padding: 10px 0;
  border-bottom: 1px solid rgba(26,23,20,.06);
}
.field-row:last-child { border-bottom: none; }
.field-lbl { font-size: 12px; color: #a59a8d; }
.field-val { font-size: 13.5px; font-weight: 500; color: #1A1714; }

.section-lbl {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: .05em;
  text-transform: uppercase;
  color: #a59a8d;
  margin-bottom: 12px;
}
.hist-list { display: flex; flex-direction: column; gap: 0; }
.hist-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 0;
  border-bottom: 1px solid rgba(26,23,20,.06);
}
.hist-row:last-child { border-bottom: none; }
.hist-row__svc { font-size: 13.5px; font-weight: 500; color: #1A1714; }
.hist-row__fecha { font-size: 12px; color: #a59a8d; margin-top: 1px; }
.hist-row__right { text-align: right; }
.hist-row__monto { font-size: 13px; font-weight: 600; color: #1A1714; }
.hist-badge {
  display: inline-block;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 20px;
  margin-top: 3px;
}
.hist-badge--confirmada { background: rgba(176,69,95,.10); color: #B0455F; }
.hist-badge--completada { background: rgba(22,163,74,.12); color: #15803d; }

.sheet__footer {
  flex: none;
  padding: 14px 22px 20px;
  border-top: 1px solid rgba(26,23,20,.07);
}
.cta-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 50px;
  border-radius: 13px;
  border: none;
  background: #B0455F;
  color: #FBF6F4;
  font-family: Fraunces, Georgia, serif;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: filter .2s;
}
.cta-btn:hover { filter: brightness(1.07); }

/* form */
.form-title { font-family: Fraunces, Georgia, serif; font-size: 19px; font-weight: 500; color: #1A1714; margin-bottom: 18px; }
.form { display: flex; flex-direction: column; gap: 14px; margin-bottom: 8px; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 600; color: #a59a8d; text-transform: uppercase; letter-spacing: .04em; }
.form-input, .form-select {
  height: 44px; padding: 0 12px; border-radius: 11px;
  border: 1.5px solid rgba(26,23,20,.14); background: #fff;
  font-size: 14px; font-family: inherit; color: #1A1714; transition: border-color .2s;
}
.form-input:focus, .form-select:focus { outline: none; border-color: #B0455F; }
.form-input::placeholder { color: #c0b4aa; }
.form-error { font-size: 12px; color: #B0455F; margin: 0 0 8px; }
.sec-btn {
  display: flex; align-items: center; justify-content: center;
  width: 100%; height: 44px; border-radius: 11px; margin-top: 10px;
  border: 1.5px solid rgba(26,23,20,.12); background: transparent;
  color: #6b6258; font-family: inherit; font-size: 14px; font-weight: 500; cursor: pointer;
}
.sec-btn:hover { background: rgba(26,23,20,.04); }
.del-btn {
  display: flex; align-items: center; justify-content: center;
  width: 100%; height: 44px; border-radius: 11px; margin-top: 10px;
  border: 1.5px solid rgba(176,69,95,.3); background: transparent;
  color: #B0455F; font-family: inherit; font-size: 14px; font-weight: 500; cursor: pointer;
}
.del-btn:hover { background: rgba(176,69,95,.06); }

/* transitions */
.scrim-enter-active, .scrim-leave-active { transition: opacity .28s ease; }
.scrim-enter-from, .scrim-leave-to { opacity: 0; }
.sheet-enter-active, .sheet-leave-active { transition: transform .36s cubic-bezier(.4,0,.2,1); }
.sheet-enter-from, .sheet-leave-to { transform: translateY(100%); }

/* ===== DESKTOP ===== */
@media (min-width: 1024px) {
  .topbar { padding: 24px 28px 18px; }
  .search-wrap { padding: 0 28px 16px; }
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
  .table__row {
    cursor: pointer;
    transition: background .15s;
  }
  .table__row:hover td { background: #fdf7f5; }
  .table__row td {
    padding: 14px 16px;
    border-bottom: 1px solid rgba(26,23,20,.06);
    vertical-align: middle;
    font-size: 13.5px;
    color: #1A1714;
  }
  .table__row:last-child td { border-bottom: none; }
  .td-muted { color: #8a7f72 !important; }
  .td-center { text-align: center; }
  .td-val { font-weight: 600; color: #1A1714 !important; }

  /* drawer desktop */
  .sheet {
    left: auto;
    right: 0;
    top: 0;
    bottom: 0;
    width: 380px;
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
