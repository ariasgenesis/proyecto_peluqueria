import { reactive } from 'vue'

const state = reactive({
  open: false,
  title: '',
  message: '',
  variant: 'info',
  confirmText: 'Aceptar',
  cancelText: 'Cancelar',
  showCancel: false,
  input: false,
  inputType: 'text',
  inputValue: '',
  placeholder: '',
  resolve: null,
})

function openDialog(options, mode) {
  const opts = typeof options === 'string' ? { message: options } : options

  state.title = opts.title || (mode === 'confirm' ? 'Confirmar accion' : 'Aviso')
  state.message = opts.message || ''
  state.variant = opts.variant || (mode === 'confirm' ? 'warning' : 'info')
  state.confirmText = opts.confirmText || 'Aceptar'
  state.cancelText = opts.cancelText || 'Cancelar'
  state.showCancel = mode !== 'alert'
  state.input = mode === 'prompt'
  state.inputType = opts.inputType || 'text'
  state.inputValue = opts.defaultValue || ''
  state.placeholder = opts.placeholder || ''
  state.open = true

  return new Promise((resolve) => {
    state.resolve = resolve
  })
}

function settle(value) {
  const resolve = state.resolve
  state.open = false
  state.resolve = null
  if (resolve) resolve(value)
}

export function useAlertDialog() {
  return {
    state,
    alertDialog(options) {
      return openDialog(options, 'alert').then(() => true)
    },
    confirmDialog(options) {
      return openDialog(options, 'confirm')
    },
    promptDialog(options) {
      return openDialog(options, 'prompt')
    },
    acceptDialog() {
      settle(state.input ? state.inputValue : true)
    },
    cancelDialog() {
      settle(state.input ? null : false)
    },
  }
}
