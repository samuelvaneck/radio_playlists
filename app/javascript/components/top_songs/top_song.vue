<template>
  <div class='card mx-1 playlist-card' v-on:click='handleClickPlaylistItem'>
    <span v-if='loading'>
      <LoadingBar class='card-img-top' v-bind:height='"190px"' v-bind:width='"90%"' />
    </span>
    <span v-else-if='!!song'>
      <img :src='song.data.attributes.spotify_artwork_url' class='card-img-top' />
    </span>
    <div class='card-body'>
      <div class='d-flex flex-column'>
        <div class='d-flex d-flex-row'>
          <div class='bungee-inline'>
            # {{ chartIdx + 1 }}
          </div>
          <div class='ml-auto'>
            <span class='badge badge-secondary'>{{ counter }} x</span>
          </div>
        </div>
        <div class='my-2'>
          <!-- Song -->
          <div v-if='loading'>
            <LoadingBar />
          </div>
          <div v-else-if='!!song'>
            <div>{{ song.data.attributes.title }}</div>
          </div>
          <!-- Artist -->
          <div v-if='loading'>
            <LoadingBar />
          </div>
          <div v-else-if='!!artist'>
            <div><small><i>{{ artist.data.attributes.name }}</i></small></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import LoadingBar from '../application/loading_bar.vue'

  export default {
    props: ['id', 'counter', 'chartIdx'],
    data () {
      return {
        artist: null,
        song: null,
        songArtworkUrl: null,
        radioStation: null,
        loading: true
      }
    },
    methods: {
      handleClickPlaylistItem() {
        if (!!this.song.data.attributes.spotify_song_url) {
          window.open(this.song.data.attributes.spotify_song_url, '_blank')
        }
      },
      getValues() {
        const songUrl = '/songs/' + this.id
        const options = {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json;charset=UTF-8'
          }
        }

        fetch(songUrl, options).then(res => res.json())
          .then(d => { 
            this.song = d
            
            const artistUrl = '/artists/' + this.song.data.attributes.artist_id
            fetch(artistUrl, options).then(res => res.json())
              .then(d => { 
                this.artist = d
                this.loading = false
              })
          })
      } 
    },
    mounted: function() {
      this.getValues()
    },
    components: { LoadingBar }
  }
</script>