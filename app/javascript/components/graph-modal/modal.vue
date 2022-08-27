<!-- This example requires Tailwind CSS v2.0+ -->
<template>
  <div v-if='showing'>
    <div class="fixed inset-0  backdrop-blur-sm bg-gray-500 bg-opacity-50 transition-opacity" />

    <div class="fixed z-10 inset-0 overflow-y-auto">
      <div class="flex items-center sm:items-center justify-center min-h-full p-4 text-center sm:p-0">
        <div as="template" enter="ease-out duration-300" enter-from="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95" enter-to="opacity-100 translate-y-0 sm:scale-100" leave="ease-in duration-200" leave-from="opacity-100 translate-y-0 sm:scale-100" leave-to="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95">
          <div class="relative bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:max-w-lg sm:w-full">
            <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
              <div class="sm:flex sm:items-start">
                <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10">
                  <img v-if="!!song" :src='this.song.spotify_artwork_url' />
                  <img v-if="!!artist" :src='this.artist.spotify_artwork_url' />
                </div>
                <div v-if="!!song" class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                  <h3>{{ this.song.title }}</h3>
                  <h5 class="text-gray-500">{{ artistsNames() }}</h5>
                </div>
                <div v-if="!!artist" class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                  <h3>{{ this.artist.name }}</h3>
                </div>
              </div>
              <GraphButtons @clickGraphButton="handleClickGraphButton" />
              <div class="sm:flex sm:items-start mt-2">
                <Graph v-if="!!song" v-bind:object="song" />
                <Graph v-if="!!artist" v-bind:object="artist" />
              </div>
            </div>
            <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
              <button type="button" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm" v-on:click="close">Close</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import GraphButtons from './graph_buttons.vue'
  import Graph from './graph'
  import { useModalStore } from '../../stores/modal'

  export default {
    components: { Graph, GraphButtons },
    data() {
      return {
        song: null,
        artists: null,
        artist: null,
        showing: false
      }
    },
    methods: {
      artistsNames() {
        return this.artists.map(artist => artist.name ).join(' - ')
      },
      close() {
        const modalStore = useModalStore();

        this.showing = false
        modalStore.$patch({
          song: null,
          artists: null,
          artist: null,
          showModal: false
        })
        document.getElementById('graph').getElementsByTagName('svg')[0].innerHTML = ''
        document.getElementById('legend').getElementsByTagName('svg')[0].innerHTML = ''
      },
      handleClickGraphButton(value) {
        console.log(value);
      }
    },
    // method that watches for changes on the artist and song stores
    watch: {
      artist() {
        // console.log(this.artists)
      },
      song() {
        // console.log(this.song)
      }
    },
    mounted() {
      const modalStore = useModalStore()
      modalStore.$subscribe((mutation, state) => {
        this.song = state.song,
        this.artists = state.artists,
        this.artist = state.artist,
        this.showing = state.showModal;
      })
    }
  }
</script>
