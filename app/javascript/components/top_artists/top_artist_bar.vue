<template>
  <div class='d-flex flex-column'>
    <div class='d-flex flex-row'>
      <h3>Top artists</h3>
      <div class='ml-auto'>
        <SearchBar @search='onSearch' @filter='onRadioStationSelect' />
      </div>
    </div>
    <div v-if='loading'>
      <div class='row flex-nowrap overflow-x-auto py-2'>
        <LoadingCard v-for='n in 10' />
      </div>
    </div>
    <div v-else>
      <TopArtistGroup v-bind:items='items' @scroll='onScroll' />
    </div>
  </div>
</template>

<script>
  import SearchBar from '../application/search_bar.vue'
  import NavArrow from '../application/slider_button.vue'
  import TopArtistGroup from './top_artist_group.vue'
  import LoadingCard from '../application/loading_card.vue'

  export default {
    data() {
      return {
        term: '',
        items: [],
        page: 1,
        requestInProgress: false,
        lastPage: false,
        radioStationFilter: '',
        loading: true
      }
    },
    components: { SearchBar, NavArrow, TopArtistGroup, LoadingCard },
    methods: {
      getItems: function(append = false) {
        const url = '/artists?radiostation_id=' + this.radioStationFilter + '&search_term=' + this.term + '&page=' + this.page
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
            this.loading = false
          })
      },
      onSearch: function(value) {
        if (this.timer) {
          clearTimeout(this.timer);
          this.timer = null;
          this.loading = true
        }
        this.timer = setTimeout(() => {
          this.term = value
          this.page = 1
          this.lastPage = false
          this.getItems()
        }, 400);
      },
      onScroll: function(row) {
        const rightEdgeOfRow = (row.scrollLeft + row.offsetWidth) >= (row.scrollWidth - 50)
        if (!rightEdgeOfRow || this.requestInProgress || this.lastPage) return
        
        this.page++
        this.getItems(true)
      },
      onRadioStationSelect: function(value) {
        this.radioStationFilter = value || ''
        this.page = 1
        this.lastPage = false
        this.getItems()
      }
    },
    created: function() {
      this.getItems()
    }
  }
</script>