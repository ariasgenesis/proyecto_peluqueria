<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'

import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { apiErrorMessage } from '@/api/client'

const auth = useAuthStore()
const ui = useUiStore()
const router = useRouter()

const email = ref('')
const password = ref('')
const showPass = ref(false)
const remember = ref(true)
const focus = ref(null)
const error = ref('')
const loading = ref(false)

const valid = computed(() => email.value.trim().length > 0 && password.value.length >= 4)

function close() {
  ui.closeLogin()
  error.value = ''
}

function toRegister() {
  close()
  router.push('/registro')
}

async function onSubmit() {
  if (!valid.value || loading.value) return
  error.value = ''
  loading.value = true
  try {
    const user = await auth.login(email.value.trim(), password.value)
    close()
    if (user.rol !== 'cliente') router.replace({ name: 'admin-dashboard' })
  } catch (err) {
    error.value = apiErrorMessage(err, 'Correo o contraseña incorrectos')
  } finally {
    loading.value = false
  }
}

function onKey(e) {
  if (ui.loginOpen && e.key === 'Escape') close()
}
onMounted(() => window.addEventListener('keydown', onKey))
onUnmounted(() => window.removeEventListener('keydown', onKey))
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="ui.loginOpen" class="overlay" @click.self="close">
        <Transition name="sheet">
          <div v-if="ui.loginOpen" class="dialog" role="dialog" aria-modal="true" aria-label="Iniciar sesión">

            <!-- cerrar -->
            <button class="dialog__close" @click="close" aria-label="Cerrar">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
            </button>

            <!-- panel foto (desktop) -->
            <div class="photo">
              <img class="photo__img" src="/img/salon/2.webp" alt="" />
              <div class="photo__overlay"></div>
              <div class="photo__brand">Beutycore</div>
              <div class="photo__quote">
                <div class="photo__quote-t">Tu estilo,<br>reservado.</div>
                <div class="photo__quote-d">Entra a tu cuenta para gestionar citas y guardar a tus estilistas favoritas.</div>
              </div>
            </div>

            <!-- panel form -->
            <div class="form-pad">
              <!-- handle (mobile) -->
              <div class="handle"></div>

              <div class="form-inner">
                <h2 class="form__title">Bienvenida de vuelta</h2>
                <p class="form__sub">Ingresa para continuar.</p>

                <form @submit.prevent="onSubmit" novalidate>

                  <!-- email -->
                  <div class="field">
                    <label class="field__lbl">Usuario o correo</label>
                    <div class="field__wrap" :class="{ 'field__wrap--on': focus === 'email' }">
                      <svg class="field__ico" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="m3 7 9 6 9-6"/></svg>
                      <input v-model="email" type="text" autocomplete="username" placeholder="admin / hola@correo.com" class="field__input" @focus="focus = 'email'" @blur="focus = null" />
                    </div>
                  </div>

                  <!-- password -->
                  <div class="field">
                    <div class="field__row">
                      <label class="field__lbl">Contraseña</label>
                      <span class="field__forgot">¿Olvidaste?</span>
                    </div>
                    <div class="field__wrap" :class="{ 'field__wrap--on': focus === 'pass' }">
                      <svg class="field__ico" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>
                      <input v-model="password" :type="showPass ? 'text' : 'password'" autocomplete="current-password" placeholder="••••••••" class="field__input field__input--pass" @focus="focus = 'pass'" @blur="focus = null" />
                      <button type="button" class="field__eye" @click="showPass = !showPass" aria-label="Ver contraseña">
                        <svg v-if="showPass" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/></svg>
                        <svg v-else width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#a59a8d" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M9.9 4.24A9.1 9.1 0 0 1 12 4c6 0 10 7 10 7a17 17 0 0 1-2.6 3.3M6.6 6.6A17 17 0 0 0 2 11s4 7 10 7a9 9 0 0 0 3.4-.66M1 1l22 22"/></svg>
                      </button>
                    </div>
                  </div>

                  <!-- remember -->
                  <div class="remember" @click="remember = !remember">
                    <div class="remember__box" :class="{ 'remember__box--on': remember }">
                      <svg v-if="remember" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#FBF6F4" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
                    </div>
                    <span class="remember__lbl">Mantener sesión iniciada</span>
                  </div>

                  <p v-if="error" class="form__error">{{ error }}</p>

                  <button type="submit" class="submit" :class="{ 'submit--on': valid }" :disabled="!valid || loading">
                    <span v-if="loading" class="spin"></span>
                    <span v-else class="submit__lbl">Ingresar</span>
                  </button>

                </form>

                <!-- divider -->
                <div class="divider">
                  <div class="div__line"></div>
                  <span class="div__txt">o continúa con</span>
                  <div class="div__line"></div>
                </div>

                <!-- social -->
                <div class="social">
                  <button type="button" class="soc__btn">
                    <svg width="18" height="18" viewBox="0 0 24 24"><path fill="#EA4335" d="M12 10.2v3.9h5.5c-.24 1.45-1.7 4.25-5.5 4.25-3.3 0-6-2.74-6-6.1s2.7-6.1 6-6.1c1.88 0 3.14.8 3.86 1.49l2.63-2.54C16.96 3.4 14.7 2.4 12 2.4 6.95 2.4 2.85 6.5 2.85 11.55S6.95 20.7 12 20.7c5.27 0 8.76-3.7 8.76-8.92 0-.6-.06-1.06-.15-1.52H12z"/></svg>
                    Google
                  </button>
                  <button type="button" class="soc__btn">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="#1A1714"><path d="M16.4 12.6c0-2.2 1.8-3.2 1.9-3.3-1-1.5-2.6-1.7-3.2-1.7-1.4-.14-2.7.8-3.3.8-.7 0-1.7-.78-2.8-.76-1.5.02-2.8.85-3.5 2.16-1.5 2.6-.4 6.5 1.1 8.6.7 1 1.5 2.2 2.6 2.16 1-.04 1.4-.67 2.7-.67 1.2 0 1.6.67 2.7.65 1.1-.02 1.8-1.06 2.5-2.07.8-1.2 1.1-2.32 1.1-2.38-.02-.01-2.1-.81-2.1-3.2zM14.3 6.2c.6-.72 1-1.7.9-2.7-.86.03-1.9.57-2.5 1.29-.55.63-1.03 1.65-.9 2.62.95.07 1.92-.49 2.5-1.21z"/></svg>
                    Apple
                  </button>
                </div>

                <p class="form__signup">
                  ¿Primera vez en Beutycore?
                  <button type="button" class="form__signup-link" @click="toRegister">Crea tu cuenta</button>
                </p>

              </div>
            </div>

          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
@keyframes spin { to { transform: rotate(360deg); } }
@keyframes fade-up { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

/* backdrop */
.overlay {
  position: fixed;
  inset: 0;
  z-index: 300;
  background: rgba(20, 14, 10, 0.52);
  display: flex;
  align-items: flex-end; /* mobile: sheet desde abajo */
}

/* dialog / sheet */
.dialog {
  position: relative;
  width: 100%;
  max-height: 92vh;
  overflow-y: auto;
  background: #FBF6F4;
  border-radius: 24px 24px 0 0;
  font-family: var(--sans);
  display: grid;
  grid-template-columns: 1fr; /* mobile: 1 col */
}

/* cerrar: solo desktop */
.dialog__close {
  display: none;
  position: absolute;
  top: 16px;
  right: 20px;
  z-index: 2;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 1px solid var(--hairline);
  background: #fff;
  cursor: pointer;
  align-items: center;
  justify-content: center;
  color: var(--ink);
}

/* panel foto: oculto mobile */
.photo { display: none; }

/* handle mobile */
.handle {
  width: 36px;
  height: 4px;
  border-radius: 2px;
  background: rgba(26, 23, 20, .18);
  margin: 14px auto 0;
}

/* form pad */
.form-pad {
  padding: 12px 26px 40px;
}
.form-inner {
  animation: fade-up .35s ease both;
}

.form__title {
  margin: 20px 0 0;
  font-family: var(--serif);
  font-size: 26px;
  font-weight: 500;
  color: var(--ink);
  letter-spacing: -.015em;
}
.form__sub {
  margin: 6px 0 20px;
  font-size: 14px;
  color: var(--muted);
}

/* campos */
.field { margin-bottom: 14px; }
.field__lbl {
  display: block;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: .03em;
  color: #7a6f63;
  margin-bottom: 7px;
}
.field__row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 7px;
}
.field__forgot {
  font-size: 12px;
  font-weight: 500;
  color: var(--rose);
  cursor: pointer;
}
.field__wrap {
  display: flex;
  align-items: center;
  gap: 10px;
  height: 50px;
  padding: 0 14px;
  border-radius: 14px;
  background: #fff;
  border: 1.5px solid rgba(26, 23, 20, .12);
  transition: border-color .2s;
}
.field__wrap--on { border-color: var(--rose); }
.field__ico { flex: none; }
.field__input {
  flex: 1;
  border: none;
  background: transparent;
  font-family: var(--sans);
  font-size: 15px;
  color: var(--ink);
  min-width: 0;
}
.field__input::placeholder { color: #b7ab9d; }
.field__input:focus { outline: none; }
.field__input--pass { letter-spacing: .05em; }
.field__eye {
  flex: none;
  display: flex;
  padding: 4px;
  border: none;
  background: transparent;
  cursor: pointer;
}

/* remember */
.remember {
  display: flex;
  align-items: center;
  gap: 9px;
  cursor: pointer;
  user-select: none;
  margin-bottom: 4px;
}
.remember__box {
  width: 20px;
  height: 20px;
  flex: none;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #fff;
  border: 1.5px solid rgba(26, 23, 20, .22);
  transition: all .2s;
}
.remember__box--on { background: var(--rose); border-color: var(--rose); }
.remember__lbl { font-size: 13px; color: #6b6258; }

.form__error {
  margin: 10px 0 0;
  font-size: 13px;
  color: #c0392b;
}

/* submit */
.submit {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 52px;
  margin-top: 20px;
  border-radius: 14px;
  border: none;
  background: #cdbfb4;
  color: #FBF6F4;
  opacity: 0.7;
  cursor: not-allowed;
  transition: background .2s, opacity .2s, filter .2s;
}
.submit--on { background: var(--rose); opacity: 1; cursor: pointer; }
.submit--on:hover { filter: brightness(1.07); }
.submit__lbl { font-family: var(--serif); font-size: 17px; font-weight: 500; letter-spacing: .01em; }
.spin {
  display: block;
  width: 18px; height: 18px;
  border-radius: 50%;
  border: 2px solid rgba(251,246,244,.4);
  border-top-color: #FBF6F4;
  animation: spin .7s linear infinite;
}

/* divider */
.divider { display: flex; align-items: center; gap: 14px; margin: 20px 0; }
.div__line { flex: 1; height: 1px; background: rgba(26,23,20,.1); }
.div__txt { font-size: 11px; letter-spacing: .06em; text-transform: uppercase; color: #a59a8d; white-space: nowrap; }

/* social */
.social { display: flex; gap: 10px; }
.soc__btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  height: 48px;
  border-radius: 14px;
  background: #fff;
  border: 1.5px solid rgba(26,23,20,.12);
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: var(--ink);
  font-family: var(--sans);
  transition: background .15s;
}
.soc__btn:hover { background: #f5efec; }

.form__signup {
  margin: 22px 0 0;
  text-align: center;
  font-size: 13.5px;
  color: var(--muted);
}
.form__signup-link {
  font-weight: 600;
  color: var(--rose);
  background: none;
  border: none;
  cursor: pointer;
  font-size: inherit;
  font-family: inherit;
  padding: 0;
}
.form__signup-link:hover { text-decoration: underline; }

/* ======= TRANSITIONS ======= */
.fade-enter-active, .fade-leave-active { transition: opacity .25s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

/* mobile: slide from bottom */
.sheet-enter-active, .sheet-leave-active { transition: transform .32s cubic-bezier(.32,1,.46,1), opacity .25s ease; }
.sheet-enter-from, .sheet-leave-to { transform: translateY(100%); opacity: 0.5; }

/* ======= DESKTOP (≥820px) ======= */
@media (min-width: 820px) {
  .overlay {
    align-items: center;
    justify-content: center;
    padding: 32px;
  }

  .dialog {
    width: 100%;
    max-width: 920px;
    max-height: 88vh;
    border-radius: 22px;
    grid-template-columns: minmax(0, 1.05fr) minmax(0, .95fr);
    overflow: hidden;
  }

  /* desktop: scale-fade en vez de slide */
  .sheet-enter-from, .sheet-leave-to {
    transform: scale(0.96);
    opacity: 0;
  }

  .dialog__close { display: flex; }
  .handle { display: none; }

  .photo {
    display: block;
    position: relative;
    min-height: 560px;
  }
  .photo__img {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }
  .photo__overlay {
    position: absolute;
    inset: 0;
    background: linear-gradient(160deg, rgba(122,58,79,.12) 0%, rgba(26,23,20,0) 38%, rgba(26,23,20,.58) 100%);
  }
  .photo__brand {
    position: absolute;
    left: 36px;
    top: 32px;
    font-family: var(--serif);
    font-size: 22px;
    font-weight: 500;
    color: #FBF6F4;
    letter-spacing: -.01em;
    text-shadow: 0 1px 8px rgba(20,12,4,.3);
  }
  .photo__quote {
    position: absolute;
    left: 36px;
    right: 36px;
    bottom: 36px;
  }
  .photo__quote-t {
    font-family: var(--serif);
    font-size: 28px;
    line-height: 1.12;
    color: #FBF6F4;
    letter-spacing: -.01em;
    text-shadow: 0 1px 10px rgba(20,12,4,.28);
  }
  .photo__quote-d {
    font-size: 13px;
    line-height: 1.55;
    color: rgba(251,246,244,.86);
    margin-top: 10px;
    max-width: 260px;
  }

  .form-pad {
    padding: 48px 52px;
    display: flex;
    flex-direction: column;
    justify-content: center;
    overflow-y: auto;
  }

  .form__title { font-size: 28px; }
}
</style>
