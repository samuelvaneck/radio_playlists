<template>
  <div class='row flex-nowrap overflow-x-auto py-2'>
    <div class='d-flex flex-row' v-bind:key='item.id' v-for='item in items'>
      <Status v-bind:item='item' />
    </div>
  </div>
</template>

<script>
  import Status from './status.vue'
  export default {
    props: ['items'],
    components: { Status }
  }
</script>
