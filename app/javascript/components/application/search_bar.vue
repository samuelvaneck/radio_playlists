<template>
  <div class='d-flex flex-column'>
    <div class='d-flex flex-row justify-content-end'>
      <div class='d-flex flex-column align-self-center justify-content-center'>
        <div class='py-2 px-3' v-on:click='onClickTimeFilterBtn'>
          <svg class="bi bi-clock-history" width="1.5em" height="1.5em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
            <path fill-rule="evenodd" d="M8.515 1.019A7 7 0 0 0 8 1V0a8 8 0 0 1 .589.022l-.074.997zm2.004.45a7.003 7.003 0 0 0-.985-.299l.219-.976c.383.086.76.2 1.126.342l-.36.933zm1.37.71a7.01 7.01 0 0 0-.439-.27l.493-.87a8.025 8.025 0 0 1 .979.654l-.615.789a6.996 6.996 0 0 0-.418-.302zm1.834 1.79a6.99 6.99 0 0 0-.653-.796l.724-.69c.27.285.52.59.747.91l-.818.576zm.744 1.352a7.08 7.08 0 0 0-.214-.468l.893-.45a7.976 7.976 0 0 1 .45 1.088l-.95.313a7.023 7.023 0 0 0-.179-.483zm.53 2.507a6.991 6.991 0 0 0-.1-1.025l.985-.17c.067.386.106.778.116 1.17l-1 .025zm-.131 1.538c.033-.17.06-.339.081-.51l.993.123a7.957 7.957 0 0 1-.23 1.155l-.964-.267c.046-.165.086-.332.12-.501zm-.952 2.379c.184-.29.346-.594.486-.908l.914.405c-.16.36-.345.706-.555 1.038l-.845-.535zm-.964 1.205c.122-.122.239-.248.35-.378l.758.653a8.073 8.073 0 0 1-.401.432l-.707-.707z"/>
            <path fill-rule="evenodd" d="M8 1a7 7 0 1 0 4.95 11.95l.707.707A8.001 8.001 0 1 1 8 0v1z"/>
            <path fill-rule="evenodd" d="M7.5 3a.5.5 0 0 1 .5.5v5.21l3.248 1.856a.5.5 0 0 1-.496.868l-3.5-2A.5.5 0 0 1 7 9V3.5a.5.5 0 0 1 .5-.5z"/>
          </svg>
        </div>
      </div>
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
    <transition name='fade'>
      <div v-if='showTimeFilters' class='time-filters d-flex flex-row justify-content-end mt-1'>
        <div>
          Start date
          <input type='datetime-local' 
                 name='start_date' 
                 class='form-control' 
                 :value='startDateFilter' 
                 v-on:change='onChangeStartTime'
                 :max='setMaxTimeFilter' />
        </div>
        <div>
          End date
          <input type='datetime-local' 
                 name='end_date' 
                 class='form-control ml-1' 
                 :value='endDateFilter' 
                 v-on:change='onChangeEndtTime'
                 :max='setMaxTimeFilter' />
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
  export default {
    props: ['searchPath'],
    data() {
      return {
        radioStations: [],
        showTimeFilters: false
      }
    },
    computed: {
      showFilterRadioStation() {
        false
      },
      startDateFilter() {
        // return format: "YYYY-MM-DDTHH:MM"
        let startDate = new Date()
        startDate.setTime(startDate.getTime() - startDate.getTimezoneOffset()*60*1000)
        startDate.setDate(startDate.getDate() - 7)
        const startDateStr = startDate.toISOString()
        return startDateStr.substring(0, startDateStr.length-8)
      },
      endDateFilter() {
        // return format: "YYYY-MM-DDTHH:MM"
        const endDate = new Date()
        endDate.setTime(endDate.getTime() - endDate.getTimezoneOffset()*60*1000)
        const endDateStr = endDate.toISOString()
        return endDateStr.substring(0, endDateStr.length-8)
      },
      setMaxTimeFilter() {
        const maxDate = new Date()
        const maxDateStr = maxDate.toISOString()
        return maxDateStr.substring(0, maxDateStr.length-8)
      }
    },
    methods: {
      onKeyUpSearch(event) {
        this.$emit('search', event.target.value)
      },
      onChangeRadioStation(event) {
        this.$emit('filter', event.target.value)
      },
      onClickTimeFilterBtn(event) {
        this.showTimeFilters = !this.showTimeFilters
      },
      onChangeStartTime(event) {
        this.$emit('filterTime', event.target.value, 'start')
      },
      onChangeEndtTime(envet) {
        this.$emit('filterTime', event.target.value, 'end')
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