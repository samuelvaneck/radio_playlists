<template>
  <div v-if='warning'>
    <input type="radio" class="btn-check" name="options" id="option1" autocomplete="off" style='postion:absolute;display:none'>
    <label class="status-button-warning" for="option1">{{ item.name }}</label>
  </div>
  <div v-else>
    <input type="radio" class="btn-check" name="options" id="option1" autocomplete="off" style='position:absolute;display:none'>
    <label class="status-button-ok" for="option1">{{ item.name }}</label>
  </div>
</template>

<script>
  export default {
    props: ['item'],
    data() {
      return {
        warning: false
      }
    },
    mounted: function() {
      this.warning = this.item.status == 'warning'
    }
  }
</script>
