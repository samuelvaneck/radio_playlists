<template>
  <div class='d-flex flex-row'>
    <div>
      <select class='form-control' v-on:change='onChangeRadioStation'>
        <option value=''>All station</option>
        <option v-for='radioStation in radioStations' :value='radioStation.attributes.id'>{{ radioStation.attributes.name }}</option>
      </select>
    </div>
    <div class='ml-1'>
      <input class='form-control' v-on:keyup='onKeyUpSearch' placeholder='Search...' />
    </div>
  </div>
</template>

<script>
  export default {
    props: ['searchPath'],
    data() {
      return {
        radioStations: []
      }
    },
    computed: {
      showFilterRadioStation() {
        false
      }
    },
    methods: {
      onKeyUpSearch(event) {
        this.$emit('search', event.target.value)
      },
      onChangeRadioStation(event) {
        this.$emit('filter', event.target.value)
      }
    },
    created() {
      const url = '/radiostations'
      const options = {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json;charset=UTF-8'
        }
      }
      fetch(url, options).then(res => res.json())
        .then(d => this.radioStations = d.data)
    }
  }
</script>