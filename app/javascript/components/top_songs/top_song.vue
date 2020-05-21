<template>
  <div class='card mx-1 playlist-card' v-on:click='handleClickPlaylistItem'>
    <span><img :src='song.spotify_artwork_url' class='card-img-top' /></span>
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
        <div>{{ song.title }}</div>
        <div class='my-2'>
          <div><small><i>{{ song.artist_name }}</i></small></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    props: ['song', 'counter', 'chartIdx'],
    data () {
      return {
        artist: null,
        songArtworkUrl: null,
        radioStation: null
      }
    },
    methods: {
      handleClickPlaylistItem() {
        if (!!this.song.spotify_song_url) {
          window.open(this.song.spotify_song_url, '_blank')
        }
      } 
    }
  }
</script>