import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUiStore = defineStore('ui', () => {
  const loginOpen = ref(false)
  function openLogin() { loginOpen.value = true }
  function closeLogin() { loginOpen.value = false }
  return { loginOpen, openLogin, closeLogin }
})
