<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'
import mapboxgl from 'mapbox-gl'
import 'mapbox-gl/dist/mapbox-gl.css'

// Mapa estilizado del salón (editorial). Token público pk.* en VITE_MAPBOX_TOKEN.
const props = defineProps({
  lng: { type: Number, default: -70.619 },
  lat: { type: Number, default: -33.4265 },
  address: { type: String, default: 'Av. Providencia 1234, Santiago' },
})

const el = ref(null)
const ok = ref(false)
let map = null

const directionsUrl = `https://www.google.com/maps/dir/?api=1&destination=${props.lat},${props.lng}`

onMounted(() => {
  const token = import.meta.env.VITE_MAPBOX_TOKEN
  if (!token || !el.value) return
  mapboxgl.accessToken = token
  ok.value = true

  map = new mapboxgl.Map({
    container: el.value,
    style: 'mapbox://styles/mapbox/light-v11',
    center: [props.lng, props.lat],
    zoom: 15.4,
    pitch: 55,
    bearing: -18,
    attributionControl: false,
    cooperativeGestures: true, // no secuestra el scroll de la página
  })

  map.addControl(new mapboxgl.NavigationControl({ showCompass: false }), 'top-right')

  // marcador rosa con pulso
  const pin = document.createElement('div')
  pin.className = 'salonpin'
  pin.innerHTML = '<span class="salonpin__pulse"></span><span class="salonpin__dot"></span>'
  new mapboxgl.Marker({ element: pin, anchor: 'center' })
    .setLngLat([props.lng, props.lat])
    .addTo(map)

  map.on('load', () => {
    // edificios 3D
    map.addLayer({
      id: 'salon-3d',
      source: 'composite',
      'source-layer': 'building',
      filter: ['==', 'extrude', 'true'],
      type: 'fill-extrusion',
      minzoom: 14,
      paint: {
        'fill-extrusion-color': '#e7d3d6',
        'fill-extrusion-height': ['get', 'height'],
        'fill-extrusion-base': ['get', 'min_height'],
        'fill-extrusion-opacity': 0.7,
      },
    })
    // entrada suave
    map.flyTo({ center: [props.lng, props.lat], zoom: 16, pitch: 58, duration: 2200, essential: true })
  })
})

onBeforeUnmount(() => {
  if (map) map.remove()
})
</script>

<template>
  <div class="map">
    <div ref="el" class="map__canvas"></div>

    <!-- fallback si no hay token -->
    <div v-if="!ok" class="map__fallback">Configura VITE_MAPBOX_TOKEN para ver el mapa.</div>

    <!-- tarjeta glass -->
    <div class="map__card">
      <div class="map__title">Visítanos</div>
      <div class="map__addr">{{ address }}</div>
      <a class="map__btn" :href="directionsUrl" target="_blank" rel="noopener">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 11l19-9-9 19-2-8-8-2z"/></svg>
        <span>Cómo llegar</span>
      </a>
    </div>
  </div>
</template>

<style scoped>
.map {
  position: relative;
  height: 320px;
  border-radius: 0;
  overflow: hidden;
  border: 1px solid rgba(26, 23, 20, 0.1);
}
@media (min-width: 768px) {
  .map {
    border-radius: 20px;
  }
}
.map__canvas {
  position: absolute;
  inset: 0;
}
.map__fallback {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  text-align: center;
  font-size: 13px;
  color: var(--muted);
  background: linear-gradient(135deg, #f1e2e4, #e7d3d6);
}
.map__card {
  position: absolute;
  left: 16px;
  bottom: 16px;
  right: 16px;
  max-width: 260px;
  padding: 16px;
  border-radius: 16px;
  background: rgba(251, 246, 244, 0.82);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  border: 1px solid rgba(26, 23, 20, 0.08);
  box-shadow: 0 10px 30px rgba(20, 12, 4, 0.15);
}
.map__title {
  font-family: var(--serif);
  font-size: 18px;
  font-weight: 500;
  color: var(--ink);
}
.map__addr {
  margin-top: 4px;
  font-size: 12.5px;
  color: var(--muted-2);
  line-height: 1.4;
}
.map__btn {
  margin-top: 12px;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 9px 16px;
  border-radius: 12px;
  background: var(--rose);
  color: #fbf6f4;
  text-decoration: none;
  font-size: 13px;
  font-weight: 500;
}

/* marcador (global porque mapbox lo monta fuera del scope) */
:global(.salonpin) {
  position: relative;
  width: 20px;
  height: 20px;
}
:global(.salonpin__dot) {
  position: absolute;
  inset: 0;
  margin: auto;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: #b0455f;
  border: 3px solid #fbf6f4;
  box-shadow: 0 2px 8px rgba(176, 69, 95, 0.5);
}
:global(.salonpin__pulse) {
  position: absolute;
  inset: 0;
  margin: auto;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: rgba(176, 69, 95, 0.45);
  animation: salonpulse 1.8s ease-out infinite;
}
@keyframes salonpulse {
  0% { transform: scale(1); opacity: 0.7; }
  100% { transform: scale(3.4); opacity: 0; }
}
</style>
