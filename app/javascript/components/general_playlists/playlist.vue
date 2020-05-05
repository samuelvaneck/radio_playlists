<template>
  <div class='card mx-1' style='width:18rem;'>
    <span v-if='!!song'><img :src='song.data.attributes.spotify_artwork_url' class='card-img-top' /></span>
    <div class='card-body'>
      <div class='d-flex flex-column'>
        <div class='d-flex d-flex-row'>
          <div class='rubik'>{{ item.attributes.time }}</div>
          <div v-if='!!radioStation' class='ml-auto'>
            <span class='badge badge-secondary'>{{ radioStation.data.attributes.name }}</span>
          </div>
        </div>
        <div v-if='!!song && !!artist' class='my-2'>
          <span>{{ artist.data.attributes.name }} -  {{ song.data.attributes.title }}</span>
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
        radioStation: null
      }
    },
    created: function() {
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
        .then(d => { this.song = d })

      fetch(radioStationUrl, options).then(res => res.json())
        .then(d => this.radioStation = d)
    }
  }
</script>