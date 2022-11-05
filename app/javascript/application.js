/* eslint no-console:0 */
// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import "@hotwired/turbo-rails"

import 'core-js/stable'
import 'regenerator-runtime/runtime'
import './stylesheets/application.scss'

import { createApp } from 'vue/dist/vue.esm-bundler.js'
import { createPinia } from 'pinia'
import StatusBar from './components/status_bar/status_bar'
import PlaylistBar from './components/playlists/playlist_bar.vue'
import TopSongBar from './components/top_songs/top_song_bar.vue'
import TopArtistBar from './components/top_artists/top_artist_bar.vue'
import GraphModal from './components/graph-modal/modal.vue'

document.addEventListener('DOMContentLoaded', () => {
  const app = createApp(document.getElementById('app'));
  const pinia = createPinia();
  app.use(pinia);
  app.component('statusBar', StatusBar);
  app.component('playlistBar', PlaylistBar);
  app.component('topSongBar', TopSongBar);
  app.component('topArtistBar', TopArtistBar);
  app.component('graphModal', GraphModal);
  app.mount('#app');
})
