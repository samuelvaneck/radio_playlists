<template>
  <div class='row flex-nowrap overflow-x-auto' style='postion:relative'>
    <div class='d-flex flex-row' v-for='item in items'>
      <Playlist v-bind:item='item' />
    </div>
  </div>
</template>

<script>
  import Playlist from './playlist.vue'
  export default {
    data() {
      return {
        items: []
      }
    },
    components: { Playlist },
    methods: {
      handleScroll(event) {
        
      }
    },
    created() {
      const url = '/generalplaylists'
      const options = {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json;charset=UTF-8'
        }
      }
      fetch(url, options).then(res => res.json())
        .then(d => this.items = d.data)
    },
    mounted() {
      this.$el.addEventListener('scroll', this.handleScroll)
    }
  }
</script>