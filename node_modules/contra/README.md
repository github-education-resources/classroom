![contra.png][logo]

[![badge](https://travis-ci.org/bevacqua/contra.png?branch=master)](https://travis-ci.org/bevacqua/contra) [![badge](https://badge.fury.io/js/contra.png)](http://badge.fury.io/js/contra) [![badge](https://badge.fury.io/bo/contra.png)](http://badge.fury.io/bo/contra) [![help me on gittip](http://gbindex.ssokolow.com/img/gittip-43x20.png)](https://www.gittip.com/bevacqua/) [![flattr.png](https://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=nzgb&url=https%3A%2F%2Fgithub.com%2Fbevacqua%2Fcontra)

> Asynchronous flow control with a functional taste to it

`λ` aims to stay small and simple, while powerful. Inspired by [async][1] and [lodash][2]. Methods are implemented individually and not as part of a whole. That design helps when considering to export functions individually. If you need all the methods in `async`, then stick with it. Otherwise, you might want to check `λ` out!

Feature requests will be considered on a case-by-case basis.

#### Quick Links

- [CHANGELOG](CHANGELOG.md)
- [Comparison with `async`](#comparison-with-async)
- [Browser Support](#browser-support)
- [License](#License)

#### API

Flow Control

- [`λ.waterfall`](#%CE%BBwaterfalltasks-done)
- [`λ.series`](#%CE%BBseriestasks-done)
- [`λ.concurrent`](#%CE%BBconcurrenttasks-cap-done)

Functional

- [`λ.each`](#%CE%BBeachitems-cap-iterator-done)
- [`λ.each.series`](#%CE%BBeachseriesitems-iterator-done)
- [`λ.map`](#%CE%BBmapitems-cap-iterator-done)
- [`λ.map.series`](#%CE%BBmapseriesitems-iterator-done)
- [`λ.filter`](#%CE%BBfilteritems-cap-iterator-done)
- [`λ.filter.series`](#%CE%BBfilterseriesitems-iterator-done)

Uncategorized

- [`λ.queue`](#%CE%BBqueueworker-cap1)
- [`λ.emitter`](#%CE%BBemitterthing-options)
- [`λ.curry`](#%CE%BBcurryfn-arguments)

# Install

Install using `npm` or `bower`. Or get the [source code][3] and embed that in a `<script>` tag.

```shell
npm i contra --save
```

```shell
bower i contra --save
```

You can use it as a Common.JS module, or embed it directly in your HTML.

```js
var λ = require('contra');
```

```html
<script src='contra.js'></script>
<script>
var λ = contra;
</script>
```

<sub>The only reason `contra` isn't published as `λ` directly is to make it easier for you to type.</sub>

<sub>[_Back to top_](#quick-links)</sub>

# API

These are the asynchronous flow control methods provided by `λ`.

## `λ.waterfall(tasks, done?)`

Executes tasks in series. Each step receives the arguments from the previous step.

- `tasks` Array of functions with the `(...results, next)` signature
- `done` Optional function with the `(err, ...results)` signature

```js
λ.waterfall([
  function (next) {
    next(null, 'params for', 'next', 'step');
  },
  function (a, b, c, next) {
    console.log(b);
    // <- 'next'
    next(null, 'ok', 'done');
  }
], function (err, ok, result) {
  console.log(result);
  // <- 'done'
});
```

<sub>[_Back to top_](#quick-links)</sub>

## `λ.concurrent(tasks, cap?, done?)`

Executes tasks concurrently. Results get passed as an array or hash to an optional `done` callback. Task order is preserved in results. You can set a concurrency cap, and it's uncapped by default.

- `tasks` Collection of functions with the `(cb)` signature. Can be an array or an object
- `cap` Optional concurrency level, used by the internal [queue](#%CE%BBqueueworker-cap1)
- `done` Optional function with the `(err, results)` signature

```js
λ.concurrent([
  function (cb) {
    setTimeout(function () {
      cb(null, 'boom');
    }, 1000);
  },
  function (cb) {
    cb(null, 'foo');
  }
], function (err, results) {
  console.log(results);
  // <- ['boom', 'foo']
});
```

Using objects

```js
λ.concurrent({
  first: function (cb) {
    setTimeout(function () {
      cb(null, 'boom');
    }, 1000);
  },
  second: function (cb) {
    cb(null, 'foo');
  }
}, function (err, results) {
  console.log(results);
  // <- { first: 'boom', second: 'foo' }
});
```

<sub>[_Back to top_](#quick-links)</sub>

## `λ.series(tasks, done?)`

**Effectively an alias for `λ.concurrent(tasks, 1, done?)`.**

Executes tasks in series. `done` gets all the results. Results get passed as an array or hash to an optional `done` callback. Task order is preserved in results.

- `tasks` Collection of functions with the `(next)` signature. Can be an array or an object
- `done` Optional function with the `(err, results)` signature

```js
λ.series([
  function (next) {
    setTimeout(function () {
      next(null, 'boom');
    }, 1000);
  },
  function (next) {
    next(null, 'foo');
  }
], function (err, results) {
  console.log(results);
  // <- ['boom', 'foo']
});
```

Using objects

```js
λ.series({
  first: function (next) {
    setTimeout(function () {
      next(null, 'boom');
    }, 1000);
  },
  second: function (next) {
    next(null, 'foo');
  }
}, function (err, results) {
  console.log(results);
  // <- { first: 'boom', second: 'foo' }
});
```

<sub>[_Back to top_](#quick-links)</sub>

## `λ.each(items, cap?, iterator, done?)`

Applies an iterator to each element in the collection concurrently.

- `items` Collection of items. Can be an array or an object
- `cap` Optional concurrency level, used by the internal [queue](#%CE%BBqueueworker-cap1)
- `iterator(item, key?, cb)` Function to execute on each item
  - `item` The current item
  - `key` Optional, array/object key of the current item
  - `cb` Needs to be called when processing for current item is done
- `done` Optional function with the `(err)` signature

```js
λ.each({ thing: 900, another: 23 }, function (item, cb) {
  setTimeout(function () {
    console.log(item);
    cb();
  }, item);
});
// <- 23
// <- 900
```

<sub>[_Back to top_](#quick-links)</sub>

## `λ.each.series(items, iterator, done?)`

Effectively an alias for `λ.each(items, 1, iterator, done?)`.

<sub>[_Back to top_](#quick-links)</sub>

## `λ.map(items, cap?, iterator, done?)`

Applies an iterator to each element in the collection concurrently. Produces an object with the transformation results. Task order is preserved in the results.

- `items` Collection of items. Can be an array or an object
- `cap` Optional concurrency level, used by the internal [queue](#%CE%BBqueueworker-cap1)
- `iterator(item, key?, cb)` Function to execute on each item
  - `item` The current item
  - `key` Optional, array/object key of the current item
  - `cb` Needs to be called when processing for current item is done
- `done` Optional function with the `(err, results)` signature

```js
λ.map({ thing: 900, another: 23 }, function (item, cb) {
  setTimeout(function () {
    cb(null, item * 2);
  }, item);
}, function (err, results) {
  console.log(results);
  <- { thing: 1800, another: 46 }
});
```

<sub>[_Back to top_](#quick-links)</sub>

## `λ.map.series(items, iterator, done?)`

Effectively an alias for `λ.map(items, 1, iterator, done?)`.

<sub>[_Back to top_](#quick-links)</sub>

## `λ.filter(items, cap?, iterator, done?)`

Applies an iterator to each element in the collection concurrently. Produces an object with the filtered results. Task order is preserved in results.

- `items` Collection of items. Can be an array or an object
- `cap` Optional concurrency level, used by the internal [queue](#%CE%BBqueueworker-cap1)
- `iterator(item, key?, cb)` Function to execute on each item
  - `item` The current item
  - `key` Optional, array/object key of the current item
  - `cb` Needs to be called when processing for current item is done
    - `err` An optional error which will short-circuit the filtering process, calling `done`
    - `keep` Truthy will keep the item. Falsy will remove it in the results
- `done` Optional function with the `(err, results)` signature

```js
λ.filter({ thing: 900, another: 23, foo: 69 }, function (item, cb) {
  setTimeout(function () {
    cb(null, item % 23 === 0);
  }, item);
}, function (err, results) {
  console.log(results);
  <- { another: 23, foo: 69 }
});
```

<sub>[_Back to top_](#quick-links)</sub>

## `λ.filter.series(items, iterator, done?)`

Effectively an alias for `λ.filter(items, 1, iterator, done?)`.

<sub>[_Back to top_](#quick-links)</sub>

## `λ.queue(worker, cap=1)`

Used to create a job queue.

- `worker(job, done)` Function to process jobs in the queue
  - `job` The current job
  - `done` Needs to be called when processing for current job is done
- `cap` Optional concurrency level, defaults to `1` (serial)

Returns a queue you can `push` or `unshift` jobs to. You can pause and resume the queue by hand.

- `push(job, done?)` Array of jobs or an individual job object. Enqueue those jobs, continue processing **(unless paused)**. Optional callback to run when each job is completed
- `unshift(job, done?)` Array of jobs or an individual job object. Add jobs to the top of the queue, continue processing **(unless paused)**. Optional callback to run when each job is completed
- `pending` Property. Jobs that haven't started processing yet
- `length` Short-hand for `pending.length`, only works if getters can be defined
- `pause()` Stop processing jobs. Those already being processed will run to completion
- `resume()` Start processing jobs again, after a `pause()`
- `on('drain', fn)` Execute `fn` whenever there's no more pending _(or running)_ jobs and processing is requested. Processing can be requested using `resume`, `push`, or `unshift`

```js
var q = λ.queue(worker);

function worker (job, done) {
  console.log(job);
  done(null);
}

q.push('job', function () {
  console.log('this job is done!');
});

q.push(['some', 'more'], function () {
  console.log('one of these jobs is done!');
});

q.on('drain', function () {
  console.log('all done!');
  // if you enqueue more tasks now, then drain
  // will fire again when pending.length reaches 0
});

// <- 'this job is done!'
// <- 'one of these jobs is done!'
// <- 'one of these jobs is done!'
// <- 'all done!'
```

<sub>[_Back to top_](#quick-links)</sub>

## `λ.emitter(thing={}, options={})`

Augments `thing` with the event emitter methods listed below. If `thing` isn't provided, an event emitter is created for you. Emitter methods return the `thing` for chaining.

- `thing` Optional. Writable JavaScript object
- `emit(type, ...arguments)` Emits an event of type `type`, passing any `...arguments`
- `emitterSnapshot(type)` Returns a function you can call, passing any `...arguments`
- `on(type, fn)` Registers an event listener `fn` for `type` events
- `once(type, fn)` Same as `on`, but the listener is discarded after one callback
- `off(type, fn)` Unregisters an event listener `fn` from `type` events
- `off(type)` Unregisters all event listeners from `type` events
- `off()` Unregisters all event listeners

The `emitterSnapshot(type)` method lets you remove all event listeners before emitting an event that might add more event listeners which shouldn't be removed. In the example below, `thing` removes all events and then emits a `'destroy'` event, resulting in a `'create'` event handler being attached. If we just used `thing.off()` after emitting the destroy event, the `'create'` event handler would be wiped out too _(or the consumer would have to know implementation details as to avoid this issue)_.

```js
var thing = λ.emitter();

thing.on('foo', foo);
thing.on('bar', bar);
thing.on('destroy', function () {
  thing.on('create', reinitialize);
});

var destroy = thing.emitterSnapshot('destroy');
thing.off();
destroy();
```

The emitter can be configured with the following options, too.

- `async` Debounce listeners asynchronously. By default they're executed in sequence.
- `throws` Throw an exception if an `error` event is emitted and no listeners are defined. Defaults to `true`.

```js
var thing = λ.emitter(); // also, λ.emitter({ foo: 'bar' })

thing.once('something', function (level) {
  console.log('something FIRST TROLL');
});

thing.on('something', function (level) {
  console.log('something level ' + level);
});

thing.emit('something', 4);
thing.emit('something', 5);
// <- 'something FIRST TROLL'
// <- 'something level 4'
// <- 'something level 5'
```

Returns `thing`.

Events of type `error` have a special behavior. `λ.emitter` will throw if there are no `error` listeners when an error event is emitted. This behavior can be turned off setting `throws: false` in the options.

```js
var thing = { foo: 'bar' };

λ.emitter(thing);

thing.emit('error', 'foo');
<- throws 'foo'
```

If an `'error'` listener is registered, then it'll work just like any other event type.

```js
var thing = { foo: 'bar' };

λ.emitter(thing);

thing.on('error', function (err) {
  console.log(err);
});

thing.emit('error', 'foo');
<- 'foo'
```

<sub>[_Back to top_](#quick-links)</sub>

## `λ.curry(fn, ...arguments)`

Returns a function bound with some arguments and a `next` callback.

```js
λ.curry(fn, 1, 3, 5);
// <- function (next) { fn(1, 3, 5, next); }
```

<sub>[_Back to top_](#quick-links)</sub>

# Comparison with `async`

[`async`][1]|`λ`
---|---
Aimed at Noders|Tailored for browsers
Arrays for [some][5], collections for [others][6]|Collections for **everyone**!
`apply`|`curry`
`parallel`|`concurrent`
`parallelLimit`|`concurrent`
`mapSeries`|`map.series`
More _comprehensive_|More _focused_
`~29.6k (minified, uncompressed)`|`~2.7k (minified, uncompressed)`

`λ` isn't meant to be a replacement for `async`. It aims to provide a more focused library, and a bit more consistency.

<sub>[_Back to top_](#quick-links)</sub>

# Browser Support

[![Browser Support](https://ci.testling.com/bevacqua/contra.png)](https://ci.testling.com/bevacqua/contra)

If you need support for one of the legacy browsers listed below, you'll need `contra.shim.js`.

- IE < 10
- Safari < 6
- Opera < 16

```js
require('contra/shim');
var λ = require('contra');
```

```html
<script src='contra.shim.js'></script>
<script src='contra.js'></script>
<script>
var λ = contra;
</script>
```

The shim currently clocks around `~1.2k` minified, uncompressed.

<sub>[_Back to top_](#quick-links)</sub>

# License

MIT

<sub>[_Back to top_](#quick-links)</sub>

  [logo]: https://raw.github.com/bevacqua/contra/master/resources/contra.png
  [1]: https://github.com/caolan/async
  [2]: https://github.com/lodash/lodash
  [3]: https://github.com/bevacqua/contra/tree/master/src/contra.js
  [4]: https://github.com/bevacqua
  [5]: https://github.com/caolan/async#maparr-iterator-callback
  [6]: https://github.com/caolan/async#paralleltasks-callback
