<script setup>
import { ref, onMounted, nextTick } from 'vue'
import { getAuditoriaResumen, getEmpleados, fmtCOP } from '@/api/admin'

// ─── Estado principal ────────────────────────────────────────────────────────
const loading      = ref(false)
const error        = ref('')
const empleados    = ref([])
const kpi          = ref({ total_servicios: 0, total_clientes: 0, total_ingresos: 0, promedio_dia: 0 })
const historial    = ref([])
const grafData     = ref({
  servicios_tipo: [],
  clientes_mes:   [],
  estado_citas:   [],
  ingresos_mes:   [],
})

// ─── Filtros ─────────────────────────────────────────────────────────────────
const filtroEmpleado   = ref('todos')
const filtroFechaInicio = ref('')
const filtroFechaFin    = ref('')

// ─── Defaults (mes actual) ───────────────────────────────────────────────────
const hoy = new Date()
const primerDiaMes = `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-01`
const ultimoDia    = `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-${String(hoy.getDate()).padStart(2, '0')}`
filtroFechaInicio.value = primerDiaMes
filtroFechaFin.value    = ultimoDia

// ─── Gráficas (refs canvas) ─────────────────────────────────────────────────
const canvasServicios = ref(null)
const canvasClientes  = ref(null)
const canvasEstados   = ref(null)
const canvasIngresos  = ref(null)

// Paleta de colores del proyecto
const COLORS = {
  primary:  '#B0455F',
  secondary:'#C9A98C',
  success:  '#16a34a',
  warning:  '#d97706',
  info:     '#7c3aed',
  gray:     '#a59a8d',
}
const ESTADO_COLORS = {
  pendiente:  { bg: 'rgba(217,119,6,.75)',  border: '#d97706' },
  confirmada: { bg: 'rgba(124,58,237,.75)', border: '#7c3aed' },
  completada: { bg: 'rgba(22,163,74,.75)',  border: '#16a34a' },
  cancelada:  { bg: 'rgba(176,69,95,.75)',  border: '#B0455F' },
}

// ─── Cargar empleados al montar ──────────────────────────────────────────────
onMounted(async () => {
  try {
    empleados.value = await getEmpleados()
  } catch { /* silencioso */ }
  await cargarDatos()
})

// ─── Función principal de carga ──────────────────────────────────────────────
async function cargarDatos() {
  loading.value = true
  error.value   = ''
  try {
    const params = {}
    if (filtroEmpleado.value !== 'todos') params.empleado_id = filtroEmpleado.value
    if (filtroFechaInicio.value) params.fecha_inicio = filtroFechaInicio.value
    if (filtroFechaFin.value)    params.fecha_fin    = filtroFechaFin.value

    const res = await getAuditoriaResumen(params)

    kpi.value      = res.kpi       || kpi.value
    historial.value = res.historial || []
    grafData.value = {
      servicios_tipo: res.grafica_servicios_tipo || [],
      clientes_mes:   res.grafica_clientes_mes   || [],
      estado_citas:   res.grafica_estado_citas   || [],
      ingresos_mes:   res.grafica_ingresos_mes   || [],
    }

    await nextTick()
    dibujarGraficas()
  } catch (e) {
    error.value = e?.response?.data?.message || 'Error al cargar los datos de auditoría'
  } finally {
    loading.value = false
  }
}

// ─── Utilidades Canvas ───────────────────────────────────────────────────────
function setupCanvas(canvas) {
  if (!canvas) return null
  const dpr = window.devicePixelRatio || 1
  const w = canvas.offsetWidth || 300
  const h = canvas.offsetHeight || 200
  canvas.width  = w * dpr
  canvas.height = h * dpr
  const ctx = canvas.getContext('2d')
  ctx.scale(dpr, dpr)
  ctx.clearRect(0, 0, w, h)
  return { ctx, w, h }
}

function roundRect(ctx, x, y, w, h, r) {
  if (h <= 0) return
  r = Math.min(r, h / 2, w / 2)
  ctx.beginPath()
  ctx.moveTo(x + r, y)
  ctx.lineTo(x + w - r, y)
  ctx.quadraticCurveTo(x + w, y, x + w, y + r)
  ctx.lineTo(x + w, y + h - r)
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
  ctx.lineTo(x + r, y + h)
  ctx.quadraticCurveTo(x, y + h, x, y + h - r)
  ctx.lineTo(x, y + r)
  ctx.quadraticCurveTo(x, y, x + r, y)
  ctx.closePath()
}

// ── Gráfica 1: Barras — Servicios por tipo ────────────────────────────────
function dibujarBarrasServicios() {
  const setup = setupCanvas(canvasServicios.value)
  if (!setup) return
  const { ctx, w, h } = setup
  const data = grafData.value.servicios_tipo
  if (!data.length) { dibujarVacio(ctx, w, h, 'Sin datos'); return }

  const padL = 60, padR = 20, padT = 20, padB = 50
  const maxVal = Math.max(...data.map(d => d.cantidad), 1)
  const barW   = Math.min(48, (w - padL - padR) / data.length - 8)
  const spacing = (w - padL - padR) / data.length
  const chartH  = h - padT - padB

  // Líneas guía
  ctx.strokeStyle = 'rgba(26,23,20,.06)'
  ctx.lineWidth   = 1
  const steps = 4
  for (let i = 0; i <= steps; i++) {
    const y = padT + (chartH / steps) * i
    ctx.beginPath(); ctx.moveTo(padL, y); ctx.lineTo(w - padR, y); ctx.stroke()
  }

  data.forEach((d, i) => {
    const x   = padL + i * spacing + spacing / 2 - barW / 2
    const barH = (d.cantidad / maxVal) * chartH
    const y   = padT + chartH - barH

    const gradient = ctx.createLinearGradient(0, y, 0, y + barH)
    gradient.addColorStop(0, '#B0455F')
    gradient.addColorStop(1, 'rgba(176,69,95,.55)')
    ctx.fillStyle = gradient
    roundRect(ctx, x, y, barW, barH, 6)
    ctx.fill()

    // Valor encima
    ctx.fillStyle  = '#1A1714'
    ctx.font       = `600 11px Inter, system-ui`
    ctx.textAlign  = 'center'
    ctx.fillText(d.cantidad, x + barW / 2, y - 6)

    // Etiqueta abajo
    ctx.fillStyle  = '#8a7f72'
    ctx.font       = `500 10px Inter, system-ui`
    ctx.fillText(truncate(d.servicio, 8), x + barW / 2, h - padB + 16)
  })
}

// ── Gráfica 2: Líneas — Clientes por mes ─────────────────────────────────
function dibujarLineasClientes() {
  const setup = setupCanvas(canvasClientes.value)
  if (!setup) return
  const { ctx, w, h } = setup
  const data = grafData.value.clientes_mes
  if (!data.length) { dibujarVacio(ctx, w, h, 'Sin datos'); return }

  const padL = 50, padR = 20, padT = 20, padB = 44
  const maxVal = Math.max(...data.map(d => d.clientes), 1)
  const chartW = w - padL - padR
  const chartH = h - padT - padB
  const stepX  = chartW / Math.max(data.length - 1, 1)

  // Líneas guía
  ctx.strokeStyle = 'rgba(26,23,20,.06)'
  ctx.lineWidth   = 1
  const steps = 4
  for (let i = 0; i <= steps; i++) {
    const y = padT + (chartH / steps) * i
    ctx.beginPath(); ctx.moveTo(padL, y); ctx.lineTo(w - padR, y); ctx.stroke()
    ctx.fillStyle = '#a59a8d'; ctx.font = '500 9px Inter,system-ui'; ctx.textAlign = 'right'
    ctx.fillText(Math.round(maxVal - (maxVal / steps) * i), padL - 4, y + 3)
  }

  const points = data.map((d, i) => ({
    x: padL + i * stepX,
    y: padT + chartH - (d.clientes / maxVal) * chartH,
    label: d.etiqueta,
    val: d.clientes,
  }))

  // Área rellena
  ctx.beginPath()
  ctx.moveTo(points[0].x, h - padB)
  points.forEach(p => ctx.lineTo(p.x, p.y))
  ctx.lineTo(points[points.length - 1].x, h - padB)
  ctx.closePath()
  const areaGrad = ctx.createLinearGradient(0, padT, 0, h - padB)
  areaGrad.addColorStop(0, 'rgba(176,69,95,.18)')
  areaGrad.addColorStop(1, 'rgba(176,69,95,0)')
  ctx.fillStyle = areaGrad
  ctx.fill()

  // Línea
  ctx.beginPath()
  ctx.moveTo(points[0].x, points[0].y)
  for (let i = 1; i < points.length; i++) {
    const cp1x = (points[i-1].x + points[i].x) / 2
    ctx.bezierCurveTo(cp1x, points[i-1].y, cp1x, points[i].y, points[i].x, points[i].y)
  }
  ctx.strokeStyle = '#B0455F'; ctx.lineWidth = 2.5; ctx.stroke()

  // Puntos y etiquetas
  points.forEach(p => {
    ctx.beginPath(); ctx.arc(p.x, p.y, 4, 0, Math.PI * 2)
    ctx.fillStyle = '#fff'; ctx.fill()
    ctx.strokeStyle = '#B0455F'; ctx.lineWidth = 2; ctx.stroke()

    ctx.fillStyle = '#8a7f72'; ctx.font = '500 9px Inter,system-ui'; ctx.textAlign = 'center'
    ctx.fillText(p.label, p.x, h - padB + 14)
    ctx.fillStyle = '#1A1714'; ctx.font = '600 10px Inter,system-ui'
    ctx.fillText(p.val, p.x, p.y - 10)
  })
}

// ── Gráfica 3: Circular — Estado de citas ────────────────────────────────
function dibujarPieEstados() {
  const setup = setupCanvas(canvasEstados.value)
  if (!setup) return
  const { ctx, w, h } = setup
  const data = grafData.value.estado_citas
  if (!data.length) { dibujarVacio(ctx, w, h, 'Sin datos'); return }

  const total   = data.reduce((s, d) => s + d.total, 0)
  if (!total)   { dibujarVacio(ctx, w, h, 'Sin datos'); return }

  const cx = w / 2 - 40
  const cy = h / 2
  const r  = Math.min(cx, cy) - 20
  let   angle = -Math.PI / 2

  data.forEach(d => {
    const slice = (d.total / total) * 2 * Math.PI
    const col = ESTADO_COLORS[d.estado] || { bg: 'rgba(165,154,141,.7)', border: '#a59a8d' }
    ctx.beginPath()
    ctx.moveTo(cx, cy)
    ctx.arc(cx, cy, r, angle, angle + slice)
    ctx.closePath()
    ctx.fillStyle   = col.bg
    ctx.fill()
    ctx.strokeStyle = '#fff'; ctx.lineWidth = 2; ctx.stroke()
    angle += slice
  })

  // Donut hole
  ctx.beginPath(); ctx.arc(cx, cy, r * 0.55, 0, Math.PI * 2)
  ctx.fillStyle = '#fff'; ctx.fill()

  // Leyenda derecha
  const legendX = cx + r + 16
  let legendY = cy - (data.length * 18) / 2
  data.forEach(d => {
    const col = ESTADO_COLORS[d.estado] || { bg: '#a59a8d', border: '#a59a8d' }
    ctx.fillStyle = col.bg
    roundRect(ctx, legendX, legendY - 8, 12, 12, 3); ctx.fill()
    ctx.fillStyle = '#1A1714'; ctx.font = '500 10px Inter,system-ui'; ctx.textAlign = 'left'
    ctx.fillText(`${capitalize(d.estado)} (${d.total})`, legendX + 17, legendY + 2)
    legendY += 20
  })

  // Centro: total
  ctx.fillStyle = '#1A1714'; ctx.font = `700 18px Fraunces,Georgia,serif`; ctx.textAlign = 'center'
  ctx.fillText(total, cx, cy + 6)
  ctx.fillStyle = '#a59a8d'; ctx.font = '500 9px Inter,system-ui'
  ctx.fillText('total', cx, cy + 18)
}

// ── Gráfica 4: Barras — Ingresos por mes ─────────────────────────────────
function dibujarBarrasIngresos() {
  const setup = setupCanvas(canvasIngresos.value)
  if (!setup) return
  const { ctx, w, h } = setup
  const data = grafData.value.ingresos_mes
  if (!data.length) { dibujarVacio(ctx, w, h, 'Sin datos'); return }

  const padL = 64, padR = 20, padT = 20, padB = 50
  const maxVal = Math.max(...data.map(d => d.ingresos), 1)
  const barW   = Math.min(48, (w - padL - padR) / data.length - 8)
  const spacing = (w - padL - padR) / data.length
  const chartH  = h - padT - padB

  // Líneas guía + eje Y
  ctx.strokeStyle = 'rgba(26,23,20,.06)'; ctx.lineWidth = 1
  const steps = 4
  for (let i = 0; i <= steps; i++) {
    const y = padT + (chartH / steps) * i
    ctx.beginPath(); ctx.moveTo(padL, y); ctx.lineTo(w - padR, y); ctx.stroke()
    ctx.fillStyle = '#a59a8d'; ctx.font = '500 9px Inter,system-ui'; ctx.textAlign = 'right'
    const val = maxVal - (maxVal / steps) * i
    ctx.fillText(fmtK(val), padL - 4, y + 3)
  }

  data.forEach((d, i) => {
    const x   = padL + i * spacing + spacing / 2 - barW / 2
    const barH = (d.ingresos / maxVal) * chartH
    const y   = padT + chartH - barH

    const gradient = ctx.createLinearGradient(0, y, 0, y + barH)
    gradient.addColorStop(0, '#16a34a')
    gradient.addColorStop(1, 'rgba(22,163,74,.45)')
    ctx.fillStyle = gradient
    roundRect(ctx, x, y, barW, barH, 6); ctx.fill()

    // Valor encima
    if (d.ingresos > 0) {
      ctx.fillStyle = '#1A1714'; ctx.font = '600 9px Inter,system-ui'; ctx.textAlign = 'center'
      ctx.fillText(fmtK(d.ingresos), x + barW / 2, y - 5)
    }
    // Etiqueta
    ctx.fillStyle = '#8a7f72'; ctx.font = '500 10px Inter,system-ui'; ctx.textAlign = 'center'
    ctx.fillText(d.etiqueta, x + barW / 2, h - padB + 16)
  })
}

function dibujarGraficas() {
  dibujarBarrasServicios()
  dibujarLineasClientes()
  dibujarPieEstados()
  dibujarBarrasIngresos()
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function truncate(str, max) { return str && str.length > max ? str.slice(0, max) + '…' : str }
function capitalize(s)       { return s ? s.charAt(0).toUpperCase() + s.slice(1) : '' }
function fmtK(n)             { return n >= 1000 ? `$${(n/1000).toFixed(0)}k` : `$${n}` }
function dibujarVacio(ctx, w, h, msg) {
  ctx.fillStyle = '#a59a8d'; ctx.font = '500 12px Inter,system-ui'; ctx.textAlign = 'center'
  ctx.fillText(msg, w / 2, h / 2)
}

const estadoBadge = (estado) => {
  const map = {
    pendiente:  { bg: 'rgba(217,119,6,.12)',   color: '#b06407'  },
    confirmada: { bg: 'rgba(124,58,237,.12)',   color: '#7c3aed'  },
    completada: { bg: 'rgba(22,163,74,.12)',    color: '#15803d'  },
    cancelada:  { bg: 'rgba(176,69,95,.12)',    color: '#B0455F'  },
    pagada:     { bg: 'rgba(22,163,74,.12)',    color: '#15803d'  },
    pendiente_fac: { bg: 'rgba(217,119,6,.12)', color: '#b06407' },
    parcial:    { bg: 'rgba(124,58,237,.12)',   color: '#7c3aed'  },
  }
  return map[estado] || { bg: 'rgba(165,154,141,.12)', color: '#a59a8d' }
}
</script>

<template>
  <div class="aud">

    <!-- TOPBAR ─────────────────────────────────────────────────────────── -->
    <div class="topbar">
      <div class="topbar__left">
        <h1 class="topbar__title">Auditoría y Desempeño</h1>
        <span class="topbar__sub">Análisis del personal</span>
      </div>
    </div>

    <!-- FILTROS ─────────────────────────────────────────────────────────── -->
    <div class="filters">
      <div class="filter-group">
        <label class="filter-label">Empleado</label>
        <select v-model="filtroEmpleado" class="filter-select">
          <option value="todos">Todos los empleados</option>
          <option v-for="emp in empleados" :key="emp.id" :value="emp.id">
            {{ emp.nombre }} {{ emp.apellido }}
          </option>
        </select>
      </div>

      <div class="filter-group">
        <label class="filter-label">Fecha inicio</label>
        <input type="date" v-model="filtroFechaInicio" class="filter-input" />
      </div>

      <div class="filter-group">
        <label class="filter-label">Fecha fin</label>
        <input type="date" v-model="filtroFechaFin" class="filter-input" />
      </div>

      <button class="filter-btn" :class="{ 'filter-btn--loading': loading }" @click="cargarDatos" :disabled="loading">
        <svg v-if="!loading" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round">
          <polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/>
          <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
        </svg>
        <span class="spinner" v-else></span>
        Actualizar
      </button>
    </div>

    <!-- ERROR ───────────────────────────────────────────────────────────── -->
    <div v-if="error" class="aud-error">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>
      {{ error }}
    </div>

    <!-- KPI TARJETAS ────────────────────────────────────────────────────── -->
    <div class="kpi-grid">
      <div class="kpi-card">
        <div class="kpi-card__ico" style="background:rgba(176,69,95,.1)">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M20 4 8.12 15.88M14.8 14.8 20 20M8.12 8.12 12 12"/></svg>
        </div>
        <div class="kpi-card__body">
          <div class="kpi-card__val">{{ kpi.total_servicios }}</div>
          <div class="kpi-card__lbl">Servicios realizados</div>
          <div class="kpi-card__sub">citas completadas</div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-card__ico" style="background:rgba(22,163,74,.1)">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0M16 6.2a3 3 0 0 1 0 5.6M21 20a5 5 0 0 0-3.5-4.8"/></svg>
        </div>
        <div class="kpi-card__body">
          <div class="kpi-card__val">{{ kpi.total_clientes }}</div>
          <div class="kpi-card__lbl">Clientes atendidos</div>
          <div class="kpi-card__sub">clientes únicos</div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-card__ico" style="background:rgba(124,58,237,.1)">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="13" rx="2"/><path d="M16 7V5a2 2 0 0 0-4 0v2M12 12v3M10 14h4"/></svg>
        </div>
        <div class="kpi-card__body">
          <div class="kpi-card__val">{{ fmtCOP(kpi.total_ingresos) }}</div>
          <div class="kpi-card__lbl">Ingresos generados</div>
          <div class="kpi-card__sub">facturas pagadas</div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-card__ico" style="background:rgba(217,119,6,.1)">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>
        </div>
        <div class="kpi-card__body">
          <div class="kpi-card__val">{{ kpi.promedio_dia }}</div>
          <div class="kpi-card__lbl">Servicios / día</div>
          <div class="kpi-card__sub">promedio en el período</div>
        </div>
      </div>
    </div>

    <!-- GRÁFICAS ROW 1 ──────────────────────────────────────────────────── -->
    <div class="charts-row">
      <div class="chart-panel">
        <div class="chart-panel__head">
          <div class="chart-panel__title">Servicios realizados por tipo</div>
          <span class="chart-panel__badge">Barras</span>
        </div>
        <div class="chart-wrap">
          <canvas ref="canvasServicios" class="chart-canvas"></canvas>
        </div>
      </div>

      <div class="chart-panel">
        <div class="chart-panel__head">
          <div class="chart-panel__title">Clientes atendidos por mes</div>
          <span class="chart-panel__badge">Líneas</span>
        </div>
        <div class="chart-wrap">
          <canvas ref="canvasClientes" class="chart-canvas"></canvas>
        </div>
      </div>
    </div>

    <!-- GRÁFICAS ROW 2 ──────────────────────────────────────────────────── -->
    <div class="charts-row">
      <div class="chart-panel">
        <div class="chart-panel__head">
          <div class="chart-panel__title">Estado de las citas</div>
          <span class="chart-panel__badge">Circular</span>
        </div>
        <div class="chart-wrap">
          <canvas ref="canvasEstados" class="chart-canvas"></canvas>
        </div>
      </div>

      <div class="chart-panel">
        <div class="chart-panel__head">
          <div class="chart-panel__title">Ingresos generados por mes</div>
          <span class="chart-panel__badge">Barras</span>
        </div>
        <div class="chart-wrap">
          <canvas ref="canvasIngresos" class="chart-canvas"></canvas>
        </div>
      </div>
    </div>

    <!-- TABLA DE HISTORIAL ──────────────────────────────────────────────── -->
    <div class="table-panel">
      <div class="table-panel__head">
        <div class="table-panel__title">Historial de citas</div>
        <span class="table-panel__count">{{ historial.length }} registros</span>
      </div>

      <div class="table-scroll">
        <table class="hist-table">
          <thead>
            <tr>
              <th>Fecha</th>
              <th>Hora</th>
              <th>Cliente</th>
              <th>Doc. Cliente</th>
              <th>Tel. Cliente</th>
              <th>Empleado</th>
              <th>Doc. Empleado</th>
              <th>Servicio</th>
              <th>Precio</th>
              <th>Estado cita</th>
              <th>N° Factura</th>
              <th>Estado factura</th>
              <th>Total factura</th>
              <th>Registrado por</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="14" class="loading-row">
                <span class="spinner spinner--dark"></span> Cargando datos…
              </td>
            </tr>
            <tr v-else-if="!historial.length">
              <td colspan="14" class="empty-row">Sin registros en el período seleccionado</td>
            </tr>
            <template v-else>
              <tr v-for="(row, idx) in historial" :key="idx">
                <td>{{ row.fecha }}</td>
                <td class="mono">{{ (row.hora || '').slice(0,5) }}</td>
                <td class="fw-medium">{{ row.cliente_nombre }}</td>
                <td>{{ row.cliente_documento }}</td>
                <td>{{ row.cliente_telefono }}</td>
                <td class="fw-medium">{{ row.empleado_nombre }}</td>
                <td>{{ row.empleado_documento }}</td>
                <td>{{ row.servicio_nombre }}</td>
                <td class="mono">{{ fmtCOP(row.servicio_precio) }}</td>
                <td>
                  <span class="badge-pill" :style="{ background: estadoBadge(row.cita_estado).bg, color: estadoBadge(row.cita_estado).color }">
                    {{ row.cita_estado }}
                  </span>
                </td>
                <td class="mono">{{ row.numero_factura }}</td>
                <td>
                  <span v-if="row.factura_estado !== '—'" class="badge-pill" :style="{ background: estadoBadge(row.factura_estado).bg, color: estadoBadge(row.factura_estado).color }">
                    {{ row.factura_estado }}
                  </span>
                  <span v-else class="color-muted">—</span>
                </td>
                <td class="mono fw-medium">{{ fmtCOP(row.total_facturado) }}</td>
                <td>{{ row.usuario_admin }}</td>
              </tr>
            </template>
          </tbody>
        </table>
      </div>
    </div>

  </div>
</template>

<style scoped>
/* ─── Layout base ─────────────────────────────────────────────────────────── */
.aud {
  flex: 1;
  display: flex;
  flex-direction: column;
  font-family: Inter, system-ui, sans-serif;
  background: #FBF6F4;
  min-height: 100vh;
}

/* ─── Topbar ──────────────────────────────────────────────────────────────── */
.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 22px 20px 12px;
}
.topbar__left { display: flex; align-items: baseline; gap: 12px; }
.topbar__title {
  margin: 0;
  font-family: Fraunces, Georgia, serif;
  font-size: 22px;
  font-weight: 500;
  color: #1A1714;
  letter-spacing: -.01em;
}
.topbar__sub { font-size: 13px; color: #8a7f72; }

/* ─── Filtros ─────────────────────────────────────────────────────────────── */
.filters {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: 12px;
  padding: 0 20px 20px;
  background: #fff;
  border-bottom: 1px solid rgba(26,23,20,.07);
  margin: 0 0 20px;
  padding-top: 14px;
}
.filter-group { display: flex; flex-direction: column; gap: 5px; }
.filter-label {
  font-size: 11px;
  font-weight: 600;
  color: #8a7f72;
  letter-spacing: .04em;
  text-transform: uppercase;
}
.filter-select,
.filter-input {
  height: 38px;
  padding: 0 12px;
  border-radius: 10px;
  border: 1.5px solid rgba(26,23,20,.12);
  background: #FBF6F4;
  font-size: 13px;
  font-family: Inter, system-ui, sans-serif;
  color: #1A1714;
  outline: none;
  transition: border-color .15s;
  min-width: 160px;
}
.filter-select:focus,
.filter-input:focus { border-color: #B0455F; }

.filter-btn {
  height: 38px;
  padding: 0 18px;
  border-radius: 10px;
  border: none;
  background: #B0455F;
  color: #fff;
  font-size: 13px;
  font-weight: 600;
  font-family: Inter, system-ui, sans-serif;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 7px;
  transition: filter .2s, opacity .2s;
}
.filter-btn:hover:not(:disabled) { filter: brightness(1.08); }
.filter-btn:disabled { opacity: .65; cursor: not-allowed; }
.filter-btn--loading { opacity: .8; }

/* ─── Error ───────────────────────────────────────────────────────────────── */
.aud-error {
  display: flex; align-items: center; gap: 8px;
  margin: 0 20px 16px; padding: 11px 14px; border-radius: 11px;
  background: #fee2e2; color: #991b1b; font-size: 13px; font-weight: 500;
}

/* ─── KPI Grid ────────────────────────────────────────────────────────────── */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  padding: 0 20px 20px;
}
.kpi-card {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  padding: 18px 16px;
  background: #fff;
  border-radius: 16px;
  border: 1px solid rgba(26,23,20,.08);
  transition: box-shadow .2s;
}
.kpi-card:hover { box-shadow: 0 4px 20px rgba(176,69,95,.08); }
.kpi-card__ico {
  flex: none;
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.kpi-card__val {
  font-family: Fraunces, Georgia, serif;
  font-size: 24px;
  font-weight: 600;
  color: #1A1714;
  letter-spacing: -.01em;
  line-height: 1;
}
.kpi-card__lbl { font-size: 12px; font-weight: 600; color: #1A1714; margin-top: 5px; }
.kpi-card__sub { font-size: 11px; color: #a59a8d; margin-top: 2px; line-height: 1.35; }

/* ─── Gráficas ────────────────────────────────────────────────────────────── */
.charts-row {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 0 20px 14px;
}
.chart-panel {
  background: #fff;
  border-radius: 16px;
  border: 1px solid rgba(26,23,20,.08);
  padding: 18px 18px 14px;
}
.chart-panel__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}
.chart-panel__title {
  font-family: Fraunces, Georgia, serif;
  font-size: 15px;
  font-weight: 500;
  color: #1A1714;
}
.chart-panel__badge {
  font-size: 10px;
  font-weight: 600;
  padding: 2px 10px;
  border-radius: 20px;
  background: rgba(176,69,95,.1);
  color: #B0455F;
}
.chart-wrap {
  position: relative;
  width: 100%;
  height: 200px;
}
.chart-canvas {
  position: absolute;
  top: 0; left: 0;
  width: 100% !important;
  height: 100% !important;
}

/* ─── Tabla ───────────────────────────────────────────────────────────────── */
.table-panel {
  background: #fff;
  border-radius: 16px;
  border: 1px solid rgba(26,23,20,.08);
  margin: 0 20px 32px;
  overflow: hidden;
}
.table-panel__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 18px 14px;
  border-bottom: 1px solid rgba(26,23,20,.06);
}
.table-panel__title {
  font-family: Fraunces, Georgia, serif;
  font-size: 16px;
  font-weight: 500;
  color: #1A1714;
}
.table-panel__count {
  font-size: 12px;
  font-weight: 500;
  color: #a59a8d;
}
.table-scroll {
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}
.hist-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12.5px;
  color: #1A1714;
  min-width: 1200px;
}
.hist-table th {
  padding: 10px 14px;
  text-align: left;
  font-size: 11px;
  font-weight: 600;
  color: #8a7f72;
  letter-spacing: .04em;
  text-transform: uppercase;
  background: #FBF6F4;
  border-bottom: 1px solid rgba(26,23,20,.07);
  white-space: nowrap;
}
.hist-table td {
  padding: 10px 14px;
  border-bottom: 1px solid rgba(26,23,20,.05);
  vertical-align: middle;
  white-space: nowrap;
}
.hist-table tbody tr:hover { background: rgba(176,69,95,.03); }
.hist-table tbody tr:last-child td { border-bottom: none; }

.fw-medium { font-weight: 500; }
.mono { font-variant-numeric: tabular-nums; }
.color-muted { color: #a59a8d; }

.badge-pill {
  display: inline-block;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 9px;
  border-radius: 20px;
  white-space: nowrap;
}
.loading-row,
.empty-row {
  text-align: center;
  padding: 32px;
  color: #a59a8d;
  font-size: 13px;
}
.loading-row { display: flex; align-items: center; justify-content: center; gap: 10px; }

/* ─── Spinner ─────────────────────────────────────────────────────────────── */
.spinner {
  display: inline-block;
  width: 14px;
  height: 14px;
  border: 2px solid rgba(255,255,255,.4);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin .7s linear infinite;
}
.spinner--dark {
  border-color: rgba(176,69,95,.2);
  border-top-color: #B0455F;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* ─── Desktop ─────────────────────────────────────────────────────────────── */
@media (min-width: 1024px) {
  .topbar { padding: 24px 28px 12px; }
  .topbar__title { font-size: 26px; }

  .filters { padding: 14px 28px 20px; }

  .kpi-grid {
    grid-template-columns: repeat(4, 1fr);
    padding: 0 28px 24px;
    gap: 16px;
  }
  .charts-row {
    flex-direction: row;
    padding: 0 28px 16px;
    gap: 16px;
  }
  .charts-row > .chart-panel { flex: 1; }
  .chart-wrap { height: 240px; }

  .table-panel { margin: 0 28px 36px; }
}
</style>
