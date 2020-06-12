<template>
  <div class='card mx-1 playlist-card'>
    <span v-if='loading'>
      <LoadingBar v-bind:height='"190px"' v-bind:width='"90%"' />
    </span>
    <span v-else><img :src='spotifyArtworkUrl' class='card-img-top' /></span>
    <div class='card-body'>
      <div class='d-flex flex-column'>
        <div class='d-flex d-flex-row'>
          <div class='bungee'>
            # {{ chartIdx + 1 }}
          </div>
          <div class='ml-auto'>
            <span class='badge badge-secondary'>{{ counter }} x</span>
          </div>
        </div>
        <div class='my-2'>
          <div v-if='loading'>
            <LoadingBar />
          </div>
          <div v-else-if='!!artist'>
            <span>{{ artist.data.attributes.name }}</span>
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
    components: { LoadingBar },
    data () {
      return {
        artist: null,
        spotifyArtworkUrl: null,
        loading: true,
      }
    },
    methods: {
      getValues: function() {
        const songUrl = '/artists/' + this.id
        const options = {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json;charset=UTF-8'
          }
        }

        fetch(songUrl, options).then(res => res.json())
          .then(d => {
            this.artist = d
            const songs = this.artist.data.relationships.songs.data;
            if (songs.length === 0) return;
            
            const song = songs[Math.floor(Math.random()*songs.length)]
            const url = '/songs/' + song.id
            const options = {
              method: 'GET',
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json;charset=UTF-8'
              }
            }
            fetch(url, options).then(res => res.json())
              .then(d => { 
                this.spotifyArtworkUrl = d.data.attributes.spotify_artwork_url
                this.loading = false
              })
          })
      }
    },
    mounted: function() {
      this.getValues()
    }
  }
</script>