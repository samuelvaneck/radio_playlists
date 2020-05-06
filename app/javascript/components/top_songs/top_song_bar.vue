<template>
  <div class='d-flex flex-column'>
    <div class='d-flex flex-row'>
      <h3>Top songs</h3>
      <div class='ml-auto'>
        <SearchBar @search='onSearch' @filter='onRadioStationSelect' />
      </div>
    </div>
    <TopSongGroup v-bind:items='items' @scroll='onScroll' />
  </div>
</template>

<script>
  import SearchBar from '../application/search_bar.vue'
  import NavArrow from '../application/slider_button.vue'
  import TopSongGroup from './top_song_group.vue'

  export default {
    data() {
      return {
        term: '',
        items: [],
        page: 1,
        requestInProgress: false,
        lastPage: false,
        radioStationFilter: ''
      }
    },
    components: { SearchBar, NavArrow, TopSongGroup },
    methods: {
      getItems: function(append = false) {
        const url = '/songs?radiostation_id=' + this.radioStationFilter + '&search_term=' + this.term + '&page=' + this.page
        const options = {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json;charset=UTF-8'
          }
        }

        if (!append) this.items = []
        this.requestInProgress = true

        fetch(url, options).then(res => res.json())
          .then(d => {
            // append if scroll else set new items
            this.items = append ? this.items.concat(d) : d
            this.requestInProgress = false
            // dont make new request if there are no more entries
            this.lastPage = d < 10
          })
      },
      onSearch(value) {
        if (this.timer) {
          clearTimeout(this.timer);
          this.timer = null;
        }
        this.timer = setTimeout(() => {
          this.term = value
          this.page = 1
          this.lastPage = false
          this.getItems()
        }, 400);
      },
      onScroll(row) {
        const rightEdgeOfRow = (row.scrollLeft + row.offsetWidth) >= (row.scrollWidth - 50)
        if (!rightEdgeOfRow || this.requestInProgress || this.lastPage) return
        
        this.page++
        this.getItems(true)
      },
      onRadioStationSelect(value) {
        this.radioStationFilter = value || ''
        this.page = 1
        this.lastPage = false
        this.getItems()
      }
    },
    created() {
      this.getItems()
    }
  }
</script>