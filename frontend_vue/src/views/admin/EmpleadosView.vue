<script setup>
import { computed, onMounted, ref } from 'vue'
import { getEmpleados, createEmpleado, updateEmpleado, deleteEmpleado } from '@/api/admin'

const loading      = ref(true)
const allEmpleados = ref([])
const q            = ref('')
const selected     = ref(null)
const mode         = ref('view') // 'view' | 'create' | 'edit'
const draft        = ref({})
const saving       = ref(false)
const formError    = ref('')

onMounted(async () => {
  try { allEmpleados.value = await getEmpleados() }
  finally { loading.value = false }
})

const initials = (e) => ((e.nombre?.[0] || '') + (e.apellido?.[0] || '')).toUpperCase() || '?'
const rolLabel = { admin: 'Administrador', empleado: 'Estilista' }

const empleados = computed(() => {
  const s = q.value.trim().toLowerCase()
  if (!s) return allEmpleados.value
  return allEmpleados.value.filter(e =>
    `${e.nombre} ${e.apellido}`.toLowerCase().includes(s) ||
    (e.cargo || '').toLowerCase().includes(s)
  )
})

const sheetOpen = computed(() => selected.value !== null || mode.value === 'create')

function open(e) { selected.value = e; mode.value = 'view'; formError.value = '' }
function openCreate() {
  selected.value = null
  draft.value = { nombre: '', apellido: '', documento: '', pin: '', telefono: '', cargo: '', rol: 'empleado', estado: 'activo', username: '', email: '' }
  mode.value = 'create'; formError.value = ''
}
function openEdit() { draft.value = { ...selected.value, pin: '' }; mode.value = 'edit'; formError.value = '' }
function cancelForm() { mode.value === 'edit' ? (mode.value = 'view') : close() }
function close() { selected.value = null; mode.value = 'view'; formError.value = '' }

async function save() {
  formError.value = ''
  if (!draft.value.nombre?.trim() || !draft.value.apellido?.trim() || !draft.value.documento?.trim()) {
    formError.value = 'Nombre, apellido y documento son requeridos'; return
  }
  if (mode.value === 'create' && !draft.value.pin?.match(/^\d{4}$/)) {
    formError.value = 'PIN debe ser exactamente 4 dígitos'; return
  }
  if (draft.value.pin && !draft.value.pin.match(/^\d{4}$/)) {
    formError.value = 'PIN debe ser exactamente 4 dígitos'; return
  }
  const payload = { ...draft.value }
  if (!payload.pin) delete payload.pin
  if (!payload.username) delete payload.username
  if (!payload.email) delete payload.email
  saving.value = true
  try {
    if (mode.value === 'create') {
      const e = await createEmpleado(payload)
      allEmpleados.value.unshift(e); close()
    } else {
      const e = await updateEmpleado(selected.value.id_empleado, payload)
      const idx = allEmpleados.value.findIndex(x => x.id_empleado === e.id_empleado)
      if (idx !== -1) allEmpleados.value[idx] = e
      selected.value = e; mode.value = 'view'
    }
  } catch (e) { formError.value = e.response?.data?.message || 'Error al guardar' }
  finally { saving.value = false }
}

async function remove() {
  if (!confirm(`¿Desactivar a ${selected.value.nombre} ${selected.value.apellido}?`)) return
  try {
    await deleteEmpleado(selected.value.id_empleado)
    allEmpleados.value = allEmpleados.value.filter(e => e.id_empleado !== selected.value.id_empleado)
    close()
  } catch (e) { alert(e.response?.data?.message || 'Error al eliminar') }
}
</script>

<template>
  <div class="emp">

    <!-- TOPBAR -->
    <div class="topbar">
      <h1 class="topbar__title">Empleadas</h1>
      <button class="topbar__btn" @click="openCreate">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
        Nueva
      </button>
    </div>

    <!-- SEARCH -->
    <div class="search-wrap">
      <div class="search">
        <svg class="search__ico" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.35-4.35"/></svg>
        <input v-model="q" class="search__input" type="search" placeholder="Buscar por nombre, especialidad…" />
        <button v-if="q" class="search__clear" @click="q = ''">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
        </button>
      </div>
    </div>

    <!-- LISTA -->
    <div class="list-wrap">
      <p v-if="!loading && !empleados.length" class="empty">No se encontraron empleadas.</p>

      <!-- tabla desktop -->
      <table class="table">
        <thead>
          <tr>
            <th>Empleada</th>
            <th>Cargo</th>
            <th>Teléfono</th>
            <th>Documento</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading"><td colspan="5" style="padding:32px;text-align:center;color:#a59a8d">Cargando…</td></tr>
          <tr v-for="e in empleados" :key="e.id_empleado" class="table__row" @click="open(e)">
            <td>
              <div class="emp-cell">
                <div class="avatar">{{ initials(e) }}</div>
                <div>
                  <div class="emp-name">{{ e.nombre }} {{ e.apellido }}</div>
                  <div class="emp-rol">{{ e.cargo || '—' }}</div>
                </div>
              </div>
            </td>
            <td class="td-muted">{{ e.cargo || '—' }}</td>
            <td class="td-muted">{{ e.telefono || '—' }}</td>
            <td class="td-muted">{{ e.documento || '—' }}</td>
            <td>
              <span class="estado" :class="'estado--' + e.estado">
                {{ e.estado === 'activo' ? 'Activa' : 'Inactiva' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- tarjetas mobile -->
      <div class="card-list">
        <div v-for="e in empleados" :key="e.id_empleado" class="emp-card" @click="open(e)">
          <div class="emp-card__top">
            <div class="avatar avatar--lg">{{ initials(e) }}</div>
            <div class="emp-card__info">
              <div class="emp-card__name">{{ e.nombre }} {{ e.apellido }}</div>
              <div class="emp-card__esp">{{ e.cargo || '—' }}</div>
            </div>
            <span class="estado" :class="'estado--' + e.estado">{{ e.estado === 'activo' ? 'Activa' : 'Inactiva' }}</span>
          </div>
          <div class="emp-card__meta">
            <span>{{ e.telefono || '—' }}</span>
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
            <div class="form-title">{{ mode === 'create' ? 'Nueva empleada' : 'Editar empleada' }}</div>
            <div class="form">
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">Nombre *</label>
                  <input class="form-input" v-model="draft.nombre" placeholder="Nombre" />
                </div>
                <div class="form-group">
                  <label class="form-label">Apellido *</label>
                  <input class="form-input" v-model="draft.apellido" placeholder="Apellido" />
                </div>
              </div>
              <div class="form-group">
                <label class="form-label">Documento *</label>
                <input class="form-input" v-model="draft.documento" placeholder="CC / Pasaporte" />
              </div>
              <div class="form-group">
                <label class="form-label">PIN (4 dígitos){{ mode === 'edit' ? ' — dejar vacío para no cambiar' : ' *' }}</label>
                <input class="form-input pin-input" v-model="draft.pin" type="text" maxlength="4" placeholder="••••" inputmode="numeric" autocomplete="off" />
              </div>
              <div class="form-group">
                <label class="form-label">Teléfono</label>
                <input class="form-input" v-model="draft.telefono" placeholder="+57 300 000 0000" />
              </div>
              <div class="form-group">
                <label class="form-label">Cargo / Especialidad</label>
                <input class="form-input" v-model="draft.cargo" placeholder="Ej: Colorista, Manicurista…" />
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">Rol</label>
                  <select class="form-select" v-model="draft.rol">
                    <option value="empleado">Estilista</option>
                    <option value="admin">Admin</option>
                  </select>
                </div>
                <div class="form-group">
                  <label class="form-label">Estado</label>
                  <select class="form-select" v-model="draft.estado">
                    <option value="activo">Activo</option>
                    <option value="inactivo">Inactivo</option>
                  </select>
                </div>
              </div>
              <div class="form-group">
                <label class="form-label">Username</label>
                <input class="form-input" v-model="draft.username" placeholder="Dejar vacío para usar documento" />
              </div>
              <div class="form-group">
                <label class="form-label">Email</label>
                <input class="form-input" v-model="draft.email" placeholder="correo@ejemplo.com" />
              </div>
            </div>
            <p v-if="formError" class="form-error">{{ formError }}</p>
          </template>

          <!-- VIEW MODE -->
          <template v-else>
            <div class="sheet__head">
              <div class="avatar avatar--xl">{{ initials(selected) }}</div>
              <div class="sheet__headinfo">
                <div class="sheet__name">{{ selected.nombre }} {{ selected.apellido }}</div>
                <div class="sheet__esp">{{ selected.cargo || '—' }}</div>
              </div>
              <button class="sheet__close" @click="close">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
              </button>
            </div>
            <div class="fields">
              <div class="field-row">
                <span class="field-lbl">Cargo</span>
                <span class="field-val">{{ selected.cargo || '—' }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Documento</span>
                <span class="field-val">{{ selected.documento || '—' }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Teléfono</span>
                <span class="field-val">{{ selected.telefono || '—' }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Username</span>
                <span class="field-val">{{ selected.username || '—' }}</span>
              </div>
              <div class="field-row">
                <span class="field-lbl">Estado</span>
                <span class="estado" :class="'estado--' + selected.estado">{{ selected.estado === 'activo' ? 'Activa' : 'Inactiva' }}</span>
              </div>
            </div>
          </template>

        </div>

        <div class="sheet__footer">
          <template v-if="mode === 'view'">
            <button class="cta-btn" @click="openEdit">Editar empleada</button>
            <button class="del-btn" @click="remove">Desactivar empleada</button>
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
.emp {
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
.table { display: none; }

/* tarjetas mobile */
.card-list { display: flex; flex-direction: column; gap: 10px; }
.emp-card {
  background: #fff;
  border-radius: 14px;
  border: 1px solid rgba(26,23,20,.08);
  padding: 14px 16px;
  cursor: pointer;
  transition: box-shadow .2s;
}
.emp-card:hover { box-shadow: 0 4px 16px rgba(20,12,4,.10); }
.emp-card__top { display: flex; align-items: center; gap: 11px; }
.emp-card__info { flex: 1; min-width: 0; }
.emp-card__name { font-size: 14px; font-weight: 600; color: #1A1714; }
.emp-card__esp { font-size: 12px; color: #8a7f72; margin-top: 1px; }
.emp-card__meta {
  display: flex;
  align-items: center;
  gap: 5px;
  margin-top: 9px;
  font-size: 12px;
  color: #a59a8d;
}

/* avatar */
.avatar {
  flex: none;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #F1E5E3;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 700;
  color: #7a3a4f;
}
.avatar--admin { background: rgba(176,69,95,.15); color: #B0455F; }
.avatar--lg  { width: 44px; height: 44px; font-size: 14px; }
.avatar--xl  { width: 56px; height: 56px; font-size: 18px; flex: none; }

/* tabla desktop */
.emp-cell { display: flex; align-items: center; gap: 10px; }
.emp-name { font-size: 13.5px; font-weight: 600; color: #1A1714; }
.emp-rol  { font-size: 11px; color: #a59a8d; margin-top: 1px; }
.td-muted { color: #8a7f72 !important; font-size: 13px; }
.td-center { text-align: center; }

.num-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 22px;
  height: 22px;
  border-radius: 20px;
  background: rgba(176,69,95,.10);
  color: #B0455F;
  font-size: 12px;
  font-weight: 700;
  padding: 0 6px;
}

/* estado */
.estado {
  display: inline-block;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 9px;
  border-radius: 20px;
}
.estado--activo   { background: rgba(22,163,74,.12);  color: #15803d; }
.estado--inactivo { background: rgba(26,23,20,.08);   color: #8a7f72; }

.star { color: #ffcb4d; font-weight: 600; }

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

.sheet__head {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 14px;
}
.sheet__headinfo { flex: 1; min-width: 0; }
.sheet__name {
  font-family: Fraunces, Georgia, serif;
  font-size: 19px;
  font-weight: 500;
  color: #1A1714;
}
.sheet__esp { font-size: 13px; color: #8a7f72; margin-top: 2px; }
.sheet__rate { display: flex; align-items: center; gap: 6px; margin-top: 5px; font-size: 13px; }
.sheet__citas-mes { color: #a59a8d; }
.sheet__close {
  flex: none;
  width: 32px; height: 32px;
  border-radius: 9px;
  border: 1px solid rgba(26,23,20,.1);
  background: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.sheet__bio {
  margin: 0 0 18px;
  font-size: 13.5px;
  color: #6b6258;
  line-height: 1.55;
}

.fields { display: flex; flex-direction: column; margin-bottom: 18px; }
.field-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 9px 0;
  border-bottom: 1px solid rgba(26,23,20,.06);
}
.field-row:last-child { border-bottom: none; }
.field-lbl { font-size: 12px; color: #a59a8d; }
.field-val { font-size: 13.5px; font-weight: 500; color: #1A1714; }

.mini-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
  margin-bottom: 20px;
}
.mini-stat {
  background: #fff;
  border-radius: 12px;
  border: 1px solid rgba(26,23,20,.08);
  padding: 12px;
  text-align: center;
}
.mini-stat__val {
  font-family: Fraunces, Georgia, serif;
  font-size: 20px;
  font-weight: 600;
  color: #1A1714;
}
.mini-stat__lbl { font-size: 11px; color: #a59a8d; margin-top: 3px; }

.section-lbl {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: .05em;
  text-transform: uppercase;
  color: #a59a8d;
  margin-bottom: 12px;
}
.hist-list { display: flex; flex-direction: column; }
.hist-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 0;
  border-bottom: 1px solid rgba(26,23,20,.06);
}
.hist-row:last-child { border-bottom: none; }
.hist-row__name { font-size: 13.5px; font-weight: 500; color: #1A1714; }
.hist-row__svc  { font-size: 12px; color: #a59a8d; margin-top: 1px; }
.hist-badge {
  flex: none;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 9px;
  border-radius: 20px;
}
.hist-badge--confirmada { background: rgba(176,69,95,.10); color: #B0455F; }
.hist-badge--completada { background: rgba(22,163,74,.12);  color: #15803d; }

.sheet__footer {
  flex: none;
  padding: 14px 22px 20px;
  border-top: 1px solid rgba(26,23,20,.07);
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.cta-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 48px;
  border-radius: 13px;
  border: none;
  background: #B0455F;
  color: #FBF6F4;
  font-family: Fraunces, Georgia, serif;
  font-size: 15px;
  font-weight: 500;
  cursor: pointer;
  transition: filter .2s;
}
.cta-btn:hover { filter: brightness(1.07); }
.sec-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 44px;
  border-radius: 13px;
  border: 1.5px solid rgba(26,23,20,.14);
  background: transparent;
  color: #1A1714;
  font-size: 13.5px;
  font-weight: 500;
  font-family: inherit;
  cursor: pointer;
  transition: background .15s;
}
.sec-btn:hover { background: rgba(26,23,20,.04); }

/* form */
.form-title { font-family: Fraunces, Georgia, serif; font-size: 19px; font-weight: 500; color: #1A1714; margin-bottom: 18px; padding: 18px 22px 0; }
.form { display: flex; flex-direction: column; gap: 14px; }
.form-row { display: flex; flex-direction: column; grid-template-columns: 1fr 1fr; gap: 12px; }
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
.form-error { font-size: 12px; color: #B0455F; margin: 0 22px 8px; }
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
  .topbar   { padding: 24px 28px 18px; }
  .topbar__title { font-size: 26px; }
  .search-wrap { padding: 0 28px 16px; }
  .list-wrap   { padding: 0 28px 32px; }
  .card-list   { display: none; }

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
