# jQuery Turbolinks

[![Build Status](https://secure.travis-ci.org/kossnocorp/jquery.turbolinks.png?branch=master)](http://travis-ci.org/kossnocorp/jquery.turbolinks)

Do you like [Turbolinks](https://github.com/rails/turbolinks)? It's easy and fast way to improve user experience of surfing on your website.

But if you have a large codebase with lots of `$(el).bind(...)` Turbolinks will surprise you. Most part of your JavaScripts will stop working in usual way. It's because the nodes on which you bind events no longer exist.

I wrote jquery.turbolinks to solve this problem in [my project](http://amplifr.com). It's easy to use: just require it *immediately after* `jquery.js`. Your other scripts should be loaded after `jquery.turbolinks.js`, and `turbolinks.js` should be after your other scripts.

Initially sponsored by [Evil Martians](http://evilmartians.com/).

This project is a member of the [OSS Manifesto](http://ossmanifesto.org/).

## Important

This readme points to the latest version (v2.x) of jQuery Turbolinks, which 
features new 2.0 API. For older versions, see [v1.0.0rc2 README][oldreadme].

## Usage

Gemfile:

``` js
gem 'jquery-turbolinks'
```

Add it to your JavaScript manifest file, in this order:

``` js
//= require jquery
//= require jquery.turbolinks
//= require jquery_ujs
//
// ... your other scripts here ...
//
//= require turbolinks
```

And it just works!

**Checkout "[Faster page loads with Turbolinks](https://coderwall.com/p/ypzfdw)" for deeper explanation how to use jQuery Turbolink in real world**.

## API and Customization

### $.turbo.use

By default, jQuery.Turbolinks is bound to [page:load] and [page:fetch]. To use 
different events (say, if you're not using Turbolinks), use:

``` js
$.turbo.use('pjax:start', 'pjax:end');
```

## $.turbo.isReady

You can check if the page is ready by checking `$.turbo.isReady`, which will be 
either `true` or `false` depending on whether the page is loading.

## Troubleshooting

### Events firing twice or more

If you find that some events are being fired multiple times after using jQuery Turbolinks, you may have been binding your `document` events inside a `$(function())` block. For instance, this example below can be a common occurrence and should be avoided:

``` javascript
/* BAD: don't bind 'document' events while inside $()! */
$(function() {
  $(document).on('click', 'button', function() { ... })
});
```

You should be binding your events outside a `$(function())` block. This will ensure that your events will only ever be bound once.

``` javascript
/* Good: events are bound outside a $() wrapper. */
$(document).on('click', 'button', function() { ... })
```

### Not working with `$(document).on('ready')`

jQuery Turbolinks doesn't support ready events bound via `$(document).on('ready', function)`. Instead, use `$(document).ready(function)` or `$(function)`.

``` javascript
// BAD: this will not work.
$(document).on('ready', function () { /* ... */ });

// OK: these two are guaranteed to work.
$(document).ready(function () { /* ... */ });
$(function () { /* ... */ });
```

## Changelog

This project uses [Semantic Versioning](http://semver.org/) for release numbering.

For changelog notes, checkout [releases page](https://github.com/kossnocorp/jquery.turbolinks/releases).

## Contributors

Initial idea and code by [@kossnocorp](http://koss.nocorp.me/), with special thanks to [@rstacruz](https://github.com/rstacruz) and other the project's [contributors](https://github.com/kossnocorp/jquery.turbolinks/graphs/contributors).

## License

[The MIT License](https://github.com/kossnocorp/jquery.turbolinks/blob/master/LICENSE.md)

[page:load]: https://github.com/rails/turbolinks/#events
[page:fetch]: https://github.com/rails/turbolinks/#events
[oldreadme]: https://github.com/kossnocorp/jquery.turbolinks/blob/v1.0.0.rc2/README.md


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/kossnocorp/jquery.turbolinks/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

