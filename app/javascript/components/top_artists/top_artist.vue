<template>
  <div class='wrapper wrapperAnime'>
    <div class='header'>
      <div class='imageWrapper'>
        <span v-if='loading'>

        </span>
        <span v-else-if='!!artist'>
          <img :src='spotifyArtworkUrl' class='image' />
        </span>
      </div>
      <div class='badgeWrapper'>
        <div class='primaryBadge badgeAnime'>
          <div v-if='!!artist && !!artist.data.attributes.spotify_artist_url' class='mt-2 d-flex flex-row'>
            <div class=''>
              <img :src='spotifyLogo' class='spotify-btn' v-on:click='handleClickSpotifyBtn' />
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class='textWrapper'>
      <div class='text'>
        <div class='flex flex-row justify-between my-2'>
          <div>
            <div class='bungee'>
              # {{ chartIdx + 1 }}
            </div>
          </div>
          <div class='float-right'>
            <span class='playlist-badge'>{{ counter }} x</span>
          </div>
        </div>
        <div class='flex flex-col my-2'>
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
  import SpotifyLogo from '../../../assets/images/Spotify_Icon_RGB_Green.png'

  export default {
    props: ['artist', 'counter', 'chartIdx'],
    components: { LoadingBar, SpotifyLogo },
    data () {
      return {
        // artist: null,
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
      setSpotifyArtworkUrl: function() {
         if (!!this.artist.data.attributes.spotify_artwork_url) {
          this.spotifyArtworkUrl = this.artist.data.attributes.spotify_artwork_url
        }
        this.loading = false
      }
    },
    mounted: function() {
      this.setSpotifyArtworkUrl()
    }
  }
</script>
