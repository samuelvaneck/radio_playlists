<template>
  <div class='card mx-1 playlist-card' v-on:click='handleClickPlaylistItem'>
    <span v-if='!!song'><img :src='song.data.attributes.spotify_artwork_url' class='card-img-top' /></span>
    <div class='card-body'>
      <div class='d-flex flex-column'>
        <div class='d-flex d-flex-row'>
          <div class='rubik mr-2'>
            <div>{{ item.attributes.time }}</div>
            <div><small><i>{{ playedDate() }}</i></small></div>
          </div>
          <div v-if='!!radioStation' class='ml-auto'>
            <span class='badge badge-secondary'>{{ radioStation.data.attributes.name }}</span>
          </div>
        </div>
        <div v-if='!!song && !!artist' class='my-2'>
          <span>{{ song.data.attributes.title }}</span>
          <div><small><i>{{ artist.data.attributes.name }}</i></small></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    props: ['item'],
    data () {
      return {
        artist: null,
        song: null,
        songArtworkUrl: null,
        radioStation: null,
      }
    },
    methods: {
      handleClickPlaylistItem() {
        if (!!this.song.data.attributes.spotify_song_url) {
          window.open(this.song.data.attributes.spotify_song_url, '_blank')
        }
      },
      playedDate() {
        const date = new Date(this.item.attributes.created_at)
        const dd = date.getDate()
        const mm = date.getMonth()+1
        const yyyy = date.getFullYear()

        return dd + '-' + mm + '-' + yyyy
      },
      getValue() {
        const attributes = this.item.attributes
        const artistUrl = '/artists/' + attributes.artist_id
        const songUrl = '/songs/' + attributes.song_id
        const radioStationUrl = '/radiostations/' + attributes.radiostation_id
        const options = {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json;charset=UTF-8'
          }
        }

        fetch(artistUrl, options).then(res => res.json())
          .then(d => this.artist = d)

        fetch(songUrl, options).then(res => res.json())
          .then(d => this.song = d)

        fetch(radioStationUrl, options).then(res => res.json())
          .then(d => this.radioStation = d)
      }
    },
    mounted: function() {
      this.getValue()
      // this.playedDate = this.convertTime(attributes.created_at)
    }
  }
</script>