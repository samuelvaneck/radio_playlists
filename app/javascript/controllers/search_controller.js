import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  initialize() {
    this.submit()
  }

  submit() {
    let timeoutId;
    // Clear the previous timeout, if any
    clearTimeout(timeoutId);

    // Set a new timeout to wait for half a second before making the fetch request
    timeoutId = setTimeout(async () => {
      const searchPath = document.getElementsByClassName("tab-btn active")[0].getAttribute("data-search-url");
      const value = document.getElementById('search-input').value;
      const view = document.getElementById('view-button').dataset.current;
      const params = { search_term: value, view: view };
      const url = searchPath + "?" + this.hashToUrlParameters(params);

      

      fetch(url, { headers: { Accept: 'text/vnd.turbo-stream.html' } })
          .then(response => response.text())
          .then(html => Turbo.renderStreamMessage(html))
    }, 500)
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
}
