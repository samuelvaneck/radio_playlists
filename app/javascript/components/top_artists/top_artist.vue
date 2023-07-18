<template>
  <div class='wrapper wrapperAnime' @click="handleClickCard">
    <div class='header'>
      <div class='imageWrapper'>
        <span v-if='loading'></span>
        <span v-else-if='!!artist'>
          <img :src='spotifyArtworkUrl' class='image' />
        </span>
      </div>
      <div v-if='!!artist && !!artist.data.attributes.spotify_artist_url' class='badgeWrapper'>
        <div class='primaryBadge badgeAnime'>
          <div class='mt-2 d-flex flex-row'>
            <img :src='spotifyLogo' class='spotify-btn' v-on:click='handleClickSpotifyBtn' />
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
  import { useModalStore } from '../../stores/modal';

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
      handleClickCard(event) {
        if (event.target.classList.contains('spotify-btn')) { return }

        const modalStore = useModalStore();
        modalStore.$patch({
          artist: this.artist.data.attributes,
          showModal: true
        })
      },
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
            if (d.historic_position === -1) {
              this.position = '?';
            } else {
              const changedPositions = d.historic_position - this.chartIdx;
              if(changedPositions === 0) {
                this.position = '=';
              } else if (Math.sign(changedPositions) === 1) {
                this.position = '+' + (changedPositions);
              } else {
                this.position = changedPositions;
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
