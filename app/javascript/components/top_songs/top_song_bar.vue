<template>
  <div class='d-flex flex-row'>
    <TopSongGroup />
  </div>
</template>

<script>
  import NavArrow from '../application/slider_button.vue'
  import TopSongGroup from './top_song_group.vue'

  export default {
    data() {
      return {
        term: ''
      }
    },
    components: { NavArrow, TopSongGroup }
  }
</script>