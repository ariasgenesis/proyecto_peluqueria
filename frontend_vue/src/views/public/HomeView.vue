<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { RouterLink } from 'vue-router'

import SalonMap from '@/components/SalonMap.vue'
import ServicioModal from '@/components/ServicioModal.vue'
import EstilistaModal from '@/components/EstilistaModal.vue'
import SalonGalleryModal from '@/components/SalonGalleryModal.vue'
import { useUiStore } from '@/stores/ui'

const ui = useUiStore()

// Carga: skeletons shimmer -> contenido (hook a /publico/servicios luego).
const loading = ref(true)
const skeletons = [0, 1, 2]

const servicios = [
  { id: 1, nombre: 'Color & corte', precio: '$250.000', dur: '1h 45m', img: '/img/s1.webp', desc: 'Transformación completa: coloración personalizada con técnica de balayage o tinte plano, más corte y brushing. Incluye tratamiento de brillo y keratina ligera.' },
  { id: 2, nombre: 'Brushing & peinado', precio: '$45.000', dur: '45m', img: '/img/s2.webp', desc: 'Peinado profesional con brushing y volumen. Ideal para el día a día o para una ocasión especial. Incluye masaje capilar reconfortante.' },
  { id: 3, nombre: 'Manicura premium', precio: '$55.000', dur: '50m', img: '/img/s3.webp', desc: 'Manicura completa con esmaltado semipermanente de larga duración. Incluye limado, cutículas, exfoliación de manos y base nutritiva.' },
  { id: 4, nombre: 'Facial luminoso', precio: '$90.000', dur: '1h', img: '/img/s4.webp', desc: 'Tratamiento facial con limpieza profunda, exfoliación enzimática y mascarilla hidratante de vitamina C. Tu piel, radiante en una hora.' },
  { id: 5, nombre: 'Uñas acrílicas', precio: '$80.000', dur: '2h', img: '/img/741a3d2bff42456470ed060de3a9cd89.jpg', desc: 'Uñas acrílicas de alta durabilidad con diseño personalizado. El servicio incluye moldeado, capa base, color y acabado tipo gel brillante.' },
]
const estilistas = [
  { id: 1, nombre: 'Camila R.', esp: 'Color & balayage', img: '/img/a1.webp', reviews: 87, bio: 'Especialista en técnicas de color avanzadas y balayage natural. Más de 6 años transformando looks con precisión y amor por el detalle. Formada en la Escuela de Colorimetría de Santiago.' },
  { id: 2, nombre: 'Valentina M.', esp: 'Cortes & styling', img: '/img/a2.webp', reviews: 64, bio: 'Experta en cortes de autor y peinados para eventos. Estudió en Buenos Aires y trae una visión fresca del styling moderno, con técnica francesa y sensibilidad latina.' },
  { id: 3, nombre: 'Sofía L.', esp: 'Uñas & nail art', img: '/img/a3.webp', reviews: 112, bio: 'Artista del nail art con diseños únicos e irrepetibles. Sus manos crean pequeñas obras de arte que duran semanas. Certificada en acrílico, gel y semipermanente.' },
]

// Modales
const showSvc = ref(false)
const selectedSvc = ref(null)
function openSvc(s) { selectedSvc.value = s; showSvc.value = true }

const showEstilista = ref(false)
const selectedEstilista = ref(null)
function openEstilista(e) { selectedEstilista.value = e; showEstilista.value = true }

const showGallery = ref(false)
const heroSlides = [
  { img: '/img/salon/1.webp', ph: 'Beutycore' },
  { img: '/img/salon/2.webp', ph: 'Beutycore' },
  { img: '/img/salon/3.webp', ph: 'Beutycore' },
  { img: '/img/salon/4.webp', ph: 'Beutycore' },
  { img: '/img/salon/5.webp', ph: 'Beutycore' },
  { img: '/img/salon/6.webp', ph: 'Beutycore' },
]

// Carruseles con botones (desktop)
const svcRow = ref(null)
const peopleRow = ref(null)
function nudge(el, dir) {
  el?.scrollBy({ left: dir * 340, behavior: 'smooth' })
}

// Carrusel hero: índice activo según scroll
const heroIdx = ref(0)
function onHeroScroll(e) {
  const el = e.target
  heroIdx.value = Math.round(el.scrollLeft / el.clientWidth)
}

// Navbar oculta-al-scroll
const navHidden = ref(false)
let lastY = 0
function onScroll() {
  const y = window.scrollY
  navHidden.value = y > lastY && y > 64
  lastY = y
}

onMounted(() => {
  setTimeout(() => {
    loading.value = false
  }, 650)
  window.addEventListener('scroll', onScroll, { passive: true })
})
onUnmounted(() => window.removeEventListener('scroll', onScroll))
</script>

<template>
  <div class="home">
    <!-- navbar (oculta al scroll) -->
    <div class="nav" :class="{ 'nav--hidden': navHidden }">
      <div class="nav__brand">Beutycore</div>
      <nav class="nav__links">
        <RouterLink to="/servicios">Servicios</RouterLink>
        <RouterLink to="/reservar">Reservar</RouterLink>
        <a href="#visitanos">Visítanos</a>
      </nav>
      <button class="nav__login" @click="ui.openLogin()">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4M10 17l5-5-5-5M15 12H3"/></svg>
        <span>Ingresar</span>
      </button>
    </div>

    <!-- ===================== CONTENIDO ===================== -->
    <template v-if="!loading">
      <!-- DESKTOP: título + acciones -->
      <div class="dhead">
        <h1 class="dhead__title">Beutycore · Providencia</h1>
        <div class="dhead__sub">
          <span class="dhead__star">★ 5,0</span>
          <span class="dhead__dot">·</span>
          <span class="dhead__rev">128 reseñas</span>
          <span class="dhead__dot">·</span>
          <span class="dhead__loc">Av. Providencia 1234, Santiago</span>
        </div>
      </div>

      <!-- DESKTOP: galería estilo airbnb -->
      <div class="gallery">
        <div class="gallery__big"><img src="/img/salon/1.webp" alt="" /></div>
        <div class="gallery__cell"><img src="/img/salon/2.webp" alt="" /></div>
        <div class="gallery__cell"><img src="/img/salon/3.webp" alt="" /></div>
        <div class="gallery__cell"><img src="/img/salon/4.webp" alt="" /></div>
        <div class="gallery__cell">
          <img src="/img/salon/5.webp" alt="" />
          <button class="gallery__all" @click="showGallery = true">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#1A1714" stroke-width="1.8"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>
            Mostrar todas las fotos
          </button>
        </div>
      </div>

      <!-- MOBILE: hero carrusel -->
      <div class="hero">
        <div class="scrl hero__track" @scroll="onHeroScroll">
          <div v-for="(s, i) in heroSlides" :key="i" class="hero__slide">
            <img v-if="s.img" class="hero__img" :src="s.img" alt="" />
            <div v-else class="hero__img ph">{{ s.ph }}</div>
          </div>
        </div>
        <div class="hero__dots">
          <span v-for="(s, i) in heroSlides" :key="i" class="dot" :class="{ 'dot--on': i === heroIdx }"></span>
        </div>
      </div>

      <!-- dos columnas (desktop) -->
      <div class="stage">
        <div class="main">
      <!-- título -->
      <h2 class="main__title">Belleza con alma, hecha ritual</h2>

      <!-- intro -->
      <div class="intro">
        <span class="intro__lead">Un espacio íntimo en el corazón de Providencia</span>
        donde el cuidado se vuelve ritual. Color, cortes y manos expertas que leen tu
        estilo y lo elevan, sin prisa y con la calidez de siempre.
      </div>

      <!-- beneficios -->
      <ul class="perks">
        <li class="perk">
          <span class="perk__ico">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/></svg>
          </span>
          <div>
            <div class="perk__t">Anticipo seguro</div>
            <div class="perk__d">Pago protegido con Wompi.</div>
          </div>
        </li>
        <li class="perk">
          <span class="perk__ico">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2l2.4 6.9H22l-6 4.4 2.3 7-6.3-4.6L5.7 20l2.3-7-6-4.4h7.6z"/></svg>
          </span>
          <div>
            <div class="perk__t">Estilistas top</div>
            <div class="perk__d">Manos expertas, <span class="star">5,0 ★</span></div>
          </div>
        </li>
        <li class="perk">
          <span class="perk__ico">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>
          </span>
          <div>
            <div class="perk__t">Confirmación inmediata</div>
            <div class="perk__d">Tu cupo, al instante.</div>
          </div>
        </li>
        <li class="perk">
          <span class="perk__ico">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5L18 18M18 6l-2.5 2.5M8.5 15.5L6 18"/></svg>
          </span>
          <div>
            <div class="perk__t">Productos premium</div>
            <div class="perk__d">Marcas profesionales.</div>
          </div>
        </li>
      </ul>
        </div><!-- /main -->

        <!-- tarjeta reserva (sticky, desktop) -->
        <aside class="booking">
          <div class="booking__card">
            <div class="booking__price">
              Desde <strong>$45.000</strong> <span>COP / servicio</span>
            </div>
            <div class="booking__rate"><span class="star">★ 5,0</span> · 128 reseñas</div>

            <div class="booking__box">
              <div class="booking__field">
                <span class="booking__lbl">Servicio</span>
                <span class="booking__val">Elige en la reserva</span>
              </div>
              <div class="booking__field">
                <span class="booking__lbl">Fecha y hora</span>
                <span class="booking__val">Disponibilidad en vivo</span>
              </div>
            </div>

            <RouterLink to="/reservar" class="booking__btn">Reservar cita</RouterLink>
            <div class="booking__note">Solo pagas el anticipo · confirmación inmediata</div>

            <div class="booking__row">
              <span>Anticipo (30%)</span><span>desde $13.500 COP</span>
            </div>
            <div class="booking__row booking__row--muted">
              <span>Saldo en Beutycore</span><span>al asistir</span>
            </div>
          </div>
        </aside>
      </div><!-- /stage -->

      <!-- servicios -->
      <section class="sec sec--svc">
        <div class="sec__head">
          <h2 class="sec__title">Servicios destacados</h2>
          <RouterLink to="/servicios" class="sec__link">Ver todo</RouterLink>
        </div>
        <div class="rowwrap">
          <button class="rownav rownav--prev" aria-label="Anterior" @click="nudge(svcRow, -1)">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1A1714" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg>
          </button>
          <div ref="svcRow" class="scrl row">
            <article v-for="s in servicios" :key="s.id" class="svc" @click="openSvc(s)">
              <img class="svc__img" :src="s.img" :alt="s.nombre" />
              <div class="svc__name">{{ s.nombre }}</div>
              <div class="svc__meta">
                <span class="svc__price">{{ s.precio }}</span>
                <span class="dotsep">·</span>
                <span class="svc__dur">{{ s.dur }}</span>
              </div>
            </article>
          </div>
          <button class="rownav rownav--next" aria-label="Siguiente" @click="nudge(svcRow, 1)">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1A1714" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg>
          </button>
        </div>
      </section>

      <!-- estilistas -->
      <section class="sec">
        <h2 class="sec__title sec__title--pad">Nuestras estilistas</h2>
        <div class="rowwrap">
          <button class="rownav rownav--prev" aria-label="Anterior" @click="nudge(peopleRow, -1)">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1A1714" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg>
          </button>
          <div ref="peopleRow" class="scrl row row--people">
            <div v-for="e in estilistas" :key="e.id" class="person" @click="openEstilista(e)">
              <img class="person__img" :src="e.img" :alt="e.nombre" />
              <div class="person__name">{{ e.nombre }}</div>
              <div class="person__esp">{{ e.esp }}</div>
            </div>
          </div>
          <button class="rownav rownav--next" aria-label="Siguiente" @click="nudge(peopleRow, 1)">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1A1714" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg>
          </button>
        </div>
      </section>

      <!-- cómo funciona -->
      <section class="sec how">
        <h2 class="sec__title">Cómo funciona</h2>

        <div class="how__row how__row--border">
          <svg class="how__ico" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M20 4 8.12 15.88M14.8 14.8 20 20M8.12 8.12 12 12"/></svg>
          <div>
            <div class="how__t">Elige tu servicio</div>
            <div class="how__d">Explora el catálogo y selecciona lo que tu estilo necesita.</div>
          </div>
        </div>

        <div class="how__row how__row--border">
          <svg class="how__ico" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18M7 15h3"/></svg>
          <div>
            <div class="how__t">Paga el anticipo</div>
            <div class="how__d">Asegura tu cupo con un pequeño anticipo, sin filas.</div>
          </div>
        </div>

        <div class="how__row">
          <svg class="how__ico" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#B0455F" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 9h18M8 3v4M16 3v4M12 13v3l2 1"/></svg>
          <div>
            <div class="how__t">Llega a tu cita</div>
            <div class="how__d">Te esperamos a la hora elegida. Lo demás, lo ponemos nosotras.</div>
          </div>
        </div>
      </section>

      <!-- mapa -->
      <section id="visitanos" class="sec sec--map">
        <div class="map-wrap">
          <SalonMap />
        </div>
      </section>

      <!-- footer -->
      <footer class="foot">
        <div class="foot__brand">Beutycore</div>
        <div class="foot__lines">
          Av. Providencia 1234, Santiago<br />
          Lun–Sáb · 10:00–20:00<br />
          hola@beutycore.cl · +56 9 4421 8890
          <br />
          Hecho con ❤️ por Genesis Arias
        </div>
      </footer>
    </template>

    <!-- ===================== SKELETONS ===================== -->
    <template v-else>
      <!-- MOBILE: hero + cta -->
      <div class="hero hero--sk shimmer sk-mobile"></div>
      <div class="skcta sk-mobile">
        <div class="shimmer skcta__btn"></div>
        <div class="shimmer skcta__line"></div>
      </div>

      <!-- DESKTOP: dhead -->
      <div class="sk-dhead sk-desktop">
        <div class="shimmer sk" style="width: 320px; height: 32px"></div>
        <div style="display:flex;gap:10px;margin-top:10px">
          <div class="shimmer sk" style="width: 60px; height: 14px"></div>
          <div class="shimmer sk" style="width: 80px; height: 14px"></div>
          <div class="shimmer sk" style="width: 180px; height: 14px"></div>
        </div>
      </div>

      <!-- DESKTOP: galería grid -->
      <div class="sk-gallery sk-desktop">
        <div class="shimmer sk sk-gallery__big"></div>
        <div class="shimmer sk sk-gallery__cell"></div>
        <div class="shimmer sk sk-gallery__cell"></div>
        <div class="shimmer sk sk-gallery__cell"></div>
        <div class="shimmer sk sk-gallery__cell"></div>
      </div>

      <!-- DESKTOP: stage (intro + booking) -->
      <div class="sk-stage sk-desktop">
        <div class="sk-stage__main">
          <div class="shimmer sk" style="width:55%;height:28px;margin-bottom:14px"></div>
          <div class="shimmer sk" style="width:100%;height:14px;margin-bottom:8px"></div>
          <div class="shimmer sk" style="width:88%;height:14px;margin-bottom:8px"></div>
          <div class="shimmer sk" style="width:74%;height:14px;margin-bottom:28px"></div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px">
            <div v-for="k in 4" :key="k" class="sk-perk">
              <div class="shimmer sk" style="width:40px;height:40px;border-radius:12px;flex:none"></div>
              <div style="flex:1">
                <div class="shimmer sk" style="width:70%;height:13px;margin-bottom:6px"></div>
                <div class="shimmer sk" style="width:90%;height:11px"></div>
              </div>
            </div>
          </div>
        </div>
        <div class="sk-stage__card shimmer sk"></div>
      </div>

      <!-- Servicios (ambas resoluciones) -->
      <section class="sec sec--svc">
        <div class="sec__head">
          <div class="shimmer sk" style="width:170px;height:20px"></div>
          <div class="shimmer sk" style="width:46px;height:12px"></div>
        </div>
        <div class="row sk-row">
          <div v-for="k in skeletons" :key="k" class="svc">
            <div class="shimmer sk svc__img"></div>
            <div class="shimmer sk" style="width:80%;height:15px;margin-top:13px"></div>
            <div class="shimmer sk" style="width:55%;height:12px;margin-top:8px"></div>
          </div>
        </div>
      </section>

      <!-- Estilistas (ambas resoluciones) -->
      <section class="sec">
        <div class="shimmer sk" style="width:160px;height:20px;margin:0 24px 16px"></div>
        <div class="row row--people sk-row">
          <div v-for="k in skeletons" :key="k" class="person">
            <div class="shimmer sk person__img"></div>
            <div class="shimmer sk" style="width:64%;height:12px;margin:11px auto 0"></div>
            <div class="shimmer sk" style="width:48%;height:10px;margin:7px auto 0"></div>
          </div>
        </div>
      </section>
    </template>

    <!-- ===================== MODALES ===================== -->
    <ServicioModal v-model="showSvc" :servicio="selectedSvc" />
    <EstilistaModal v-model="showEstilista" :estilista="selectedEstilista" />
    <SalonGalleryModal v-model="showGallery" :slides="heroSlides" />

    <!-- ===================== CTA FIJA ===================== -->
    <div class="ctabar">
      <RouterLink to="/reservar" class="ctabar__btn">
        <span>Reservar cita</span>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h13M13 6l6 6-6 6"/></svg>
      </RouterLink>
      <div class="ctabar__note">Paga solo el anticipo · confirmación inmediata</div>
    </div>
  </div>
</template>

<style scoped>
.home {
  padding-bottom: 110px;
}

/* navbar oculta-al-scroll */
.nav {
  position: fixed;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  z-index: 40;
  width: 100%;
  max-width: 480px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  background: rgba(251, 246, 244, 0.82);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-bottom: 1px solid rgba(26, 23, 20, 0.06);
  transition: transform 0.35s ease, opacity 0.35s ease;
}
.nav--hidden {
  transform: translateX(-50%) translateY(-100%);
  opacity: 0;
}
.nav__brand {
  font-family: var(--serif);
  font-size: 22px;
  font-weight: 500;
  letter-spacing: -0.01em;
  color: var(--ink);
}
.nav__login {
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 8px 16px;
  border-radius: 20px;
  border: 1px solid rgba(122, 58, 79, 0.3);
  background: rgba(176, 69, 95, 0.06);
  text-decoration: none;
  cursor: pointer;
  font-family: var(--sans);
}
.nav__login span {
  font-size: 13px;
  font-weight: 500;
  color: var(--rose);
}

/* hero carrusel */
.hero {
  position: relative;
  height: 280px;
      margin: 60px 0 0 0;
}
.hero__track {
  display: flex;
  overflow-x: auto;
  height: 100%;
  scroll-snap-type: x mandatory;
}
.hero__slide {
  flex: none;
  width: 100%;
  height: 100%;
  scroll-snap-align: center;
}
.hero__img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.hero__dots {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 14px;
  display: flex;
  justify-content: center;
  gap: 7px;
  pointer-events: none;
}
.dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: rgba(251, 249, 246, 0.5);
  box-shadow: 0 1px 3px rgba(20, 12, 4, 0.3);
}
.dot--on {
  background: #fbf9f6;
}

/* intro */
.main__title {
  margin: 0;
  padding: 26px 24px 0;
  font-family: var(--serif);
  font-size: 22px;
  font-weight: 500;
  letter-spacing: -0.01em;
  color: var(--ink);
}
.intro {
  padding: 14px 24px 0;
  font-size: 13.5px;
  line-height: 1.6;
  color: var(--muted-2);
  letter-spacing: 0.002em;
}
.intro__lead {
  color: var(--rose);
  font-weight: 500;
}
.star {
  color: #ffcb4d;
  font-weight: 600;
}

/* beneficios */
.perks {
  list-style: none;
  margin: 18px 0 0;
  padding: 0 24px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px 14px;
}
.perk {
  display: flex;
  align-items: flex-start;
  gap: 11px;
}
.perk__ico {
  flex: none;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  background: #fbeef1;
}
.perk__t {
  font-size: 14px;
  font-weight: 600;
  color: var(--ink);
}
.perk__d {
  font-size: 12px;
  color: var(--muted);
  margin-top: 1px;
  line-height: 1.35;
}

/* secciones */
.sec {
  margin-top: 30px;
}
.sec--svc {
  margin-top: 24px;
}
.sec__head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  padding: 0 24px 14px;
}
.sec__title {
  margin: 0;
  font-family: var(--serif);
  font-size: 21px;
  font-weight: 500;
  color: var(--ink);
}
.sec__title--pad {
  padding: 0 24px 14px;
}
.sec__link {
  font-size: 12px;
  font-weight: 500;
  color: var(--rose);
  text-decoration: none;
}

/* carruseles */
.row {
  display: flex;
  gap: 14px;
  overflow-x: auto;
  padding-bottom: 4px;
  scroll-snap-type: x mandatory;
  scroll-padding-left: 24px;
}
/* gutters fiables en scroll flex: márgenes en extremos */
.row > :first-child {
  margin-left: 24px;
}
.row > :last-child {
  margin-right: 24px;
}
.row--people {
  gap: 20px;
}
/* botones de carrusel: solo desktop */
.rowwrap {
  position: relative;
}
.rownav {
  display: none;
}

/* servicio */
.svc {
  flex: none;
  width: 158px;
  scroll-snap-align: start;
  cursor: pointer;
}
.svc__img {
  width: 158px;
  height: 158px;
  border-radius: 14px;
  object-fit: cover;
  display: block;
}
.svc__name {
  font-family: var(--serif);
  font-size: 16px;
  color: var(--ink);
  margin-top: 11px;
}
.svc__meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
}
.svc__price {
  font-size: 14px;
  font-weight: 600;
  color: var(--rose);
}
.dotsep {
  font-size: 12px;
  color: var(--muted-3);
}
.svc__dur {
  font-size: 12px;
  color: var(--muted);
}

/* persona */
.person {
  flex: none;
  width: 80px;
  text-align: center;
  cursor: pointer;
}
.person__img {
  width: 76px;
  height: 76px;
  margin: 0 auto;
  border-radius: 50%;
  object-fit: cover;
  display: block;
}
.person__name {
  font-family: var(--serif);
  font-size: 13px;
  font-weight: 500;
  color: var(--ink);
  margin-top: 9px;
}
.person__esp {
  font-size: 11px;
  color: var(--muted);
  margin-top: 2px;
  line-height: 1.3;
}

/* placeholder de imagen */
.ph {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  color: #b89aa0;
  background: linear-gradient(135deg, #f1e2e4, #e7d3d6);
}

/* cómo funciona */
.how {
  padding: 0 24px;
}
.how .sec__title {
  margin-bottom: 20px;
}
.how__row {
  display: flex;
  gap: 16px;
  align-items: flex-start;
  padding: 20px 0;
}

.how__row--border {
  border-bottom: 1px solid var(--hairline);
}
.how__num {
  font-family: var(--serif);
  font-size: 30px;
  font-weight: 500;
  color: var(--rose-soft);
  line-height: 1;
  width: 34px;
  flex: none;
}
.how__ico {
  flex: none;
  margin-top: 2px;
}
.how__t {
  font-family: var(--serif);
  font-size: 16px;
  font-weight: 500;
  color: var(--ink);
}
.how__d {
  font-size: 13px;
  color: var(--muted);
  line-height: 1.45;
  margin-top: 3px;
}

/* footer */
.foot {
  margin-top: 12px;
  padding: 26px 24px 40px;
  background: var(--bg-footer);
  border-top: 1px solid rgba(26, 23, 20, 0.06);
}
.foot__brand {
  font-family: var(--serif);
  font-size: 20px;
  font-weight: 500;
  color: var(--ink);
}
.foot__lines {
  margin-top: 12px;
  font-size: 13px;
  color: var(--muted-2);
  line-height: 1.7;
}

/* skeleton helpers */
.hero--sk {
  height: 372px;
}
.sk {
  border-radius: 6px;
}
.skcta {
  padding: 22px 24px 8px;
}
.skcta__btn {
  width: 100%;
  height: 60px;
  border-radius: 16px;
}
.skcta__line {
  width: 64%;
  height: 12px;
  border-radius: 6px;
  margin: 15px auto 0;
}
/* visibilidad por breakpoint */
.sk-desktop { display: none; }
.sk-mobile  { display: block; }
/* evita scroll horizontal en filas skeleton */
.sk-row { overflow: hidden; }

/* cta fija */
.ctabar {
  position: fixed;
  z-index: 28;
  left: 50%;
  bottom: 0;
  transform: translateX(-50%);
  width: 100%;
  max-width: 480px;
  padding: 14px 24px 18px;
  background: rgba(251, 246, 244, 0.94);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-top: 1px solid var(--hairline);
}
.ctabar__btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  width: 100%;
  height: 56px;
  border-radius: 16px;
  background: var(--rose);
  color: #fbf6f4;
  text-decoration: none;
}
.ctabar__btn span {
  font-family: var(--serif);
  font-size: 19px;
  font-weight: 500;
  letter-spacing: 0.01em;
}
.ctabar__note {
  margin-top: 9px;
  text-align: center;
  font-size: 12px;
  color: var(--muted);
}

/* mapa */
.sec--map {
  margin-top: 30px;
}
.map-wrap {
  padding: 0;
}

/* ===================== TABLET (>=768) ===================== */
@media (min-width: 768px) {
  .home {
    padding-bottom: 120px;
  }
  .nav,
  .ctabar {
    max-width: 720px;
  }
  .hero {
    height: 420px;
  }
  .intro {
    padding: 34px 32px 0;
    font-size: 15px;
    max-width: 640px;
    margin: 0 auto;
    text-align: center;
  }
  .sec,
  .sec--svc,
  .sec--map {
    margin-top: 44px;
  }
  .sec__head,
  .sec__title--pad {
    padding-left: 32px;
    padding-right: 32px;
  }
  .how {
    padding: 0 32px;
  }
  .map-wrap {
    padding: 0 32px;
  }
  /* carruseles: scroll horizontal (sin wrap) */
  .row {
    flex-wrap: nowrap;
    justify-content: flex-start;
    overflow-x: auto;
    gap: 20px;
    padding: 0 32px;
  }
  .row > :first-child,
  .row > :last-child {
    margin: 0;
  }
  .svc {
    width: 200px;
  }
  .svc__img {
    width: 200px;
    height: 200px;
  }
  /* cómo funciona en 3 columnas */
  .how {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 24px;
  }
  .how .sec__title {
    grid-column: 1 / -1;
  }
  .how__row,
  .how__row--border {
    border-bottom: 0;
    padding: 0;
    flex-direction: column;
  }
  .map {
    height: 380px;
  }
}

/* elementos desktop-only (ocultos por defecto) */
.nav__links,
.dhead,
.gallery,
.booking {
  display: none;
}

/* ===================== ESCRITORIO (>=1100) — estilo Airbnb ===================== */
@media (min-width: 1100px) {
  .home {
    padding-bottom: 0;
            margin: 90px 0 0 0;
  }
  .hero,
  .ctabar {
    display: none;
  }

  /* navbar estática con links */
  .nav {
    max-width: none;
    width: 100%;
    padding: 16px 40px;
  }
  .nav--hidden {
    transform: translateX(-50%);
    opacity: 1;
  }
  .nav__links {
    display: flex;
    gap: 28px;
  }
  .nav__links a {
    font-size: 14px;
    color: var(--ink);
    text-decoration: none;
    transition: color 0.2s ease;
  }
  .nav__links a:hover {
    color: var(--rose);
  }

  /* título + subtítulo */
  .dhead {
    display: block;
    max-width: 1200px;
    margin: 14px auto 0;
    padding: 0 40px;
  }
  .dhead__title {
    margin: 0;
    font-family: var(--serif);
    font-size: 30px;
    font-weight: 500;
    letter-spacing: -0.01em;
    color: var(--ink);
  }
  .dhead__sub {
    margin-top: 8px;
    font-size: 14px;
    color: var(--muted-2);
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .dhead__star {
    color: #ffcb4d;
    font-weight: 600;
  }
  .dhead__dot {
    color: var(--muted-3);
  }

  /* galería grid */
  .gallery {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    grid-template-rows: repeat(2, 210px);
    gap: 8px;
    max-width: 1200px;
    margin: 18px auto 0;
    padding: 0 40px;
  }
  .gallery img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }
  .gallery__big {
    grid-column: 1 / 3;
    grid-row: 1 / 3;
    overflow: hidden;
    border-radius: 20px 0 0 20px;
  }
  .gallery__cell {
    position: relative;
    overflow: hidden;
  }
  .gallery__cell:nth-child(3) {
    border-top-right-radius: 20px;
  }
  .gallery__cell:nth-child(5) {
    border-bottom-right-radius: 20px;
  }
  .gallery__cell img {
    transition: transform 0.4s ease;
  }
  .gallery__cell:hover img {
    transform: scale(1.05);
  }
  .gallery__all {
    position: absolute;
    right: 14px;
    bottom: 14px;
    display: inline-flex;
    align-items: center;
    gap: 7px;
    padding: 8px 14px;
    border-radius: 10px;
    background: rgba(251, 246, 244, 0.95);
    border: 1px solid rgba(26, 23, 20, 0.25);
    font-size: 13px;
    font-weight: 500;
    color: var(--ink);
    cursor: pointer;
  }

  /* dos columnas */
  .stage {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 360px;
    gap: 64px;
    max-width: 1200px;
    margin: 48px auto 0;
    padding: 0 40px;
    align-items: start;
  }
  .main {
    min-width: 0;
  }

  /* intro: dentro de .main, junto a la tarjeta */
  .main__title {
    padding: 0;
    font-size: 28px;
  }
  .main .intro {
    max-width: none;
    margin: 0;
    padding: 12px 0 0;
    text-align: left;
    font-size: 16px;
  }
  .main .perks {
    padding: 0;
    margin-top: 24px;
  }

  /* secciones full-width (fuera de .main) */
  .sec,
  .sec--svc,
  .sec--map {
    max-width: 1200px;
    margin: 64px auto 0;
    padding: 0 40px;
  }
  .sec__head,
  .sec__title--pad {
    padding-left: 0;
    padding-right: 0;
  }
  .sec__title {
    font-size: 26px;
  }
  .row {
    padding: 0;
    justify-content: flex-start;
    overflow-x: auto;
    max-width: none;
    margin: 0;
    gap: 24px;
  }
  .svc {
    width: 220px;
  }
  .svc__img {
    width: 220px;
    height: 220px;
    transition: transform 0.3s ease;
  }
  .svc:hover .svc__img {
    transform: scale(1.03);
  }

  /* estilistas más grandes */
  .row--people {
    gap: 28px;
  }
  .person {
    width: 130px;
  }
  .person__img {
    width: 130px;
    height: 130px;
  }
  .person__name {
    font-size: 16px;
    margin-top: 12px;
  }
  .person__esp {
    font-size: 13px;
  }

  /* botones de carrusel */
  .rownav {
    display: flex;
    align-items: center;
    justify-content: center;
    position: absolute;
    top: 110px;
    width: 42px;
    height: 42px;
    border-radius: 50%;
    background: #fff;
    border: 1px solid rgba(26, 23, 20, 0.15);
    box-shadow: 0 4px 16px rgba(20, 12, 4, 0.16);
    cursor: pointer;
    z-index: 2;
    transition: background 0.2s ease, transform 0.2s ease;
  }
  .rownav:hover {
    background: #faf3f0;
    transform: scale(1.06);
  }
  .rownav--prev {
    left: -10px;
  }
  .rownav--next {
    right: -10px;
  }
  /* en estilistas (imágenes más bajas) los botones suben */
  .rowwrap:has(.row--people) .rownav {
    top: 65px;
  }

  .how {
    gap: 20px;
  }
  .how__row,
  .how__row--border {
    background: #fff;
    border: 1px solid var(--hairline);
    border-radius: 18px;
    padding: 26px 22px;
    flex-direction: column;
  }
  .how__ico {
    width: 46px;
    height: 46px;
    padding: 11px;
    border-radius: 13px;
    background: #fbeef1;
    margin-top: 0;
  }
  .how__t {
    font-size: 17px;
    margin-top: 13px;
  }
  .map-wrap {
    padding: 0;
  }
  .map {
    height: 440px;
    border-radius: 22px;
  }

  /* tarjeta reserva sticky */
  .booking {
    display: block;
  }
  .booking__card {
    position: sticky;
    top: 90px;
    border: 1px solid rgba(26, 23, 20, 0.12);
    border-radius: 20px;
    padding: 24px;
    background: #fff;
    box-shadow: 0 10px 34px rgba(20, 12, 4, 0.1);
  }
  .booking__price {
    font-size: 15px;
    color: var(--muted-2);
  }
  .booking__price strong {
    font-family: var(--serif);
    font-size: 24px;
    font-weight: 600;
    color: var(--ink);
  }
  .booking__price span {
    font-size: 13px;
  }
  .booking__rate {
    margin-top: 4px;
    font-size: 13px;
    color: var(--muted);
  }
  .booking__box {
    margin-top: 16px;
    border: 1px solid rgba(26, 23, 20, 0.15);
    border-radius: 14px;
    overflow: hidden;
  }
  .booking__field {
    display: flex;
    flex-direction: column;
    gap: 2px;
    padding: 12px 14px;
  }
  .booking__field + .booking__field {
    border-top: 1px solid rgba(26, 23, 20, 0.12);
  }
  .booking__lbl {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    color: var(--muted);
  }
  .booking__val {
    font-size: 14px;
    color: var(--ink);
  }
  .booking__btn {
    display: flex;
    align-items: center;
    justify-content: center;
    margin-top: 16px;
    height: 52px;
    border-radius: 14px;
    background: var(--rose);
    color: #fbf6f4;
    text-decoration: none;
    font-family: var(--serif);
    font-size: 18px;
    font-weight: 500;
    transition: filter 0.2s ease;
  }
  .booking__btn:hover {
    filter: brightness(1.06);
  }
  .booking__note {
    margin-top: 12px;
    text-align: center;
    font-size: 12px;
    color: var(--muted);
  }
  .booking__row {
    display: flex;
    justify-content: space-between;
    margin-top: 16px;
    font-size: 13px;
    color: var(--ink);
  }
  .booking__row--muted {
    margin-top: 8px;
    color: var(--muted);
  }

  /* ---- skeleton desktop ---- */
  .sk-desktop { display: block; }
  .sk-mobile  { display: none !important; }

  .sk-dhead {
    max-width: 1200px;
    margin: 14px auto 0;
    padding: 0 40px;
  }

  .sk-gallery {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    grid-template-rows: repeat(2, 210px);
    gap: 8px;
    max-width: 1200px;
    margin: 18px auto 0;
    padding: 0 40px;
  }
  .sk-gallery__big {
    grid-column: 1 / 3;
    grid-row: 1 / 3;
    border-radius: 20px 0 0 20px;
  }
  .sk-gallery__cell { border-radius: 4px; }
  .sk-gallery__cell:nth-child(2) { border-top-right-radius: 20px; }
  .sk-gallery__cell:last-child   { border-bottom-right-radius: 20px; }

  .sk-stage {
    display: grid;
    grid-template-columns: minmax(0,1fr) 360px;
    gap: 64px;
    max-width: 1200px;
    margin: 48px auto 0;
    padding: 0 40px;
    align-items: start;
  }
  .sk-stage__main { min-width: 0; }
  .sk-perk { display: flex; align-items: flex-start; gap: 11px; }
  .sk-stage__card {
    height: 380px;
    border-radius: 20px;
    position: sticky;
    top: 90px;
  }

  /* footer ancho completo */
  .foot {
    max-width: 1200px;
    margin: 56px auto 0;
    padding: 26px 40px 48px;
    background: transparent;
    border-top: 1px solid var(--hairline);
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
  }
  .foot__lines {
    margin-top: 0;
    text-align: right;
  }
}
</style>
