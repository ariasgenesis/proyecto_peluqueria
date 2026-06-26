<script setup>
import { computed, onMounted, ref } from 'vue'
import { getMovimientos } from '@/api/admin'

const loading        = ref(true)
const allMovimientos = ref([])
const filtroTipo     = ref('todos')
const q              = ref('')

onMounted(async () => {
  try { allMovimientos.value = await getMovimientos() }
  finally { loading.value = false }
})

const movimientos = computed(() => {
  let list = allMovimientos.value
  if (filtroTipo.value !== 'todos') list = list.filter(m => m.tipo === filtroTipo.value)
  const s = q.value.trim().toLowerCase()
  if (s) list = list.filter(m =>
    (m.descripcion || '').toLowerCase().includes(s) ||
    (m.producto || '').toLowerCase().includes(s) ||
    (m.producto_nombre || '').toLowerCase().includes(s) ||
    (m.usuario || '').toLowerCase().includes(s) ||
    (m.usuario_nombre || '').toLowerCase().includes(s) ||
    String(m.producto_id || '').includes(s) ||
    String(m.usuario_id || '').includes(s) ||
    (m.tipo || '').toLowerCase().includes(s)
  )
  return list
})

const tipoLabel = { entrada: 'Entrada', salida: 'Salida', ajuste: 'Ajuste' }

function fmtFecha(dt) { return dt ? String(dt).slice(0, 10) : '—' }
function fmtHora(dt)  { return dt ? String(dt).slice(11, 16) : '' }
function cantSign(m)  { return m.tipo === 'salida' ? -m.cantidad : m.cantidad }
</script>

<template>
  <div class="mov">

    <div class="topbar">
      <h1 class="topbar__title">Movimientos</h1>
    </div>

    <!-- toolbar -->
    <div class="toolbar">
      <div class="search">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.35-4.35"/></svg>
        <input v-model="q" class="search__input" type="search" placeholder="Buscar producto o responsable…" />
        <button v-if="q" class="search__clear" @click="q = ''">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#8a7f72" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
        </button>
      </div>
      <div class="chips">
        <button v-for="f in ['todos','entrada','salida','ajuste']" :key="f"
          class="chip" :class="{ 'chip--on': filtroTipo === f }"
          @click="filtroTipo = f">
          {{ f === 'todos' ? 'Todos' : tipoLabel[f] + 's' }}
        </button>
      </div>
    </div>

    <!-- lista -->
    <div class="list-wrap">
      <p v-if="!loading && !movimientos.length" class="empty">Sin movimientos.</p>

      <!-- tabla desktop -->
      <table class="table">
        <thead>
          <tr>
            <th>Fecha</th>
            <th>Tipo</th>
            <th>Producto</th>
            <th>Usuario</th>
            <th>Descripción</th>
            <th class="tc">Cant.</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading"><td colspan="6" style="padding:32px;text-align:center;color:#a59a8d">Cargando…</td></tr>
          <tr v-for="m in movimientos" :key="m.id_movimiento_inv || m.id_movimiento" class="table__row">
            <td class="td-muted td-nowrap">{{ fmtFecha(m.fecha) }}<br><span class="td-hora">{{ fmtHora(m.fecha) }}</span></td>
            <td>
              <span class="badge" :class="'badge--' + m.tipo">{{ tipoLabel[m.tipo] }}</span>
            </td>
            <td class="td-muted">{{ m.producto || m.producto_nombre || ('#' + m.producto_id) }}</td>
            <td class="td-muted">{{ m.usuario || m.usuario_nombre || ('#' + m.usuario_id) }}</td>
            <td class="td-concepto">{{ m.descripcion }}</td>
            <td class="tc">
              <span class="cant" :class="cantSign(m) > 0 ? 'cant--pos' : 'cant--neg'">
                {{ cantSign(m) > 0 ? '+' : '' }}{{ cantSign(m) }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- tarjetas mobile -->
      <div class="card-list">
        <div v-for="m in movimientos" :key="m.id_movimiento_inv || m.id_movimiento" class="mov-card">
          <div class="mov-card__top">
            <span class="badge" :class="'badge--' + m.tipo">{{ tipoLabel[m.tipo] }}</span>
            <span class="cant" :class="cantSign(m) > 0 ? 'cant--pos' : 'cant--neg'">
              {{ cantSign(m) > 0 ? '+' : '' }}{{ cantSign(m) }} uds
            </span>
          </div>
          <div class="mov-card__concepto">{{ m.descripcion }}</div>
          <div class="mov-card__meta">
            {{ m.producto || m.producto_nombre || ('#' + m.producto_id) }} · {{ m.usuario || m.usuario_nombre || ('#' + m.usuario_id) }} · {{ fmtFecha(m.fecha) }} · {{ fmtHora(m.fecha) }}
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
.mov {
  flex: 1; display: flex; flex-direction: column;
  font-family: Inter, system-ui, sans-serif; background: #FBF6F4; min-height: 100vh;
}

.topbar { display: flex; align-items: center; justify-content: space-between; padding: 22px 20px 14px; }
.topbar__title { margin: 0; font-family: Fraunces, Georgia, serif; font-size: 22px; font-weight: 500; color: #1A1714; letter-spacing: -.01em; }

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
.mov-card {
  background: #fff; border-radius: 14px; border: 1px solid rgba(26,23,20,.08); padding: 14px 16px;
}
.mov-card__top     { display: flex; align-items: center; justify-content: space-between; margin-bottom: 7px; }
.mov-card__concepto{ font-size: 14px; font-weight: 600; color: #1A1714; margin-bottom: 5px; }
.mov-card__meta    { font-size: 12px; color: #a59a8d; }
.mov-card__notas   { font-size: 12px; color: #8a7f72; margin-top: 5px; }

.badge { display: inline-block; font-size: 10px; font-weight: 600; padding: 2px 9px; border-radius: 20px; white-space: nowrap; }
.badge--entrada { background: rgba(22,163,74,.12);  color: #15803d; }
.badge--salida  { background: rgba(176,69,95,.10);  color: #B0455F; }
.badge--ajuste  { background: rgba(217,119,6,.14);  color: #b45309; }

.cant { font-size: 13px; font-weight: 700; }
.cant--pos { color: #15803d; }
.cant--neg { color: #B0455F; }

.td-muted    { color: #8a7f72 !important; font-size: 13px; }
.td-hora     { font-size: 11px; color: #b7ab9d; }
.td-nowrap   { white-space: nowrap; }
.td-concepto { font-size: 13.5px; font-weight: 500; color: #1A1714; max-width: 260px; }
.td-notas    { font-size: 12px; color: #8a7f72; max-width: 220px; }
.tc          { text-align: center; }

@media (min-width: 1024px) {
  .topbar   { padding: 24px 28px 18px; }
  .topbar__title { font-size: 26px; }
  .toolbar  { padding: 0 28px 14px; flex-direction: row; align-items: center; gap: 14px; }
  .search   { max-width: 340px; }
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
  .table thead th.tc { text-align: center; }
  .table__row td { padding: 11px 14px; border-bottom: 1px solid rgba(26,23,20,.06); vertical-align: middle; }
  .table__row:last-child td { border-bottom: none; }
}
</style>
