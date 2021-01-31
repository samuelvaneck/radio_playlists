<template>
  <div v-if='warning'>
    <input type="radio" class="btn-check" name="options" id="option1" autocomplete="off" style='postion:absolute;display:none'>
    <label class="btn btn-outline-danger mx-1" for="option1">{{ item.name }}</label>
  </div>
  <div v-else>
    <input type="radio" class="btn-check" name="options" id="option1" autocomplete="off" style='position:absolute;display:none'>
    <label class="btn btn-outline-success mx-1" for="option1">{{ item.name }}</label>
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
      console.log(this.item.status)
      this.warning = this.item.status == 'warning'
    }
  }
</script>
