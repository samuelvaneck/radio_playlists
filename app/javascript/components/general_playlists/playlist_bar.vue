<template>
  <div class='d-flex flex-row'>
    <NavArrow v-bind:direction="'left'" />
    <PlaylistGroup />
    <NavArrow v-bind:direction="'right'" />
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