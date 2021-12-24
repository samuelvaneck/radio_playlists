<template>
  <div class='wrapper wrapperAnime'>
    <div class='header'>
      <div class='imageWrapper'>
        <span v-if='loading'>
          <LoadingBar class='image' v-bind:height='"190px"' v-bind:width='"90%"' />
        </span>
        <span v-else-if='!!song'>
          <img :src='song.data.attributes.spotify_artwork_url' class='image' />
        </span>
      </div>
      <div class='badgeWrapper'>
        <div class='primaryBadge badgeAnime'>
          <div v-if='!!song && !!song.data.attributes.spotify_song_url' class='mt-2 flex flex-row'>
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
          <div class='grow'>
            <span class='bungee'>
              # {{ chartIdx + 1 }}
            </span>
          </div>
          <div class='grow'>
            <span class=''>{{ counter }} x</span>
          </div>
        </div>
        <div class='flex flex-col my-2'>
          <!-- Song -->
          <div class='w-full my-1' v-if='loading'>
            <LoadingBar />
          </div>
          <div class='grow my-1' v-else-if='!!song'>
            <div>{{ song.data.attributes.title }}</div>
          </div>
          <!-- Artist -->
          <div class='w-full my-1' v-if='loading'>
            <LoadingBar />
          </div>
          <div class='grow my-1' v-else-if='!!artists'>
            <div><small><i>{{ artistsNames() }}</i></small></div>
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
