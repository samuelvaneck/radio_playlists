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
import './application.scss'

import Vue from 'vue/dist/vue.esm'
import StatusBar from './components/status_bar/status_bar'
import PlaylistBar from './components/general_playlists/playlist_bar.vue'
import TopSongBar from './components/top_songs/top_song_bar.vue'
import TopArtistBar from './components/top_artists/top_artist_bar.vue'

Vue.component('statusBar', StatusBar)
Vue.component('playlistBar', PlaylistBar)
Vue.component('topSongBar', TopSongBar)
Vue.component('topArtistBar', TopArtistBar)

document.addEventListener('DOMContentLoaded', () => {
  let elements = document.querySelectorAll('[data-behaviour="vue"]')
  for (let element of elements) {
    const app = new Vue({
      el: element,
    })
  }
})

//
const files = require.context('./', true, /\.vue$/i)
files.keys().map(key => {
  const component = key.split('/').pop().split('.')[0]

  // With Lazy Loading
  Vue.component(component, () => import(`${key}`))

  // Or without Lazy Loading
  Vue.component(component, files(key).default)
})
