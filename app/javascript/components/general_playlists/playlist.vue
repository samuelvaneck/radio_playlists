<template>
  <li class='collection-item'>
    <div class='row'>
      <div class='col s12'>
        {{ song }}
      </div>
      <div class='col s12'>
        {{ item.attributes.time }}
        {{ artist }}
        {{ radioStation }}
      </div>
      <div class='col s12'>
        {{ item }}
      </div>
    </div>
  </li>
</template>

<script>
  export default {
    props: ['item'],
    data () {
      return {
        artist: null,
        song: null,
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

      // fetch(songUrl, options).then(res => res.json())
      //   .then(d => this.song = d)

      fetch(radioStationUrl, options).then(res => res.json())
        .then(d => this.radioStation = d)
    }
  }
</script>