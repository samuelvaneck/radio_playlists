<template>
  <div class='d-flex flex-column'>
    <div class='d-flex flex-row'>
      <h3>Playlists</h3>
      <div class='ml-auto'>
        <SearchBar @search='onKeyUpSearch' @filter='onRadioStationSelect' />
      </div>
    </div>
    <PlaylistGroup v-bind:items='items' @scroll='onScroll' />
  </div>
</template>

<script>
  import SearchBar from '../application/search_bar.vue'
  import NavArrow from '../application/slider_button.vue'
  import PlaylistGroup from './playlist_group.vue'

  export default {
    data() {
      return {
        term: '',
        items: [],
        page: 1,
        requestInProgress: false,
        lastPage: false,
        radioStationFilter: '',
      }
    },
    methods: {
      getItems: function(append = false) {
        const url = '/generalplaylists?radiostation_id=' + this.radioStationFilter + '&search_term=' + this.term + '&page=' + this.page
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
            this.items = append ? this.items.concat(d.data) : d.data
            this.requestInProgress = false
            // dont make new request if there are no more entries
            this.lastPage = d.data.length < 10
          })
      },
      onKeyUpSearch(value) {
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
      const url = '/generalplaylists'
      this.getItems(url);
    },
    components: { SearchBar, NavArrow, PlaylistGroup }
  }
</script>