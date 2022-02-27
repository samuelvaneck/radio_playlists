<template>
  <div class='wrapper wrapperAnime'>
    <div class='header'>
      <div class='imageWrapper'>
        <span v-if='loading'>

        </span>
        <span v-else-if='!!artist'>
          <img :src='spotifyArtworkUrl' class='image' />
        </span>
      </div>
      <div class='badgeWrapper'>
        <div class='primaryBadge badgeAnime'>
          <div v-if='!!artist && !!artist.data.attributes.spotify_artist_url' class='mt-2 d-flex flex-row'>
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
          <div>
            <span class='bungee'># {{ chartIdx + 1 }}</span>
            <span class='playlist-badge'>{{ this.position }}</span>
          </div>
          <div class='float-right'>
            <span class='playlist-badge'>{{ counter }} x</span>
          </div>
        </div>
        <div class='flex flex-col my-2'>
          <div v-if='loading'>
            <LoadingBar />
          </div>
          <div v-else-if='!!artist'>
            <span>{{ artist.data.attributes.name }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import LoadingBar from '../application/loading_bar.vue'

  export default {
    props: ['artist', 'counter', 'chartIdx'],
    components: { LoadingBar },
    data () {
      return {
        // artist: null,
        spotifyArtworkUrl: null,
        loading: true,
        spotifyLogo: null,
        position: ''
      }
    },
    methods: {
      handleClickSpotifyBtn() {
        if (!!this.artist.data.attributes.spotify_artist_url) {
          window.open(this.artist.data.attributes.spotify_artist_url, '_blank')
        }
      },
      setSpotifyArtworkUrl: function() {
         if (!!this.artist.data.attributes.spotify_artwork_url) {
          this.spotifyArtworkUrl = this.artist.data.attributes.spotify_artwork_url
        }
        this.loading = false
      },
      getSpotifyImage() {
        this.spotifyLogo = document.getElementById('section-1').getAttribute('data-spotify-logo-url');
      },
      getChartPosition() {
        const url = '/charts/' + this.artist.data.attributes.id + '/?chart_type=artists';
        const options = {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json;charset=UTF-8'
          }
        }

        fetch(url, options).then(res => res.json())
          .then(d => {
            if (d.last_week_position === -1 && d.yesterdays_position === -1) {
              this.position = '?';
            } else if (d.last_week_position === -1) {
              this.position = '+' + d.yesterdays_position
            } else if (d.yesterdays_position === -1) {
              this.position = '?';
            } else {
              const changePositions = d.last_week_position - d.yesterdays_position;
              if (Math.sign(changePositions) === 1) {
                this.position = '+' + (changePositions);
              } else {
                this.position = changePositions;
              }
            }
          });
      }
    },
    mounted: function() {
      this.setSpotifyArtworkUrl()
      this.getSpotifyImage()
      this.getChartPosition()
    }
  }
</script>
