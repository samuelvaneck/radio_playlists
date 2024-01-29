<template>
  <div class='flex flew-row flex-nowrap overflow-x-scroll py-2 justify-center'>
    <div v-bind:key='item.id' v-for='item in items'>
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
