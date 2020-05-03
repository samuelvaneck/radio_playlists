<template>
  <div>
    <ul class='collection' v-for='item in items'>
      <Playlist v-bind:item='item' />
    </ul>
  </div>
</template>

<script>
  import Playlist from './playlist.vue'

  export default {
    data () {
      return {
        term: '',
        items: []
      }
    },
    components: { Playlist },
    created: function() {
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
    }
  }
</script>