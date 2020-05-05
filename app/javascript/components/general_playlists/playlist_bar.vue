<template>
  <div class='d-flex flex-row'>
    <PlaylistGroup />
  </div>
</template>

<script>
  import NavArrow from '../application/slider_button.vue'
  import PlaylistGroup from './playlist_group.vue'

  export default {
    data() {
      return {
        term: ''
      }
    },
    components: { NavArrow, PlaylistGroup }
  }
</script>