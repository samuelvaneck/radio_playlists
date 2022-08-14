import { defineStore } from "pinia";

export const useModalStore = defineStore('modal', {
  state: () => {
    return {
      artists: null,
      song: null,
      artist: null,
      showModal: false
    }
  }
})
