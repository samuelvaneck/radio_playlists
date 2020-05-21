<template>
  <div class='row flex-nowrap overflow-x-auto py-2' style='postion:relative'>
    <div class='d-flex flex-row' v-for='(item, idx) in items'>
      <TopSong v-bind:song='item' v-bind:counter='item.count' v-bind:chartIdx='idx' />
    </div>
  </div>
</template>

<script>
  import TopSong from './top_song.vue'
  export default {
    props: ['items'],
    components: { TopSong },
    methods: {
      handleScroll(event) {
        const row = event.target
        this.$emit('scroll', row)
      }
    },
    mounted: function() {
      this.$el.addEventListener('scroll', this.handleScroll)
    }
  }
</script>