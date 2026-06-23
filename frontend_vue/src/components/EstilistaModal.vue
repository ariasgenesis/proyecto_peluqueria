<script setup>
import { onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'

const props = defineProps({
  modelValue: Boolean,
  estilista: Object, // { id, nombre, esp, img, bio?, reviews? }
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
      <div v-if="modelValue && estilista" class="overlay" @click.self="close">
        <Transition name="sheet">
          <div v-if="modelValue" class="sheet" role="dialog" aria-modal="true">
            <div class="handle"></div>
            <button class="close" @click="close" aria-label="Cerrar">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
            </button>

            <!-- mobile: centrado vertical -->
            <div class="sheet__top">
              <img class="sheet__avatar" :src="estilista.img" :alt="estilista.nombre" />
              <div class="sheet__info">
                <h2 class="sheet__name">{{ estilista.nombre }}</h2>
                <div class="sheet__esp">{{ estilista.esp }}</div>
                <div class="sheet__rate">
                  <span class="star">★ 5,0</span>
                  <span class="sheet__rev">· {{ estilista.reviews ?? 80 }} reseñas</span>
                </div>
              </div>
            </div>

            <div class="sheet__body">
              <p class="sheet__bio">
                {{ estilista.bio || 'Especialista apasionada por transformar looks con técnica y cuidado. Cada cliente es un lienzo único.' }}
              </p>

              <div class="sheet__tags">
                <span v-for="tag in (estilista.tags || [estilista.esp])" :key="tag" class="tag">{{ tag }}</span>
                <span class="tag">Reserva disponible</span>
              </div>

              <button class="sheet__cta" @click="reservar">Reservar con {{ estilista.nombre.split(' ')[0] }}</button>
              <div class="sheet__note">Seleccionarás estilista en el paso de reserva</div>
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
  display: none;
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

.sheet__top {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px 24px 0;
  text-align: center;
}

.sheet__avatar {
  width: 96px;
  height: 96px;
  border-radius: 50%;
  object-fit: cover;
  border: 3px solid #fbeef1;
  display: block;
}

.sheet__info {
  margin-top: 14px;
}

.sheet__name {
  margin: 0;
  font-family: var(--serif);
  font-size: 22px;
  font-weight: 500;
  color: var(--ink);
}

.sheet__esp {
  margin-top: 4px;
  font-size: 14px;
  color: var(--muted);
}

.sheet__rate {
  margin-top: 6px;
  font-size: 13px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}
.star { color: #ffcb4d; font-weight: 600; }
.sheet__rev { color: var(--muted); }

.sheet__body {
  padding: 16px 24px 32px;
}

.sheet__bio {
  margin: 0;
  font-size: 14px;
  line-height: 1.65;
  color: var(--muted-2);
  text-align: center;
}

.sheet__tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 16px;
  justify-content: center;
}
.tag {
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
  margin-top: 22px;
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
    width: 540px;
    max-height: 80vh;
    border-radius: 22px;
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }

  .handle { display: none; }

  .close {
    display: flex;
    top: 16px;
    right: 16px;
  }

  /* desktop: foto grande arriba, texto centrado */
  .sheet__avatar {
    width: 120px;
    height: 120px;
    margin-top: 40px;
    border: 4px solid #fbeef1;
  }

  .sheet__name { font-size: 26px; }
  .sheet__bio { font-size: 15px; }

  .sheet-enter-from,
  .sheet-leave-to {
    transform: scale(0.96);
    opacity: 0;
  }
}
</style>
