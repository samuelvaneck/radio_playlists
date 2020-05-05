<template>
  <div>
    <span v-if='direction == "left"' class='nav-arrow left-arrow' v-on:click='scrollLeft'>
      <svg class="bi bi-chevron-compact-left" width="1em" height="1em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
        <path fill-rule="evenodd" d="M9.224 1.553a.5.5 0 01.223.67L6.56 8l2.888 5.776a.5.5 0 11-.894.448l-3-6a.5.5 0 010-.448l3-6a.5.5 0 01.67-.223z" clip-rule="evenodd"/>
      </svg>
    </span>
    <span v-else-if='direction == "right"' class='nav-arrow right-arrow' v-on:click='scrollRight'>
      <svg class="bi bi-chevron-compact-right" width="1em" height="1em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
        <path fill-rule="evenodd" d="M6.776 1.553a.5.5 0 01.671.223l3 6a.5.5 0 010 .448l-3 6a.5.5 0 11-.894-.448L9.44 8 6.553 2.224a.5.5 0 01.223-.671z" clip-rule="evenodd"/>
      </svg>
    </span>
  </div>
</template>

<script>
  export default {
    props: ['direction'],
    methods: {
      scrollLeft(event) {
        const row = event.target.closest('.d-flex').getElementsByClassName('row')[0]
        row.scrollLeft -= 100;
      },
      scrollRight(event) {
        const row = event.target.closest('.d-flex').getElementsByClassName('row')[0]
        row.scrollLeft += 100;
      }
    }
  }
</script>