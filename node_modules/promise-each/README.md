# promise-each
[![NPM version][npm-image]][npm-url]
[![build status][travis-image]][travis-url]
[![Test coverage][coveralls-image]][coveralls-url]
[![Downloads][downloads-image]][downloads-url]

Call a function [for each][mdn] value in an array and return a [Promise][promise].
Should only be used for side effects. Waits for promises to resolve before
proceeding to the next value.

## Installation
```bash
$ npm install promise-each
```

## Usage
```js
const each = require('promise-each')

Promise.resolve([1, 2, 3])
  .then(each((val) => console.log(val)))
// => 1
// => 2
// => 3
```

## Why?
This module is basically equivalent to [`bluebird.each`][bluebird], but it's
handy to have the one function you need instead of a kitchen sink. Modularity!
Especially handy if you're serving to the browser and need to reduce your
javascript bundle size.

Works great in the browser with
[browserify](http://github.com/substack/node-browserify)!

## See Also
- [promise-every](https://github.com/yoshuawuyts/promise-every)
- [promise-filter](https://github.com/yoshuawuyts/promise-filter)
- [promise-map](https://github.com/yoshuawuyts/promise-map)
- [promise-reduce](https://github.com/yoshuawuyts/promise-reduce)
- [promise-some](https://github.com/yoshuawuyts/promise-some)

## License
[MIT](https://tldrlegal.com/license/mit-license)

[npm-image]: https://img.shields.io/npm/v/promise-each.svg?style=flat-square
[npm-url]: https://npmjs.org/package/promise-each
[travis-image]: https://img.shields.io/travis/yoshuawuyts/promise-each.svg?style=flat-square
[travis-url]: https://travis-ci.org/yoshuawuyts/promise-each
[coveralls-image]: https://img.shields.io/coveralls/yoshuawuyts/promise-each.svg?style=flat-square
[coveralls-url]: https://coveralls.io/r/yoshuawuyts/promise-each?branch=master
[downloads-image]: http://img.shields.io/npm/dm/promise-each.svg?style=flat-square
[downloads-url]: https://npmjs.org/package/promise-each

[mdn]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/each
[promise]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
[bluebird]: https://github.com/petkaantonov/bluebird/blob/master/API.md#eachfunction-iterator---promise
