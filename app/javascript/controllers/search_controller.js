import { Controller } from "@hotwired/stimulus"
import debounce from "debounce";

// Connects to data-controller="search"
export default class extends Controller {
  initialize() {
    this.submit = debounce(this.submit.bind(this), 500);
    this.submit()
  }

  submit() {
    const searchPath = document.getElementsByClassName("tab-btn active")[0].getAttribute("data-search-url");
    const value = document.getElementById('search-input').value;
    const view = document.getElementById('view-button').dataset.current;
    const params = { search_term: value, view: view };
    const url = searchPath + "?" + this.hashToUrlParameters(params);

    this.showLoader();
    fetch(url, { headers: { Accept: 'text/vnd.turbo-stream.html' } })
        .then(response => response.text())
        .then(html => Turbo.renderStreamMessage(html))
        .then(this.hideLoader)
  }

  hashToUrlParameters(hash) {
    const params = [];

    for (const key in hash) {
      if (hash.hasOwnProperty(key)) {
        const encodedKey = encodeURIComponent(key);
        const encodedValue = encodeURIComponent(hash[key]);
        params.push(`${encodedKey}=${encodedValue}`);
      }
    }

    return params.join('&');
  }

  showLoader() {
    const loader = document.getElementById('loader')
    loader.classList.remove('hidden');
  }

  hideLoader() {
    const loader = document.getElementById('loader')
    loader.classList.add('hidden');
  }
}
