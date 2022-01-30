<template>
  <span
    :style="{ height, width: computedWidth }"
    class="loading-bar" />
</template>

<script>
  export default {
    name: 'LoadingBar',
    props: {
      maxWidth: {
        default: 100,
        type: Number
      },
      minWidth: {
        default: 80,
        type: Number
      },
      height: {
        default: '1em',
        type: String
      },
      width: {
        default: null,
        type: String
      }
    },
    computed: {
      computedWidth() {
        return this.width || `${Math.floor((Math.random() * (this.maxWidth - this.minWidth)) + this.minWidth)}%`;
      }
    }
  }
</script>
