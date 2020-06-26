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
        <div v-if='!!artist && !!artist.data.attributes.spotify_artist_url' class='mt-2 d-flex flex-row'>
          <div class='ml-auto'>
            <img :src='spotifyLogo' class='spotify-btn' v-on:click='handleClickSpotifyBtn' />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import LoadingBar from '../application/loading_bar.vue'
  import SpotifyLogo from 'images/Spotify_Icon_RGB_Green.png'

  export default {
    props: ['id', 'counter', 'chartIdx'],
    components: { LoadingBar, SpotifyLogo },
    data () {
      return {
        artist: null,
        spotifyArtworkUrl: null,
        loading: true,
        spotifyLogo: SpotifyLogo
      }
    },
    methods: {
      handleClickSpotifyBtn() {
        if (!!this.artist.data.attributes.spotify_artist_url) {
          window.open(this.artist.data.attributes.spotify_artist_url, '_blank')
        }
      },
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
            if (!!this.artist.data.attributes.spotify_artwork_url) {
              this.spotifyArtworkUrl = this.artist.data.attributes.spotify_artwork_url
            }
            this.loading = false
          })
      }
    },
    mounted: function() {
      this.getValues()
    }
  }
</script>