<template>
  <div class='d-flex flex-row'>
    <TopArtistGroup />
  </div>
</template>

<script>
  import NavArrow from '../application/slider_button.vue'
  import TopArtistGroup from './top_artist_group.vue'

  export default {
    data() {
      return {
        term: ''
      }
    },
    components: { NavArrow, TopArtistGroup }
  }
</script>