import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js";

// attaches an infinite-scroll listener on either a specific scrollable element or
// the entire window(<body>)

// if you want to attach the listener to the window, you can do this
// data-pagination-attach-to-body-value="true", then the listener will be attached on the window
// rather than the element.

// If you omit this option, the controller will attach the event listener-
// on the element that has the declaration
//<element data-controller="pagination">

// make sure to return a <element data-pagination-target="lastPage" /> in the turbo stream response
// to indicate that there are no more pages. Thus, no more requests being sent.

export default class extends Controller {
    static values = {
        url: String,
        page: Number,
        fetching: Boolean,
        lastScroll: Number
    };

    initialize() {
        this.scroll = this.scroll.bind(this);
        this.pageValue = this.pageValue || 1;
        this.fetching = false;
        this.lastScroll = 0;
    }

    connect() {
        document.addEventListener("scroll", this.scroll);
    }

    scroll(event) {
        if (this.scrollReachedEnd && !this.fetching && this.scrollDown(event)) {
            this.fetching = true
            this._fetchNewPage()
        }
    }

    async _fetchNewPage() {
        const value = document.getElementById('search-input').value;
        const view = document.getElementById('view-button').dataset.current;
        const url = new URL(this.urlValue);
        url.searchParams.set('page', this.pageValue);
        url.searchParams.set('search_term', value)
        url.searchParams.set('view', view)

        await get(url.toString(), {
            responseKind: 'turbo-stream'
        })

        this.pageValue +=1;
        setTimeout(this.fetching = false, 500)
    }

    get scrollReachedEnd() {
        const { scrollHeight, scrollTop, clientHeight } = this.element;
        const distanceFromBottom = scrollHeight - scrollTop - clientHeight;

        return distanceFromBottom < 20;
    }

    scrollDown(event) {
        const st = this.element.scrollTop
        const value = st > this.lastScroll

        this.lastScroll = st <= 0 ? 0 :st
        return value
    }
}
