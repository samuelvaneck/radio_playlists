<template>
  <div class='row flex-nowrap overflow-x-auto py-2' style='postion:relative'>
    <div class='d-flex flex-row' v-for='(item, idx) in items'>
      <TopSong v-bind:id='item[0]' v-bind:counter='item[1]' v-bind:chartIdx='idx' />
    </div>
  </div>
</template>

<script>
  import TopSong from './top_song.vue'
  export default {
    data() {
      return {
        items: [],
        page: 1,
        requestInProgress: false
      }
    },
    components: { TopSong },
    methods: {
      handleScroll(event) {
        const row = event.target
        const rightEdgeOfRow = (row.scrollLeft + row.offsetWidth) >= (row.scrollWidth - 50)
        if (!rightEdgeOfRow || this.requestInProgress) return
        
        this.page++
        this.requestInProgress = true

        const url = '/songs?page=' + this.page
        const options = {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json;charset=UTF-8'
          },
        }

        fetch(url, options).then(response => response.json())
          .then(d => {
            this.items = this.items.concat(d)
            this.requestInProgress = false
          })
      }
    },
    created() {
      const url = '/songs'
      const options = {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json;charset=UTF-8'
        }
      }
      fetch(url, options).then(res => res.json())
        .then(d => this.items = d)
    },
    mounted() {
      this.$el.addEventListener('scroll', this.handleScroll)
    }
  }
</script>