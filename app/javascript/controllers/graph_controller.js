import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="graph"
export default class extends Controller {
  static value = {
    songId: Number
  }
  connect() {

  }

  openModal() {
    this.songId = this.element.dataset.graphIdValue;
    const modal = document.getElementById('graph-modal')
    modal.classList.remove('hidden')
  }
}
