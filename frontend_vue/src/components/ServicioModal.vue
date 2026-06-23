<script setup>
import { onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'

const props = defineProps({
  modelValue: Boolean,
  servicio: Object, // { id, nombre, precio, dur, img, desc? }
})
const emit = defineEmits(['update:modelValue'])

function close() { emit('update:modelValue', false) }

const router = useRouter()
function reservar() {
  close()
  router.push('/reservar')
}

function onKey(e) {
  if (props.modelValue && e.key === 'Escape') close()
}
onMounted(() => window.addEventListener('keydown', onKey))
onUnmounted(() => window.removeEventListener('keydown', onKey))
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="modelValue && servicio" class="overlay" @click.self="close">
        <Transition name="sheet">
          <div v-if="modelValue" class="sheet" role="dialog" aria-modal="true">
            <div class="handle"></div>
            <button class="close" @click="close" aria-label="Cerrar">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
            </button>
            <img class="sheet__img" :src="servicio.img" :alt="servicio.nombre" />
            <div class="sheet__body">
              <div class="sheet__meta">
                <span class="sheet__price">{{ servicio.precio }}</span>
                <span class="sep">·</span>
                <span class="sheet__dur">{{ servicio.dur }}</span>
              </div>
              <h2 class="sheet__name">{{ servicio.nombre }}</h2>
              <p class="sheet__desc">
                {{ servicio.desc || 'Tratamiento profesional con productos de primera calidad, adaptado a tu tipo de cabello y estilo personal.' }}
              </p>
              <div class="sheet__perks">
                <span class="perk-tag">Productos premium</span>
                <span class="perk-tag">Reserva en línea</span>
                <span class="perk-tag">Confirmación inmediata</span>
              </div>
              <button class="sheet__cta" @click="reservar">Reservar este servicio</button>
              <div class="sheet__note">Solo pagas el anticipo (30%) al reservar</div>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  z-index: 200;
  background: rgba(20, 14, 10, 0.55);
  display: flex;
  align-items: flex-end;
}

.sheet {
  position: relative;
  width: 100%;
  max-height: 88vh;
  overflow-y: auto;
  background: #fff;
  border-radius: 24px 24px 0 0;
}

.handle {
  width: 36px;
  height: 4px;
  border-radius: 2px;
  background: rgba(26, 23, 20, 0.18);
  margin: 12px auto 0;
}

.close {
  position: absolute;
  top: 12px;
  right: 16px;
  display: none; /* mobile: handle es suficiente */
  width: 34px;
  height: 34px;
  border-radius: 50%;
  border: 1px solid var(--hairline);
  background: #fff;
  cursor: pointer;
  align-items: center;
  justify-content: center;
  color: var(--ink);
}

.sheet__img {
  display: block;
  width: 100%;
  height: 230px;
  object-fit: cover;
  margin-top: 12px;
}

.sheet__body {
  padding: 20px 24px 32px;
}

.sheet__meta {
  display: flex;
  align-items: center;
  gap: 8px;
}
.sheet__price {
  font-size: 15px;
  font-weight: 700;
  color: var(--rose);
}
.sep {
  font-size: 13px;
  color: var(--muted-3);
}
.sheet__dur {
  font-size: 13px;
  color: var(--muted);
}

.sheet__name {
  margin: 6px 0 0;
  font-family: var(--serif);
  font-size: 24px;
  font-weight: 500;
  color: var(--ink);
  letter-spacing: -0.01em;
}

.sheet__desc {
  margin: 12px 0 0;
  font-size: 14px;
  line-height: 1.65;
  color: var(--muted-2);
}

.sheet__perks {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 16px;
}
.perk-tag {
  font-size: 12px;
  padding: 5px 12px;
  border-radius: 20px;
  background: #fbeef1;
  color: var(--rose);
  font-weight: 500;
}

.sheet__cta {
  display: block;
  width: 100%;
  margin-top: 24px;
  height: 52px;
  border-radius: 14px;
  border: none;
  background: var(--rose);
  color: #fbf6f4;
  font-family: var(--serif);
  font-size: 18px;
  font-weight: 500;
  cursor: pointer;
  transition: filter 0.2s;
}
.sheet__cta:hover { filter: brightness(1.07); }

.sheet__note {
  margin-top: 10px;
  text-align: center;
  font-size: 12px;
  color: var(--muted);
}

/* transitions */
.fade-enter-active, .fade-leave-active { transition: opacity 0.25s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

.sheet-enter-active, .sheet-leave-active { transition: transform 0.3s ease, opacity 0.3s ease; }
.sheet-enter-from, .sheet-leave-to { transform: translateY(100%); opacity: 0.6; }

/* ===== DESKTOP ===== */
@media (min-width: 1100px) {
  .overlay {
    align-items: center;
    justify-content: center;
  }

  .sheet {
    width: 700px;
    max-height: 85vh;
    border-radius: 22px;
    display: grid;
    grid-template-columns: 280px 1fr;
    grid-template-rows: auto 1fr;
    overflow: hidden;
  }

  .handle { display: none; }

  .close {
    display: flex;
    z-index: 2;
  }

  .sheet__img {
    grid-column: 1;
    grid-row: 1 / 3;
    width: 280px;
    height: 100%;
    min-height: 380px;
    margin-top: 0;
    object-fit: cover;
  }

  .sheet__body {
    grid-column: 2;
    grid-row: 1 / 3;
    padding: 32px 28px 32px;
    overflow-y: auto;
  }

  .sheet__name { font-size: 28px; }
  .sheet__desc { font-size: 15px; }

  /* desktop: slide from bottom replaced by scale-fade */
  .sheet-enter-from,
  .sheet-leave-to {
    transform: scale(0.96);
    opacity: 0;
  }
}
</style>
