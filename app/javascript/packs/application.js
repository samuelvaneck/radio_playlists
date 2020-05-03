/* eslint no-console:0 */
// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import 'core-js/stable'
import 'regenerator-runtime/runtime'
import Vue from 'vue/dist/vue.esm'

document.addEventListener('DOMContentLoaded', () => {
  let elements = document.querySelectorAll('[data-behaviour="vue"]')
  for (let element of elements) {
    const app = new Vue({
      el: element,
    })
  }
})

// 
const files = require.context('./', true, /\.vue$/i)
files.keys().map(key => {
  const component = key.split('/').pop().split('.')[0]

  // With Lazy Loading
  Vue.component(component, () => import(`${key}`))

  // Or without Lazy Loading
  Vue.component(component, files(key).default)
})