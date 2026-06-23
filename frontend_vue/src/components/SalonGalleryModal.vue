<script setup>
import { ref, watch, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  modelValue: Boolean,
  slides: Array, // [{ img, ph }]
})
const emit = defineEmits(['update:modelValue'])

function close() { emit('update:modelValue', false) }

const idx = ref(0)
function prev() { idx.value = (idx.value - 1 + props.slides.length) % props.slides.length }
function next() { idx.value = (idx.value + 1) % props.slides.length }
function goTo(i) { idx.value = i }

function onKey(e) {
  if (!props.modelValue) return
  if (e.key === 'Escape') close()
  if (e.key === 'ArrowLeft') prev()
  if (e.key === 'ArrowRight') next()
}
onMounted(() => window.addEventListener('keydown', onKey))
onUnmounted(() => window.removeEventListener('keydown', onKey))
watch(() => props.modelValue, v => { if (v) idx.value = 0 })
</script>

<template>
  <Teleport to="body">
    <Transition name="gfade">
      <div v-if="modelValue && slides?.length" class="gal" role="dialog" aria-modal="true">

        <!-- barra superior -->
        <div class="gal__bar">
          <span class="gal__count">{{ idx + 1 }} / {{ slides.length }}</span>
          <button class="gal__close" @click="close" aria-label="Cerrar">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
          </button>
        </div>

        <!-- imagen principal -->
        <div class="gal__main" @click.self="close">
          <button class="gal__nav gal__nav--prev" @click="prev" aria-label="Anterior">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg>
          </button>

          <Transition name="slide" mode="out-in">
            <img
              :key="idx"
              class="gal__img"
              :src="slides[idx].img"
              :alt="`Foto ${idx + 1}`"
            />
          </Transition>

          <button class="gal__nav gal__nav--next" @click="next" aria-label="Siguiente">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg>
          </button>
        </div>

        <!-- miniaturas -->
        <div class="gal__thumbs">
          <button
            v-for="(s, i) in slides"
            :key="i"
            class="gal__thumb"
            :class="{ 'gal__thumb--on': i === idx }"
            @click="goTo(i)"
          >
            <img :src="s.img" :alt="`Miniatura ${i + 1}`" />
          </button>
        </div>

      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.gal {
  position: fixed;
  inset: 0;
  z-index: 300;
  background: rgba(10, 7, 5, 0.96);
  display: flex;
  flex-direction: column;
}

/* barra top */
.gal__bar {
  flex: none;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
}
.gal__count {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.7);
  font-variant-numeric: tabular-nums;
}
.gal__close {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(255, 255, 255, 0.08);
  color: #fff;
  cursor: pointer;
  transition: background 0.2s;
}
.gal__close:hover { background: rgba(255, 255, 255, 0.16); }

/* imagen */
.gal__main {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  min-height: 0;
}

.gal__img {
  max-width: 100%;
  max-height: 100%;
  width: auto;
  height: auto;
  object-fit: contain;
  display: block;
  border-radius: 4px;
}

.gal__nav {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(255, 255, 255, 0.08);
  color: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, transform 0.2s;
  z-index: 1;
}
.gal__nav:hover { background: rgba(255, 255, 255, 0.18); }
.gal__nav--prev { left: 16px; }
.gal__nav--next { right: 16px; }

/* miniaturas */
.gal__thumbs {
  flex: none;
  display: flex;
  gap: 8px;
  padding: 14px 20px 20px;
  overflow-x: auto;
  justify-content: center;
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.gal__thumbs::-webkit-scrollbar { display: none; }

.gal__thumb {
  flex: none;
  width: 60px;
  height: 60px;
  border-radius: 8px;
  overflow: hidden;
  border: 2px solid transparent;
  padding: 0;
  cursor: pointer;
  opacity: 0.55;
  transition: opacity 0.2s, border-color 0.2s;
}
.gal__thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.gal__thumb--on {
  border-color: #fff;
  opacity: 1;
}
.gal__thumb:hover { opacity: 0.85; }

/* transitions */
.gfade-enter-active, .gfade-leave-active { transition: opacity 0.22s ease; }
.gfade-enter-from, .gfade-leave-to { opacity: 0; }

.slide-enter-active, .slide-leave-active { transition: opacity 0.2s ease, transform 0.2s ease; }
.slide-enter-from { opacity: 0; transform: translateX(20px); }
.slide-leave-to { opacity: 0; transform: translateX(-20px); }

/* desktop: miniaturas más grandes */
@media (min-width: 1100px) {
  .gal__thumb {
    width: 80px;
    height: 80px;
  }
  .gal__nav--prev { left: 32px; }
  .gal__nav--next { right: 32px; }
  .gal__nav {
    width: 52px;
    height: 52px;
  }
}
</style>
