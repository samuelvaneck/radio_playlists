<template>
  <div class='row flex-nowrap overflow-x-auto py-2' style='postion:relative'>
    <div class='d-flex flex-row' v-for='item in items'>
      <Playlist v-bind:item='item' />
    </div>
  </div>
</template>

<script>
  import Playlist from './playlist.vue'
  export default {
    props: ['items'],
    components: { Playlist },
    methods: {
      handleScroll(event) {
        const row = event.target
        this.$emit('scroll', row)
      }
    },
    mounted() {
      this.$el.addEventListener('scroll', this.handleScroll)
    }
  }
</script>