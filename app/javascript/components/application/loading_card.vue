<template>
  <div class='card playlist-card mx-1' style='min-width:190px'>
    <span class='card-img-top'>
      <LoadingBar v-bind:height='"190px"' v-bind:width='"90%"' />
    </span>
    <div class='card-body'>
      <div class='d-flex flex-row'>
        <LoadingBar />
        <LoadingBar />
      </div>
      <div><LoadingBar /></div>
      <div><LoadingBar /></div>
    </div>
  </div>
</template>

<script>
  import LoadingBar from './loading_bar.vue'
  export default {
    components: { LoadingBar }
  }
</script>