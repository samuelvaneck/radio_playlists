<template>
  <div class='wrapper wrapperAnime' @click="handleClickCard">
    <div class='header'>
      <div class='imageWrapper'>
        <span v-if='loading'>
          <LoadingBar class='image' v-bind:height='"190px"' v-bind:width='"90%"' />
        </span>
        <span v-if="!!song.spotify_artwork_url">
          <img :src='song.spotify_artwork_url' class='image' />
        </span>
        <span v-else>
          <img :src='lpIcon' class="image" />
        </span>
      </div>
      <div v-if="!!song.spotify_song_url" class='ml-auto'>
        <div class='badgeWrapper'>
          <div class='primaryBadge badgeAnime'>
            <div class='mt-2 flex flex-row'>
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
            <div class='ml-auto'>
              <span class='playlist-badge'>{{ radioStation.name }}</span>
            </div>
          </div>
        </div>

        <div class='flex flex-col my-2'>
          <div class='my-2'>
            <!-- Song -->
            <div v-if='loading'>
              <LoadingBar />
            </div>
            <div>
              <span>{{ song.title }}</span>
            </div>
            <!-- Artist -->
            <div v-if='loading'>
              <LoadingBar />
            </div>
            <div>
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
  import { useModalStore } from '../../stores/modal';

  export default {
    props: ['item', 'song', 'radioStation', 'artists'],
    components: { LoadingBar },
    data () {
      return {
        songArtworkUrl: null,
        loading: true,
        spotifyLogo: null,
        lpIcon: null
      }
    },
    methods: {
      handleClickCard(event) {
        if (event.target.classList.contains('spotify-btn')) { return }

        const modalStore = useModalStore();
        modalStore.$patch({
          song: this.song,
          artists: this.artists,
          showModal: true
        })
      },
      handleClickSpotifyBtn() {
        window.open(this.song.spotify_song_url, '_blank')
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
      artistName() {
        return this.artists.map(artist => artist.name ).join(' - ')
      },
      getSpotifyImage() {
        this.spotifyLogo = document.getElementById('section-1').getAttribute('data-spotify-logo-url')
      },
      getLpIcon() {
        this.lpIcon = document.getElementById('section-1').getAttribute('data-lp-icon')
      }
    },
    mounted: function() {
      this.getSpotifyImage()
      this.getLpIcon()
    }
  }
</script>
