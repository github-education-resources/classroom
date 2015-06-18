With the Rails asset pipeline or other asset packagers, you
usually include the JS for your entire application in one bundle,
while individual scripts should be run only on certain pages.

jquery.readyselector extends `.ready()` to provide a nice syntax
for page-specific script:

```javascript
$('.posts.index').ready(function () {
  // ...
});
```

This works well if you include the controller name and action
as `<body>` element classes, a la:
 http://postpostmodern.com/instructional/a-body-with-class/

The callback will be run once for each matching element, with
the usual 'this' context for a jQuery callback. `$(fn)`,
`$(document).ready(fn)`, and `$().ready(fn)` behave as normal.
