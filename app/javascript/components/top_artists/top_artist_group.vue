<template>
  <div class='flex flew-row flex-nowrap overflow-x-scroll py-2' style='postion:relative'>
    <div class='mx-1 mt-2 mb-3' v-bind:key='item.id' v-for='(item, idx) in items'>
      <TopArtist v-bind:id='item[0]' v-bind:counter='item[1]' v-bind:chartIdx='idx' />
    </div>
  </div>
</template>

<script>
  import TopArtist from './top_artist.vue'
  export default {
    props: ['items'],
    components: { TopArtist },
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
