<template>
  <div class="flex flex-col">
    <div><span class='text-xl'>Status</span></div>
    <div class='float-right'>
      <StatusGroup v-bind:items='items' />
    </div>
  </div>
</template>

<script>
  import StatusGroup from './status_group'

  export default {
    data() {
      return {
        items: []
      }
    },
    components: { StatusGroup },
    methods: {
      getStatus: function() {
        const options = {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json;charset=UTF-8'
          }
        }
        fetch('/radio_stations', options).then(res => res.json())
          .then(d => {
            d.data.forEach(radioStation => {
              let url = '/radio_stations/' + radioStation.id + '/status'

              fetch(url, options).then(status => status.json())
                .then(di => this.items.push(di))
            });
          })
      }
    },
    created: function() {
      this.getStatus()
    }
  }
</script>
