# &lt;include-fragment&gt; element

A Client Side Includes tag.


## Installation

Available on [Bower](http://bower.io) as **include-fragment-element**.

```
$ bower install include-fragment-element
```

This component is built on the [Web Component](http://webcomponents.org/) stack. Specifically, it requires a feature called [Custom Elements](http://www.html5rocks.com/en/tutorials/webcomponents/customelements/). You'll need to use a polyfill to get this feature today. Either the [Polymer](http://www.polymer-project.org/) or [X-Tag](http://www.x-tags.org/) frameworks supply a polyfill, or you can install the standalone [CustomElements](https://github.com/Polymer/CustomElements) polyfill.

``` html
<script src="https://cdnjs.cloudflare.com/ajax/libs/polymer/0.3.4/platform.js"></script>
```

## Usage

All `include-fragment` elements must have a `src` attribute from which to retrieve an HTML element fragment.

The initial page load should include fallback content to be displayed if the resource could not be fetched immediately.

**Original:**

``` html
<div class="tips">
  <include-fragment src="/tips">
    <p>Loading tip…</p>
  </include-fragment>
</div>
```

On page load, the `include-fragment` element fetches the URL, the response is parsed into an HTML element, which replaces the `include-fragment` element entirely.

**Result:**

``` html
<div class="tip">
  <p>You look nice today</p>
</div>
```

The server must respond with an HTML fragment to replace the `include-fragment` element. It should not contain _another_ `include-fragment` element or the server will be polled in an infinite loop.

### Errors

If the URL fails to load, the `include-fragment` element is left in the page and tagged with an `is-error` CSS class that can be used for styling.

### Options

Attribute      | Options                        | Description
---            | ---                            | ---
`src`          | URL string                     | Required URL from which to load the replacement HTML element fragment.

## Patterns

Deferring the display of markup is typically done in the following usage patterns.

- A user action begins a slow running background job on the server, like backing up files stored on the server. While the backup job is running, a progress bar is shown to the user. When it's complete, the include-fragment element is replaced with a link to the backup files.

- The first time a user visits a page that contains a time-consuming piece of markup to generate, a loading indicator is displayed. When the markup is finished building on the server, it's stored in memcache and sent to the browser to replace the include-fragment loader. Subsequent visits to the page render the cached markup directly, without going through a include-fragment element.


## Relation to Server Side Includes

This declarative approach is very similar to [SSI](http://en.wikipedia.org/wiki/Server_Side_Includes) or [ESI](http://en.wikipedia.org/wiki/Edge_Side_Includes) directives. In fact, an edge implementation could replace the markup before its actually delivered to the client.

``` html
<include-fragment src="/github/include-fragment/commit-count" timeout="100">
  <p>Counting commits…</p>
</include-fragment>
```

A proxy may attempt to fetch and replace the fragment if the request finishes before the timeout. Otherwise the tag is delivered to the client. This library only implements the client side aspect.


## Browser Support

![Chrome](https://raw.github.com/alrra/browser-logos/master/chrome/chrome_48x48.png) | ![Firefox](https://raw.github.com/alrra/browser-logos/master/firefox/firefox_48x48.png) | ![IE](https://raw.github.com/alrra/browser-logos/master/internet-explorer/internet-explorer_48x48.png) | ![Opera](https://raw.github.com/alrra/browser-logos/master/opera/opera_48x48.png) | ![Safari](https://raw.github.com/alrra/browser-logos/master/safari/safari_48x48.png)
--- | --- | --- | --- | --- |
Latest ✔ | Latest ✔ | 9+ ✔ | Latest ✔ | 6.1+ ✔ |
