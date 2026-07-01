<script setup>
import { computed, nextTick, ref, watch } from 'vue'
import { useAlertDialog } from '@/composables/useAlertDialog'

const inputEl = ref(null)
const { state, acceptDialog, cancelDialog } = useAlertDialog()

const iconPath = computed(() => {
  if (state.variant === 'danger') return 'M12 8v5M12 17h.01M10.3 4.5 2.8 17.5A2 2 0 0 0 4.5 20h15a2 2 0 0 0 1.7-2.5L13.7 4.5a2 2 0 0 0-3.4 0Z'
  if (state.variant === 'success') return 'm5 13 4 4L19 7'
  return 'M12 8v4M12 16h.01M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z'
})

watch(() => state.open, async (open) => {
  if (open && state.input) {
    await nextTick()
    inputEl.value?.focus()
  }
})
</script>

<template>
  <Teleport to="body">
    <Transition name="app-alert">
      <div v-if="state.open" class="app-alert" @click.self="cancelDialog">
        <section
          class="app-alert__dialog"
          :class="'app-alert__dialog--' + state.variant"
          role="dialog"
          aria-modal="true"
          :aria-label="state.title"
          @keydown.esc="cancelDialog"
        >
          <button class="app-alert__close" type="button" aria-label="Cerrar" @click="cancelDialog">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
              <path d="M18 6 6 18M6 6l12 12" />
            </svg>
          </button>

          <div class="app-alert__icon" aria-hidden="true">
            <svg width="23" height="23" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
              <path :d="iconPath" />
            </svg>
          </div>

          <h2 class="app-alert__title">{{ state.title }}</h2>
          <p class="app-alert__message">{{ state.message }}</p>

          <input
            v-if="state.input"
            ref="inputEl"
            v-model="state.inputValue"
            class="app-alert__input"
            :type="state.inputType"
            :placeholder="state.placeholder"
            @keyup.enter="acceptDialog"
          >

          <div class="app-alert__actions">
            <button v-if="state.showCancel" class="app-alert__btn app-alert__btn--ghost" type="button" @click="cancelDialog">
              {{ state.cancelText }}
            </button>
            <button class="app-alert__btn app-alert__btn--main" type="button" @click="acceptDialog">
              {{ state.confirmText }}
            </button>
          </div>
        </section>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.app-alert {
  position: fixed;
  inset: 0;
  z-index: 200;
  display: grid;
  place-items: center;
  padding: 18px;
  background: rgba(26, 23, 20, .34);
}

.app-alert__dialog {
  position: relative;
  width: min(420px, 100%);
  border: 1px solid rgba(26, 23, 20, .08);
  border-radius: 22px;
  background: #FBF6F4;
  box-shadow: 0 24px 70px rgba(20, 12, 4, .20);
  padding: 28px 24px 22px;
  color: #1A1714;
  font-family: Inter, system-ui, sans-serif;
}

.app-alert__close {
  position: absolute;
  top: 14px;
  right: 14px;
  width: 32px;
  height: 32px;
  display: grid;
  place-items: center;
  border: 1px solid rgba(26, 23, 20, .10);
  border-radius: 9px;
  background: #fff;
  color: #8a7f72;
  cursor: pointer;
}

.app-alert__icon {
  width: 48px;
  height: 48px;
  display: grid;
  place-items: center;
  border-radius: 50%;
  background: rgba(176, 69, 95, .10);
  color: #B0455F;
  margin-bottom: 16px;
}

.app-alert__dialog--danger .app-alert__icon {
  background: rgba(220, 38, 38, .10);
  color: #dc2626;
}

.app-alert__dialog--success .app-alert__icon {
  background: rgba(22, 163, 74, .12);
  color: #15803d;
}

.app-alert__title {
  margin: 0;
  padding-right: 32px;
  font-family: Fraunces, Georgia, serif;
  font-size: 22px;
  font-weight: 500;
  line-height: 1.15;
  color: #1A1714;
}

.app-alert__message {
  margin: 10px 0 0;
  color: #6b6258;
  font-size: 14px;
  line-height: 1.55;
}

.app-alert__input {
  width: 100%;
  height: 44px;
  margin-top: 18px;
  border: 1.5px solid rgba(26, 23, 20, .14);
  border-radius: 12px;
  background: #fff;
  color: #1A1714;
  font: inherit;
  outline: none;
  padding: 0 13px;
}

.app-alert__input:focus {
  border-color: #B0455F;
}

.app-alert__actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 24px;
}

.app-alert__btn {
  min-width: 112px;
  height: 44px;
  border-radius: 13px;
  font: inherit;
  font-size: 13.5px;
  font-weight: 600;
  cursor: pointer;
}

.app-alert__btn--ghost {
  border: 1.5px solid rgba(26, 23, 20, .14);
  background: transparent;
  color: #1A1714;
}

.app-alert__btn--main {
  border: none;
  background: #B0455F;
  color: #FBF6F4;
}

.app-alert__dialog--danger .app-alert__btn--main {
  background: #dc2626;
}

.app-alert-enter-active,
.app-alert-leave-active {
  transition: opacity .16s ease;
}

.app-alert-enter-from,
.app-alert-leave-to {
  opacity: 0;
}

.app-alert-enter-active .app-alert__dialog,
.app-alert-leave-active .app-alert__dialog {
  transition: transform .18s ease, opacity .18s ease;
}

.app-alert-enter-from .app-alert__dialog,
.app-alert-leave-to .app-alert__dialog {
  opacity: 0;
  transform: translateY(12px) scale(.98);
}

@media (max-width: 520px) {
  .app-alert {
    align-items: end;
    padding: 12px;
  }

  .app-alert__dialog {
    border-radius: 22px 22px 16px 16px;
    padding: 26px 20px 20px;
  }

  .app-alert__actions {
    flex-direction: column-reverse;
  }

  .app-alert__btn {
    width: 100%;
  }
}
</style>
