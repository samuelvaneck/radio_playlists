<template>
  <div class='flex flew-row flex-nowrap overflow-x-scroll py-2' style='postion:relative'>
    <div class='mx-1 mt-2 mb-3' v-bind:key='item.id' v-for='item in items'>
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
