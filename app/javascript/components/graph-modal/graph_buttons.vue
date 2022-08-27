<template>
  <div class="flex sm:items-start mt-2">
    <button class="grow graph-button" @click="handleClickButton">Day</button>
    <button class="grow graph-button button-active" @click="handleClickButton">Week</button>
    <button class="grow graph-button" @click="handleClickButton">Month</button>
    <button class="grow graph-button">Year</button>
    <button class="grow graph-button">All</button>
  </div>
</template>

<script>
  export default {
    methods: {
      handleClickButton(event) {
        const clickedButton = event.target;
        const buttons = document.getElementsByClassName('graph-button');
        for (let button of buttons) {
          button.classList.remove('button-active');
        }
        clickedButton.classList.add('button-active');
        this.$emit('clickGraphButton', clickedButton.innerHTML.toLowerCase())
      }
    }
  }
</script>
