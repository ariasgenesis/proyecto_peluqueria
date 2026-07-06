<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { apiErrorMessage } from '@/api/client'
import { fmtCOP, getAuditoriaPersonal, getEmpleados } from '@/api/admin'

const today = new Date()
const firstDay = new Date(today.getFullYear(), today.getMonth(), 1)
const toDateInput = (date) => date.toISOString().slice(0, 10)

const filtros = reactive({
  empleado_id: '',
  fecha_inicio: toDateInput(firstDay),
  fecha_fin: toDateInput(today),
})

const empleados = ref([])
const reporte = ref({
  metricas: {},
  servicios_por_empleado: [],
  clientes_por_mes: [],
  citas_por_estado: [],
  ingresos_por_mes: [],
  clientes_frecuentes: [],
  productividad_semanal: [],
  historial: [],
})
const loading = ref(true)
const empleadosLoading = ref(true)
const error = ref('')
const busquedaTabla = ref('')
const sortKey = ref('fecha')
const sortDir = ref('desc')
const currentPage = ref(1)
const perPage = ref(10)
let debounceId = null
let requestSeq = 0

const monthNames = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic']
const statusColors = {
  pendiente: '#d97706',
  confirmada: '#7c3aed',
  completada: '#16a34a',
  cancelada: '#B0455F',
}

function formatMonth(value) {
  if (!value) return ''
  const [year, month] = value.split('-').map(Number)
  return `${monthNames[(month || 1) - 1]} ${String(year).slice(2)}`
}

function buildParams() {
  return {
    empleado_id: filtros.empleado_id || undefined,
    fecha_inicio: filtros.fecha_inicio || undefined,
    fecha_fin: filtros.fecha_fin || undefined,
  }
}

async function cargarReporte() {
  const seq = ++requestSeq
  loading.value = true
  error.value = ''
  try {
    const data = await getAuditoriaPersonal(buildParams())
    if (seq !== requestSeq) return
    reporte.value = data
  } catch (e) {
    if (seq !== requestSeq) return
    error.value = apiErrorMessage(e, 'No se pudo cargar la auditoria de personal')
  } finally {
    if (seq === requestSeq) loading.value = false
  }
}

function actualizar() {
  window.clearTimeout(debounceId)
  cargarReporte()
}

onMounted(async () => {
  getEmpleados({ estado: 'activo' })
    .then(data => { empleados.value = data || [] })
    .catch(() => { empleados.value = [] })
    .finally(() => { empleadosLoading.value = false })
  cargarReporte()
})

watch(filtros, () => {
  window.clearTimeout(debounceId)
  debounceId = window.setTimeout(cargarReporte, 250)
}, { deep: true })

const metricas = computed(() => reporte.value.metricas || {})
const servicios = computed(() => reporte.value.servicios_por_empleado || [])
const clientesMes = computed(() => reporte.value.clientes_por_mes || [])
const estados = computed(() => reporte.value.citas_por_estado || [])
const ingresosMes = computed(() => reporte.value.ingresos_por_mes || [])
const clientesFrecuentes = computed(() => reporte.value.clientes_frecuentes || [])
const productividadSemanal = computed(() => reporte.value.productividad_semanal || [])
const historial = computed(() => reporte.value.historial || [])

const cards = computed(() => [
  { label: 'Servicios realizados', value: metricas.value.total_servicios ?? 0, sub: 'citas completadas', accent: '#B0455F', icon: 'scissors' },
  { label: 'Clientes atendidos', value: metricas.value.total_clientes ?? 0, sub: 'clientes unicos', accent: '#16a34a', icon: 'users' },
  { label: 'Ingresos generados', value: fmtCOP(metricas.value.total_ingresos || 0), sub: 'facturas de citas', accent: '#d97706', icon: 'money' },
  { label: 'Promedio diario', value: Number(metricas.value.promedio_servicios_dia || 0).toFixed(2), sub: 'servicios por dia', accent: '#7c3aed', icon: 'chart' },
])

const maxServicios = computed(() => Math.max(1, ...servicios.value.map(item => item.total || 0)))
const maxIngresos = computed(() => Math.max(1, ...ingresosMes.value.map(item => item.total || 0)))
const maxProductividad = computed(() => Math.max(1, ...productividadSemanal.value.map(item => item.total || 0)))
const chartWidth = 620
const chartHeight = 220
const chartPad = 34
const maxClientes = computed(() => Math.max(1, ...clientesMes.value.map(item => item.total || 0)))
const tableColumns = [
  { key: 'fecha', label: 'Fecha' },
  { key: 'hora', label: 'Hora' },
  { key: 'cliente', label: 'Cliente' },
  { key: 'cliente_documento', label: 'Documento cliente' },
  { key: 'cliente_telefono', label: 'Telefono cliente' },
  { key: 'empleado', label: 'Empleado' },
  { key: 'empleado_documento', label: 'Documento empleado' },
  { key: 'servicio', label: 'Servicio realizado' },
  { key: 'precio_servicio', label: 'Precio servicio', numeric: true },
  { key: 'estado_cita', label: 'Estado cita' },
  { key: 'numero_factura', label: 'Numero factura' },
  { key: 'estado_factura', label: 'Estado factura' },
  { key: 'total_facturado', label: 'Total facturado', numeric: true },
  { key: 'usuario_registro', label: 'Usuario registro' },
]

const linePoints = computed(() => {
  const data = clientesMes.value
  const usableW = chartWidth - chartPad * 2
  const usableH = chartHeight - chartPad * 2
  if (!data.length) return []
  return data.map((item, index) => {
    const x = chartPad + (data.length === 1 ? usableW / 2 : (usableW / (data.length - 1)) * index)
    const y = chartHeight - chartPad - ((item.total || 0) / maxClientes.value) * usableH
    return { ...item, x, y, label: formatMonth(item.mes) }
  })
})

const linePath = computed(() =>
  linePoints.value.map((point, index) => `${index ? 'L' : 'M'} ${point.x} ${point.y}`).join(' ')
)

const pieTotal = computed(() => estados.value.reduce((sum, item) => sum + Number(item.total || 0), 0))
function piePath(startAngle, endAngle, radius = 74) {
  const cx = 90
  const cy = 90
  const toPoint = (angle) => {
    const rad = (angle - 90) * Math.PI / 180
    return { x: cx + radius * Math.cos(rad), y: cy + radius * Math.sin(rad) }
  }
  const start = toPoint(startAngle)
  const end = toPoint(endAngle)
  const largeArc = endAngle - startAngle > 180 ? 1 : 0
  return `M ${cx} ${cy} L ${start.x} ${start.y} A ${radius} ${radius} 0 ${largeArc} 1 ${end.x} ${end.y} Z`
}

const pieSlices = computed(() => {
  if (!pieTotal.value) return []
  let angle = 0
  return estados.value
    .filter(item => Number(item.total || 0) > 0)
    .map(item => {
      const size = (Number(item.total || 0) / pieTotal.value) * 360
      const slice = {
        ...item,
        color: statusColors[item.estado] || '#8a7f72',
        d: piePath(angle, angle + size),
      }
      angle += size
      return slice
    })
})

const estadoLabel = (estado) => {
  const item = estados.value.find(e => e.estado === estado)
  return item?.label || estado || 'Sin estado'
}

const badgeStyle = (estado) => {
  const color = statusColors[estado] || '#8a7f72'
  return { background: `${color}18`, color }
}

function formatDuration(minutes) {
  const total = Math.round(Number(minutes || 0))
  const hours = Math.floor(total / 60)
  const mins = total % 60
  if (!hours) return `${mins} min`
  return mins ? `${hours} h ${mins} min` : `${hours} h`
}

function sortIndicator(key) {
  if (sortKey.value !== key) return ''
  return sortDir.value === 'asc' ? ' (asc)' : ' (desc)'
}

function ordenarPor(key) {
  if (sortKey.value === key) {
    sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = key
    sortDir.value = 'asc'
  }
  currentPage.value = 1
}

function cellValue(row, key) {
  if (key === 'estado_cita') return estadoLabel(row.estado_cita)
  return row[key] ?? ''
}

const historialFiltrado = computed(() => {
  const query = busquedaTabla.value.trim().toLowerCase()
  if (!query) return historial.value
  const fields = [
    'cliente',
    'cliente_documento',
    'empleado',
    'empleado_documento',
    'servicio',
    'estado_cita',
    'estado_factura',
  ]
  return historial.value.filter(row =>
    fields.some(field => String(cellValue(row, field)).toLowerCase().includes(query))
  )
})

const historialOrdenado = computed(() => {
  const direction = sortDir.value === 'asc' ? 1 : -1
  return [...historialFiltrado.value].sort((a, b) => {
    const column = tableColumns.find(item => item.key === sortKey.value)
    const aValue = cellValue(a, sortKey.value)
    const bValue = cellValue(b, sortKey.value)
    if (column?.numeric) return (Number(aValue || 0) - Number(bValue || 0)) * direction
    return String(aValue).localeCompare(String(bValue), 'es', { numeric: true, sensitivity: 'base' }) * direction
  })
})

const totalPages = computed(() => Math.max(1, Math.ceil(historialOrdenado.value.length / Number(perPage.value || 10))))
const historialPaginado = computed(() => {
  const start = (currentPage.value - 1) * Number(perPage.value || 10)
  return historialOrdenado.value.slice(start, start + Number(perPage.value || 10))
})
const tableRange = computed(() => {
  if (!historialOrdenado.value.length) return '0 de 0'
  const start = (currentPage.value - 1) * Number(perPage.value || 10) + 1
  const end = Math.min(start + Number(perPage.value || 10) - 1, historialOrdenado.value.length)
  return `${start}-${end} de ${historialOrdenado.value.length}`
})

watch([busquedaTabla, perPage], () => {
  currentPage.value = 1
})

watch(totalPages, (pages) => {
  if (currentPage.value > pages) currentPage.value = pages
})

function exportRows() {
  return historialOrdenado.value.map(row => ({
    ...row,
    estado_cita_label: estadoLabel(row.estado_cita),
    precio_servicio_fmt: fmtCOP(row.precio_servicio),
    total_facturado_fmt: fmtCOP(row.total_facturado),
  }))
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
}

function exportarExcel() {
  const rows = exportRows()
  const headers = tableColumns.map(column => column.label)
  const body = rows.map(row => tableColumns.map(column => {
    if (column.key === 'estado_cita') return row.estado_cita_label
    if (column.key === 'precio_servicio') return row.precio_servicio_fmt
    if (column.key === 'total_facturado') return row.total_facturado_fmt
    return cellValue(row, column.key)
  }))
  const html = `<table><thead><tr>${headers.map(h => `<th>${escapeHtml(h)}</th>`).join('')}</tr></thead><tbody>${body.map(cells => `<tr>${cells.map(cell => `<td>${escapeHtml(cell)}</td>`).join('')}</tr>`).join('')}</tbody></table>`
  const blob = new Blob([`\ufeff${html}`], { type: 'application/vnd.ms-excel;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = 'auditoria-personal.xls'
  link.click()
  URL.revokeObjectURL(url)
}

function exportarPdf() {
  const rows = exportRows()
  const headers = tableColumns.map(column => column.label)
  const body = rows.map(row => tableColumns.map(column => {
    if (column.key === 'estado_cita') return row.estado_cita_label
    if (column.key === 'precio_servicio') return row.precio_servicio_fmt
    if (column.key === 'total_facturado') return row.total_facturado_fmt
    return cellValue(row, column.key)
  }))
  const popup = window.open('', '_blank')
  if (!popup) {
    error.value = 'El navegador bloqueo la ventana de exportacion a PDF'
    return
  }
  popup.document.write(`
    <html>
      <head>
        <title>Auditoria de personal</title>
        <style>
          body { font-family: Arial, sans-serif; color: #1A1714; }
          h1 { font-size: 20px; margin-bottom: 4px; }
          p { color: #6b6258; font-size: 12px; margin-top: 0; }
          table { width: 100%; border-collapse: collapse; font-size: 10px; }
          th, td { border: 1px solid #ddd; padding: 5px; text-align: left; }
          th { background: #FBF6F4; }
        </style>
      </head>
      <body>
        <h1>Auditoria y Desempeno del Personal</h1>
        <p>Rango: ${escapeHtml(filtros.fecha_inicio)} a ${escapeHtml(filtros.fecha_fin)}</p>
        <table>
          <thead><tr>${headers.map(h => `<th>${escapeHtml(h)}</th>`).join('')}</tr></thead>
          <tbody>${body.map(cells => `<tr>${cells.map(cell => `<td>${escapeHtml(cell)}</td>`).join('')}</tr>`).join('')}</tbody>
        </table>
      </body>
    </html>
  `)
  popup.document.close()
  popup.focus()
  popup.print()
}
</script>

<template>
  <div class="audit">
    <div class="topbar">
      <div class="topbar__left">
        <h1 class="topbar__title">Auditor&iacute;a y Desempe&ntilde;o del Personal</h1>
        <span class="topbar__date">Analisis administrativo</span>
      </div>
      <button class="topbar__btn" :disabled="loading" @click="actualizar">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 0 1-15.5 6.2"/><path d="M3 12A9 9 0 0 1 18.5 5.8"/><path d="M18 2v4h4M6 22v-4H2"/></svg>
        Actualizar
      </button>
    </div>

    <section class="filters">
      <label class="field">
        <span>Empleado</span>
        <select v-model="filtros.empleado_id" :disabled="empleadosLoading">
          <option value="">Todos</option>
          <option v-for="empleado in empleados" :key="empleado.id_empleado" :value="empleado.id_empleado">
            {{ empleado.nombre }} {{ empleado.apellido }}
          </option>
        </select>
      </label>
      <label class="field">
        <span>Fecha inicial</span>
        <input v-model="filtros.fecha_inicio" type="date">
      </label>
      <label class="field">
        <span>Fecha final</span>
        <input v-model="filtros.fecha_fin" type="date">
      </label>
    </section>

    <div v-if="error" class="dash-error">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 8v4M12 16h.01"/></svg>
      {{ error }}
    </div>

    <div class="stats">
      <template v-if="loading">
        <div v-for="k in 4" :key="k" class="stat">
          <div class="shimmer" style="width:42px;height:42px;border-radius:12px;flex:none"></div>
          <div style="flex:1">
            <div class="shimmer sk-line" style="width:50%;height:18px;margin-bottom:6px"></div>
            <div class="shimmer sk-line" style="width:70%;height:12px;margin-bottom:4px"></div>
            <div class="shimmer sk-line" style="width:40%;height:10px"></div>
          </div>
        </div>
      </template>
      <template v-else>
        <div v-for="card in cards" :key="card.label" class="stat">
          <div class="stat__ico" :style="{ background: card.accent + '18' }">
            <svg v-if="card.icon === 'scissors'" width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="card.accent" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M20 4 8.12 15.88M14.8 14.8 20 20M8.12 8.12 12 12"/></svg>
            <svg v-else-if="card.icon === 'users'" width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="card.accent" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0M16 6.2a3 3 0 0 1 0 5.6M21 20a5 5 0 0 0-3.5-4.8"/></svg>
            <svg v-else-if="card.icon === 'money'" width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="card.accent" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="13" rx="2"/><path d="M16 7V5a2 2 0 0 0-4 0v2M12 12v3M10 14h4"/></svg>
            <svg v-else width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="card.accent" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="m7 15 4-4 3 3 5-7"/><path d="M7 19v-4M12 19v-8M17 19v-6"/></svg>
          </div>
          <div class="stat__body">
            <div class="stat__val">{{ card.value }}</div>
            <div class="stat__lbl">{{ card.label }}</div>
            <div class="stat__sub">{{ card.sub }}</div>
          </div>
        </div>
      </template>
    </div>

    <section class="insights-grid">
      <article class="panel">
        <div class="panel__head">
          <div class="panel__title">Tiempo trabajado</div>
        </div>
        <div class="time-grid">
          <div class="time-card">
            <span>Tiempo total trabajado</span>
            <strong>{{ formatDuration(metricas.tiempo_total_minutos) }}</strong>
          </div>
          <div class="time-card">
            <span>Duracion promedio por cita</span>
            <strong>{{ formatDuration(metricas.duracion_promedio_cita_minutos) }}</strong>
          </div>
        </div>
      </article>

      <article class="panel">
        <div class="panel__head">
          <div class="panel__title">Clientes frecuentes</div>
        </div>
        <div v-if="clientesFrecuentes.length" class="frequent-list">
          <div v-for="cliente in clientesFrecuentes" :key="`${cliente.documento}-${cliente.cliente}`" class="frequent-row">
            <div>
              <strong>{{ cliente.cliente }}</strong>
              <span>{{ cliente.documento }}</span>
            </div>
            <em>{{ cliente.visitas }} visita(s)</em>
          </div>
        </div>
        <p v-else class="empty empty--tight">Sin clientes frecuentes en el rango.</p>
      </article>
    </section>

    <section class="chart-grid">
      <article class="panel">
        <div class="panel__head">
          <div class="panel__title">Servicios realizados por empleado</div>
        </div>
        <div v-if="servicios.length" class="hbars">
          <div v-for="item in servicios" :key="item.servicio" class="hbar">
            <div class="hbar__meta">
              <span>{{ item.servicio }}</span>
              <strong>{{ item.total }}</strong>
            </div>
            <div class="hbar__track"><span :style="{ width: `${(item.total / maxServicios) * 100}%` }"></span></div>
          </div>
        </div>
        <p v-else class="empty">Sin servicios completados en el rango.</p>
      </article>

      <article class="panel">
        <div class="panel__head">
          <div class="panel__title">Clientes atendidos por mes</div>
        </div>
        <div v-if="clientesMes.length" class="svg-wrap">
          <svg class="line-chart" :viewBox="`0 0 ${chartWidth} ${chartHeight}`" role="img">
            <path :d="`M ${chartPad} ${chartHeight - chartPad} H ${chartWidth - chartPad}`" stroke="#eadfdd" stroke-width="1.5"/>
            <path :d="linePath" fill="none" stroke="#B0455F" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
            <g v-for="point in linePoints" :key="point.mes">
              <circle :cx="point.x" :cy="point.y" r="5" fill="#B0455F"/>
              <text :x="point.x" :y="chartHeight - 10" text-anchor="middle">{{ point.label }}</text>
              <text :x="point.x" :y="point.y - 12" text-anchor="middle" class="point-label">{{ point.total }}</text>
            </g>
          </svg>
        </div>
        <p v-else class="empty">Sin clientes atendidos en el rango.</p>
      </article>

      <article class="panel">
        <div class="panel__head">
          <div class="panel__title">Estado de las citas</div>
        </div>
        <div class="pie-layout">
          <svg v-if="pieTotal" class="pie" viewBox="0 0 180 180" role="img">
            <path v-for="slice in pieSlices" :key="slice.estado" :d="slice.d" :fill="slice.color"/>
            <circle cx="90" cy="90" r="43" fill="#fff"/>
            <text x="90" y="87" text-anchor="middle" class="pie__total">{{ pieTotal }}</text>
            <text x="90" y="106" text-anchor="middle" class="pie__sub">citas</text>
          </svg>
          <div v-else class="pie-empty">0</div>
          <div class="legend">
            <div v-for="item in estados" :key="item.estado" class="legend__row">
              <span :style="{ background: statusColors[item.estado] || '#8a7f72' }"></span>
              <p>{{ item.label }}</p>
              <strong>{{ item.total }}</strong>
            </div>
          </div>
        </div>
      </article>

      <article class="panel">
        <div class="panel__head">
          <div class="panel__title">Ingresos generados por mes</div>
        </div>
        <div v-if="ingresosMes.length" class="vbars">
          <div v-for="item in ingresosMes" :key="item.mes" class="vbar">
            <div class="vbar__col">
              <span :style="{ height: `${Math.max(4, (item.total / maxIngresos) * 100)}%` }"></span>
            </div>
            <div class="vbar__label">{{ formatMonth(item.mes) }}</div>
            <div class="vbar__value">{{ fmtCOP(item.total) }}</div>
          </div>
        </div>
        <p v-else class="empty">Sin facturas asociadas en el rango.</p>
      </article>

      <article class="panel">
        <div class="panel__head">
          <div class="panel__title">Productividad semanal</div>
        </div>
        <div class="week-bars">
          <div v-for="item in productividadSemanal" :key="item.dia" class="week-bar">
            <div class="week-bar__col">
              <span :style="{ height: `${Math.max(4, (item.total / maxProductividad) * 100)}%` }"></span>
            </div>
            <div class="week-bar__label">{{ item.label }}</div>
            <strong>{{ item.total }}</strong>
          </div>
        </div>
      </article>
    </section>

    <section class="panel history-panel">
      <div class="panel__head">
        <div>
          <div class="panel__title">Historial de citas y facturacion</div>
          <div class="panel__hint">{{ tableRange }} registro(s)</div>
        </div>
        <div class="table-actions">
          <button class="table-btn" type="button" @click="exportarPdf">PDF</button>
          <button class="table-btn" type="button" @click="exportarExcel">Excel</button>
        </div>
      </div>
      <div class="table-tools">
        <label class="search-box">
          <span>Busqueda rapida</span>
          <input v-model="busquedaTabla" type="search" placeholder="Cliente, documento, empleado, servicio o estado">
        </label>
        <label class="page-size">
          <span>Filas</span>
          <select v-model.number="perPage">
            <option :value="5">5</option>
            <option :value="10">10</option>
            <option :value="20">20</option>
            <option :value="50">50</option>
          </select>
        </label>
      </div>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th v-for="column in tableColumns" :key="column.key">
                <button class="sort-btn" type="button" @click="ordenarPor(column.key)">
                  {{ column.label }}{{ sortIndicator(column.key) }}
                </button>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in historialPaginado" :key="`${row.fecha}-${row.hora}-${row.empleado}-${row.servicio}-${row.numero_factura}`">
              <td>{{ row.fecha }}</td>
              <td>{{ (row.hora || '').slice(0, 5) }}</td>
              <td>{{ row.cliente }}</td>
              <td>{{ row.cliente_documento }}</td>
              <td>{{ row.cliente_telefono }}</td>
              <td>{{ row.empleado }}</td>
              <td>{{ row.empleado_documento }}</td>
              <td>{{ row.servicio }}</td>
              <td>{{ fmtCOP(row.precio_servicio) }}</td>
              <td><span class="badge" :style="badgeStyle(row.estado_cita)">{{ estadoLabel(row.estado_cita) }}</span></td>
              <td>{{ row.numero_factura }}</td>
              <td>{{ row.estado_factura }}</td>
              <td>{{ fmtCOP(row.total_facturado) }}</td>
              <td>{{ row.usuario_registro }}</td>
            </tr>
            <tr v-if="!historialOrdenado.length">
              <td colspan="14" class="empty-row">No hay historial para los filtros seleccionados.</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="pager">
        <button type="button" :disabled="currentPage <= 1" @click="currentPage--">Anterior</button>
        <span>Pagina {{ currentPage }} de {{ totalPages }}</span>
        <button type="button" :disabled="currentPage >= totalPages" @click="currentPage++">Siguiente</button>
      </div>
    </section>
  </div>
</template>

<style scoped>
*, *::before, *::after { box-sizing: border-box; }

.audit {
  flex: 1;
  display: flex;
  flex-direction: column;
  font-family: Inter, system-ui, sans-serif;
  background: #FBF6F4;
  min-height: 100vh;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  padding: 22px 20px 16px;
}
.topbar__left { min-width: 0; }
.topbar__title {
  margin: 0;
  font-family: Fraunces, Georgia, serif;
  font-size: 21px;
  font-weight: 500;
  color: #1A1714;
}
.topbar__date { display: block; margin-top: 4px; font-size: 13px; color: #8a7f72; }
.topbar__btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
  min-height: 38px;
  padding: 0 16px;
  border: none;
  border-radius: 11px;
  background: #B0455F;
  color: #FBF6F4;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}
.topbar__btn:disabled { opacity: .65; cursor: wait; }

.filters {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
  padding: 0 20px 16px;
}
.field {
  display: flex;
  flex-direction: column;
  gap: 7px;
}
.field span {
  font-size: 12px;
  font-weight: 700;
  color: #6b6258;
}
.field select,
.field input {
  width: 100%;
  height: 42px;
  border: 1px solid rgba(26,23,20,.10);
  border-radius: 12px;
  background: #fff;
  color: #1A1714;
  padding: 0 12px;
  font: inherit;
  font-size: 13px;
}

.dash-error {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 20px 12px;
  padding: 11px 14px;
  border-radius: 11px;
  background: #fee2e2;
  color: #991b1b;
  font-size: 13px;
  font-weight: 500;
}

.stats {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  padding: 0 20px 16px;
}
.stat {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  min-width: 0;
  padding: 16px;
  background: #fff;
  border-radius: 16px;
  border: 1px solid rgba(26,23,20,.08);
}
.stat__ico {
  flex: none;
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.stat__body { min-width: 0; }
.stat__val {
  font-family: Fraunces, Georgia, serif;
  font-size: 22px;
  font-weight: 600;
  color: #1A1714;
  line-height: 1;
  overflow-wrap: anywhere;
}
.stat__lbl { margin-top: 4px; font-size: 12px; font-weight: 700; color: #1A1714; }
.stat__sub { margin-top: 2px; font-size: 11px; color: #a59a8d; line-height: 1.35; }

.insights-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 14px;
  padding: 0 20px 14px;
}

.chart-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 14px;
  padding: 0 20px 14px;
}
.panel {
  background: #fff;
  border-radius: 16px;
  border: 1px solid rgba(26,23,20,.08);
  padding: 18px;
  min-width: 0;
}
.panel__head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 16px;
}
.panel__title {
  font-family: Fraunces, Georgia, serif;
  font-size: 16px;
  font-weight: 500;
  color: #1A1714;
}
.panel__hint { margin-top: 4px; font-size: 12px; color: #a59a8d; }
.empty {
  margin: 0;
  padding: 36px 0;
  text-align: center;
  font-size: 13px;
  color: #a59a8d;
}
.empty--tight { padding: 18px 0; }

.time-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
}
.time-card {
  padding: 14px;
  border-radius: 12px;
  background: #FBF6F4;
  border: 1px solid rgba(26,23,20,.07);
}
.time-card span {
  display: block;
  font-size: 12px;
  color: #8a7f72;
  margin-bottom: 6px;
}
.time-card strong {
  display: block;
  font-family: Fraunces, Georgia, serif;
  font-size: 24px;
  color: #1A1714;
}

.frequent-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.frequent-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 11px 0;
  border-bottom: 1px solid rgba(26,23,20,.06);
}
.frequent-row:last-child { border-bottom: none; }
.frequent-row div { min-width: 0; }
.frequent-row strong {
  display: block;
  font-size: 13px;
  color: #1A1714;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.frequent-row span {
  display: block;
  margin-top: 2px;
  font-size: 11.5px;
  color: #a59a8d;
}
.frequent-row em {
  flex: none;
  font-style: normal;
  font-size: 11px;
  font-weight: 800;
  color: #B0455F;
  background: rgba(176,69,95,.10);
  border-radius: 20px;
  padding: 4px 9px;
}

.hbars { display: flex; flex-direction: column; gap: 13px; }
.hbar__meta {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 7px;
  font-size: 13px;
  color: #1A1714;
}
.hbar__meta span { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.hbar__track {
  height: 10px;
  overflow: hidden;
  border-radius: 20px;
  background: #F1E5E3;
}
.hbar__track span {
  display: block;
  height: 100%;
  border-radius: inherit;
  background: linear-gradient(90deg, #B0455F, #C9A98C);
}

.svg-wrap { overflow-x: auto; }
.line-chart {
  width: 100%;
  min-width: 420px;
  height: 240px;
}
.line-chart text { fill: #8a7f72; font-size: 12px; }
.line-chart .point-label { fill: #1A1714; font-weight: 700; }

.pie-layout {
  display: grid;
  grid-template-columns: 180px 1fr;
  gap: 18px;
  align-items: center;
}
.pie { width: 180px; height: 180px; }
.pie__total {
  font-family: Fraunces, Georgia, serif;
  font-size: 26px;
  font-weight: 700;
  fill: #1A1714;
}
.pie__sub { font-size: 12px; fill: #8a7f72; }
.pie-empty {
  width: 180px;
  height: 180px;
  border-radius: 50%;
  background: #F1E5E3;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: Fraunces, Georgia, serif;
  font-size: 28px;
  color: #a59a8d;
}
.legend { display: flex; flex-direction: column; gap: 10px; }
.legend__row {
  display: grid;
  grid-template-columns: 10px 1fr auto;
  gap: 9px;
  align-items: center;
  font-size: 13px;
}
.legend__row span { width: 10px; height: 10px; border-radius: 50%; }
.legend__row p { margin: 0; color: #6b6258; }
.legend__row strong { color: #1A1714; }

.vbars {
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: minmax(74px, 1fr);
  align-items: end;
  gap: 12px;
  min-height: 260px;
  overflow-x: auto;
}
.vbar {
  min-width: 74px;
  text-align: center;
}
.vbar__col {
  height: 170px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  padding: 0 12px;
  border-bottom: 1px solid #eadfdd;
}
.vbar__col span {
  width: 100%;
  min-width: 20px;
  border-radius: 10px 10px 0 0;
  background: linear-gradient(180deg, #C9A98C, #B0455F);
}
.vbar__label { margin-top: 8px; font-size: 12px; font-weight: 700; color: #1A1714; }
.vbar__value { margin-top: 3px; font-size: 10.5px; color: #8a7f72; overflow-wrap: anywhere; }

.week-bars {
  display: grid;
  grid-template-columns: repeat(7, minmax(58px, 1fr));
  gap: 10px;
  min-height: 240px;
  overflow-x: auto;
  align-items: end;
}
.week-bar {
  min-width: 58px;
  text-align: center;
}
.week-bar__col {
  height: 160px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  padding: 0 8px;
  border-bottom: 1px solid #eadfdd;
}
.week-bar__col span {
  width: 100%;
  min-width: 18px;
  border-radius: 10px 10px 0 0;
  background: linear-gradient(180deg, #B0455F, #7a3a4f);
}
.week-bar__label {
  margin-top: 8px;
  font-size: 11px;
  font-weight: 700;
  color: #1A1714;
}
.week-bar strong {
  display: block;
  margin-top: 3px;
  font-size: 12px;
  color: #8a7f72;
}

.history-panel { margin: 0 20px 28px; }
.table-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  justify-content: flex-end;
}
.table-btn {
  height: 34px;
  padding: 0 12px;
  border: 1px solid rgba(176,69,95,.18);
  border-radius: 10px;
  background: rgba(176,69,95,.10);
  color: #B0455F;
  font-size: 12px;
  font-weight: 800;
  cursor: pointer;
}
.table-tools {
  display: grid;
  grid-template-columns: 1fr;
  gap: 10px;
  margin-bottom: 12px;
}
.search-box,
.page-size {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.search-box span,
.page-size span {
  font-size: 11px;
  font-weight: 800;
  color: #6b6258;
}
.search-box input,
.page-size select {
  height: 38px;
  border: 1px solid rgba(26,23,20,.10);
  border-radius: 11px;
  background: #fff;
  color: #1A1714;
  padding: 0 11px;
  font: inherit;
  font-size: 12.5px;
}
.table-wrap {
  width: 100%;
  overflow: auto;
  border: 1px solid rgba(26,23,20,.07);
  border-radius: 12px;
}
table {
  width: 100%;
  min-width: 1320px;
  border-collapse: collapse;
}
th,
td {
  padding: 11px 12px;
  border-bottom: 1px solid rgba(26,23,20,.06);
  text-align: left;
  font-size: 12.5px;
  vertical-align: middle;
}
th {
  position: sticky;
  top: 0;
  z-index: 1;
  background: #FBF6F4;
  color: #6b6258;
  font-weight: 800;
  white-space: nowrap;
}
.sort-btn {
  border: none;
  background: transparent;
  color: inherit;
  padding: 0;
  font: inherit;
  font-weight: inherit;
  cursor: pointer;
  white-space: nowrap;
}
td { color: #1A1714; }
tbody tr:last-child td { border-bottom: none; }
.badge {
  display: inline-flex;
  align-items: center;
  padding: 3px 9px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 700;
  white-space: nowrap;
}
.empty-row {
  padding: 28px 12px;
  text-align: center;
  color: #a59a8d;
}
.pager {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 12px;
  font-size: 12px;
  color: #8a7f72;
}
.pager button {
  height: 32px;
  border: 1px solid rgba(26,23,20,.10);
  border-radius: 9px;
  background: #fff;
  color: #1A1714;
  padding: 0 11px;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
}
.pager button:disabled {
  opacity: .45;
  cursor: not-allowed;
}

.sk-line { border-radius: 5px; }
@keyframes shimmer { from { background-position: -200% 0; } to { background-position: 200% 0; } }
.shimmer {
  background: linear-gradient(90deg, #f0ece8 25%, #e8e3de 50%, #f0ece8 75%);
  background-size: 200% 100%;
  animation: shimmer 1.4s infinite;
}

@media (max-width: 680px) {
  .topbar { align-items: flex-start; flex-direction: column; }
  .topbar__btn { width: 100%; }
  .stats { grid-template-columns: 1fr; }
  .pie-layout { grid-template-columns: 1fr; justify-items: center; }
  .legend { width: 100%; }
}

@media (min-width: 768px) {
  .filters {
    grid-template-columns: 1.4fr 1fr 1fr;
  }
  .insights-grid {
    grid-template-columns: 1fr 1fr;
  }
  .time-grid {
    grid-template-columns: 1fr 1fr;
  }
  .table-tools {
    grid-template-columns: 1fr 120px;
    align-items: end;
  }
}

@media (min-width: 1024px) {
  .topbar { padding: 24px 28px 20px; }
  .topbar__title { font-size: 26px; }
  .filters { padding: 0 28px 20px; }
  .stats {
    grid-template-columns: repeat(4, 1fr);
    padding: 0 28px 20px;
    gap: 16px;
  }
  .insights-grid {
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    padding: 0 28px 20px;
  }
  .chart-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 20px;
    padding: 0 28px 20px;
  }
  .history-panel { margin: 0 28px 32px; }
}
</style>
