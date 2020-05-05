<template>
  <div class='card mx-1 playlist-card' v-on:click='handleClickPlaylistItem'>
    <span v-if='!!song'><img :src='song.data.attributes.spotify_artwork_url' class='card-img-top' /></span>
    <div class='card-body'>
      <div class='d-flex flex-column'>
        <div class='d-flex d-flex-row'>
          <div class='bungee-inline'>
            # {{ chartIdx }}
          </div>
          <div class='ml-auto'>
            <span class='badge badge-secondary'>{{ counter }} x</span>
          </div>
        </div>
        <div v-if='!!song && !!artist' class='my-2'>
          <span>{{ artist.data.attributes.name }} - {{ song.data.attributes.title }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    props: ['id', 'counter', 'chartIdx'],
    data () {
      return {
        artist: null,
        song: null,
        songArtworkUrl: null,
        radioStation: null
      }
    },
    methods: {
      handleClickPlaylistItem() {
        if (!!this.song.data.attributes.spotify_song_url) {
          window.open(this.song.data.attributes.spotify_song_url, '_blank')
        }
      } 
    },
    created: function() {
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
            .then(d => this.artist = d)
        })
    }
  }
</script>