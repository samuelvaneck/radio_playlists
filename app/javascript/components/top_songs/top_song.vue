<template>
  <div class='card mx-1 playlist-card'>
    <span v-if='loading'>
      <LoadingBar class='card-img-top' v-bind:height='"190px"' v-bind:width='"90%"' />
    </span>
    <span v-else-if='!!song'>
      <img :src='song.data.attributes.spotify_artwork_url' class='card-img-top' />
    </span>
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
          <div v-else-if='!!artists'>
            <div><small><i>{{ artistsNames() }}</i></small></div>
          </div>
        </div>
        <div v-if='!!song && !!song.data.attributes.spotify_song_url' class='mt-2 d-flex flex-row'>
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
    data () {
      return {
        artists: [],
        song: null,
        songArtworkUrl: null,
        radioStation: null,
        loading: true,
        spotifyLogo: SpotifyLogo
      }
    },
    methods: {
      handleClickSpotifyBtn() {
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

            const artistUrl = '/artists/' + this.song.data.attributes.artist_ids
            fetch(artistUrl, options).then(res => res.json())
              .then(d => { 
                this.artist = d
                this.loading = false

                for(let artist of this.song.data.relationships.artists.data) {
                  const artistUrl = '/artists/' + artist.id
                  fetch(artistUrl, options).then(res => res.json())
                    .then(d => this.artists.push(d))
                }
              })
          })
      },
      artistsNames() {
        return this.artists.map(artist => artist.data.attributes.name ).join(' - ')
      }
    },
    mounted: function() {
      this.getValues()
    },
    components: { LoadingBar }
  }
</script>