import { defineStore } from "pinia";

export const useModalStore = defineStore('modal', {
  state: () => {
    return {
      object: null,
      showModal: false
    }
  }
})
