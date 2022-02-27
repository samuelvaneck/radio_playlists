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
          <!-- Song -->
          <div class='w-full my-1' v-if='loading'>
            <LoadingBar />
          </div>
          <div class='grow my-1' v-else-if='!!song'>
            <div>{{ song.data.attributes.title }}</div>
          </div>
          <!-- Artist -->
          <div class='w-full my-1' v-if='loading'>
            <LoadingBar />
          </div>
          <div class='grow my-1' v-else-if='!!artists'>
            <div><small><i>{{ artistsNames() }}</i></small></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import LoadingBar from '../application/loading_bar.vue'

  export default {
    props: ['song', 'counter', 'chartIdx'],
    data () {
      return {
        artists: [],
        songArtworkUrl: null,
        radioStation: null,
        loading: true,
        spotifyLogo: null,
        position: ''
      }
    },
    methods: {
      handleClickSpotifyBtn() {
        if (!!this.song.data.attributes.spotify_song_url) {
          window.open(this.song.data.attributes.spotify_song_url, '_blank')
        }
      },
      getValues() {
        const artistUrl = '/artists/' + this.song.data.attributes.artist_ids
        const options = {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json;charset=UTF-8'
          }
        }

        fetch(artistUrl, options).then(res => res.json())
          .then(d => {
            this.artist = d
            this.loading = false

            for(let artist of this.song.data.relationships.artists.data) {
              const artistUrl = '/artists/' + artist.id
              fetch(artistUrl, options).then(res => res.json())
                .then(d => this.artists.push(d))
            }
          })
      },
      artistsNames() {
        return this.artists.map(artist => artist.data.attributes.name ).join(' - ')
      },
      getSpotifyImage() {
        this.spotifyLogo = document.getElementById('section-1').getAttribute('data-spotify-logo-url');
      },
      getChartPosition() {
        const url = '/charts/' + this.song.data.attributes.id + '/?chart_type=songs';
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
      this.getValues()
      this.getSpotifyImage();
      this.getChartPosition();
    },
    components: { LoadingBar }
  }
</script>
