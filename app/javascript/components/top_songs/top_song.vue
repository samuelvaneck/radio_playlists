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
        <div v-if='!!artist' class='my-2'>
          <div><small><i>{{ artist.data.attributes.name }}</i></small></div>
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
      },
      getValues() {
        const artistUrl = '/artists/' + this.song.artist_id
        const options = {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json;charset=UTF-8'
          }
        }

        fetch(artistUrl, options).then(res => res.json())
          .then(d => this.artist = d)
      } 
    },
    mounted: function() {
      this.getValues()
    }
  }
</script>