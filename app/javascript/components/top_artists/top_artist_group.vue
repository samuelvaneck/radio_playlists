<template>
  <div class='row flex-nowrap overflow-x-auto py-2' style='postion:relative'>
    <div class='d-flex flex-row' v-for='(item, idx) in items'>
      <TopArtist v-bind:id='item[0]' v-bind:counter='item[1]' v-bind:chartIdx='idx' />
    </div>
  </div>
</template>

<script>
  import TopArtist from './top_artist.vue'
  export default {
    data() {
      return {
        items: [],
        page: 1,
        requestInProgress: false
      }
    },
    components: { TopArtist },
    methods: {
      handleScroll(event) {
        const row = event.target
        const rightEdgeOfRow = (row.scrollLeft + row.offsetWidth) >= (row.scrollWidth - 50)
        if (!rightEdgeOfRow || this.requestInProgress) return
        
        this.page++
        this.requestInProgress = true

        const url = '/artists?page=' + this.page
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
      const url = '/artists'
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