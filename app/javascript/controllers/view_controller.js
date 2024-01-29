import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  switchView() {
    const searchPath = document.getElementsByClassName("tab-btn active")[0].getAttribute("data-search-url");
    const view = document.getElementById('view-button').dataset.view;
    const value = document.getElementById('search-input').value;
    const params = { search_term: value, view: view };

    const url = searchPath + "?" + this.hashToUrlParameters(params);

    fetch(url, { headers: { Accept: 'text/vnd.turbo-stream.html' } })
        .then(response => response.text())
        .then(html => Turbo.renderStreamMessage(html))
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
