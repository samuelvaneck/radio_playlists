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
            <div class='ml-auto'>
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
            <div class='rubik mr-2'>
              <div>{{ playedTime() }}</div>
              <div><small><i>{{ playedDate() }}</i></small></div>
            </div>
          </div>
          <div class='float-right'>
            <!-- Radio station label -->
            <div v-if='loading'>
              <LoadingBar />
            </div>
            <div v-else-if='!!radioStation' class='ml-auto'>
              <span class='playlist-badge'>{{ radioStation.data.attributes.name }}</span>
            </div>
          </div>
        </div>

        <div class='flex flex-col my-2'>
          <div class='my-2'>
            <!-- Song -->
            <div v-if='loading'>
              <LoadingBar />
            </div>
            <div v-else-if='!!song'>
              <span>{{ song.data.attributes.title }}</span>
            </div>
            <!-- Artist -->
            <div v-if='loading'>
              <LoadingBar />
            </div>
            <div v-else-if='!!artists'>
              <small><i>{{ artistName() }}</i></small>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import LoadingBar from '../application/loading_bar.vue'

  export default {
    props: ['item'],
    components: { LoadingBar },
    data () {
      return {
        artists: [],
        song: null,
        songArtworkUrl: null,
        radioStation: null,
        loading: true,
        spotifyLogo: null
      }
    },
    methods: {
      handleClickSpotifyBtn() {
        window.open(this.song.data.attributes.spotify_song_url, '_blank')
      },
      playedTime() {
        const date = new Date(this.item.attributes.broadcast_timestamp)
        const hh = (date.getHours() < 10 ? '0' : '') + date.getHours()
        const mm = (date.getMinutes() < 10 ? '0' : '') + date.getMinutes()

        return hh + ':' + mm
      },
      playedDate() {
        const date = new Date(this.item.attributes.created_at)
        const dd = date.getDate()
        const mm = date.getMonth()+1
        const yyyy = date.getFullYear()

        return dd + '-' + mm + '-' + yyyy
      },
      getValue() {
        this.item
        const attributes = this.item.attributes
        const songUrl = '/songs/' + attributes.song_id
        const radioStationUrl = '/radiostations/' + attributes.radiostation_id
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
            this.loading = false

            this.song.data;
            // for(let artist of this.song.data.relationships.artists.data) {
            //   const artistUrl = '/artists/' + artist.id
            //   fetch(artistUrl, options).then(res => res.json())
            //     .then(d => this.artists.push(d))
            // }
          })

        fetch(radioStationUrl, options).then(res => res.json())
          .then(d => this.radioStation = d)
      },
      artistName() {
        return this.artists.map(artist => artist.data.attributes.name ).join(' - ')
      },
      getSpotifyImage() {
        this.spotifyLogo = document.getElementById('section-1').getAttribute('data-spotify-logo-url')
      }
    },
    mounted: function() {
      this.getValue()
      this.getSpotifyImage()
    }
  }
</script>
