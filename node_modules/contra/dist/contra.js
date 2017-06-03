(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.contra = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
module.exports = Infinity;

},{}],2:[function(require,module,exports){
module.exports = 1;

},{}],3:[function(require,module,exports){
'use strict';

var _map = require('./_map');

module.exports = function each (concurrency) {
  return _map(concurrency, then);
  function then (collection, done) {
    return function mask (err) {
      done(err); // only return the error, no more arguments
    };
  }
};

},{"./_map":5}],4:[function(require,module,exports){
'use strict';

var a = require('./a');
var _map = require('./_map');

module.exports = function filter (concurrency) {
  return _map(concurrency, then);
  function then (collection, done) {
    return function filter (err, results) {
      function exists (item, key) {
        return !!results[key];
      }
      function ofilter () {
        var filtered = {};
        Object.keys(collection).forEach(function omapper (key) {
          if (exists(null, key)) { filtered[key] = collection[key]; }
        });
        return filtered;
      }
      if (err) { done(err); return; }
      done(null, a(results) ? collection.filter(exists) : ofilter());
    };
  }
};

},{"./_map":5,"./a":6}],5:[function(require,module,exports){
'use strict';

var a = require('./a');
var once = require('./once');
var concurrent = require('./concurrent');
var CONCURRENTLY = require('./CONCURRENTLY');
var SERIAL = require('./SERIAL');

module.exports = function _map (cap, then, attached) {
  function api (collection, concurrency, iterator, done) {
    var args = arguments;
    if (args.length === 2) { iterator = concurrency; concurrency = CONCURRENTLY; }
    if (args.length === 3 && typeof concurrency !== 'number') { done = iterator; iterator = concurrency; concurrency = CONCURRENTLY; }
    var keys = Object.keys(collection);
    var tasks = a(collection) ? [] : {};
    keys.forEach(function insert (key) {
      tasks[key] = function iterate (cb) {
        if (iterator.length === 3) {
          iterator(collection[key], key, cb);
        } else {
          iterator(collection[key], cb);
        }
      };
    });
    concurrent(tasks, cap || concurrency, then ? then(collection, once(done)) : done);
  }
  if (!attached) { api.series = _map(SERIAL, then, true); }
  return api;
};

},{"./CONCURRENTLY":1,"./SERIAL":2,"./a":6,"./concurrent":7,"./once":19}],6:[function(require,module,exports){
'use strict';

module.exports = function a (o) { return Object.prototype.toString.call(o) === '[object Array]'; };

},{}],7:[function(require,module,exports){
'use strict';

var atoa = require('atoa');
var a = require('./a');
var once = require('./once');
var queue = require('./queue');
var errored = require('./errored');
var debounce = require('./debounce');
var CONCURRENTLY = require('./CONCURRENTLY');

module.exports = function concurrent (tasks, concurrency, done) {
  if (typeof concurrency === 'function') { done = concurrency; concurrency = CONCURRENTLY; }
  var d = once(done);
  var q = queue(worker, concurrency);
  var keys = Object.keys(tasks);
  var results = a(tasks) ? [] : {};
  q.unshift(keys);
  q.on('drain', function completed () { d(null, results); });
  function worker (key, next) {
    debounce(tasks[key], [proceed]);
    function proceed () {
      var args = atoa(arguments);
      if (errored(args, d)) { return; }
      results[key] = args.shift();
      next();
    }
  }
};

},{"./CONCURRENTLY":1,"./a":6,"./debounce":10,"./errored":13,"./once":19,"./queue":20,"atoa":16}],8:[function(require,module,exports){
'use strict';

module.exports = {
  curry: require('./curry'),
  concurrent: require('./concurrent'),
  series: require('./series'),
  waterfall: require('./waterfall'),
  each: require('./each'),
  map: require('./map'),
  filter: require('./filter'),
  queue: require('./queue'),
  emitter: require('./emitter')
};

},{"./concurrent":7,"./curry":9,"./each":11,"./emitter":12,"./filter":14,"./map":15,"./queue":20,"./series":21,"./waterfall":22}],9:[function(require,module,exports){
'use strict';

var atoa = require('atoa');

module.exports = function curry () {
  var args = atoa(arguments);
  var method = args.shift();
  return function curried () {
    var more = atoa(arguments);
    method.apply(method, args.concat(more));
  };
};

},{"atoa":16}],10:[function(require,module,exports){
'use strict';

var ticky = require('ticky');

module.exports = function debounce (fn, args, ctx) {
  if (!fn) { return; }
  ticky(function run () {
    fn.apply(ctx || null, args || []);
  });
};

},{"ticky":17}],11:[function(require,module,exports){
'use strict';

module.exports = require('./_each')();

},{"./_each":3}],12:[function(require,module,exports){
'use strict';

var atoa = require('atoa');
var debounce = require('./debounce');

module.exports = function emitter (thing, options) {
  var opts = options || {};
  var evt = {};
  if (thing === undefined) { thing = {}; }
  thing.on = function (type, fn) {
    if (!evt[type]) {
      evt[type] = [fn];
    } else {
      evt[type].push(fn);
    }
    return thing;
  };
  thing.once = function (type, fn) {
    fn._once = true; // thing.off(fn) still works!
    thing.on(type, fn);
    return thing;
  };
  thing.off = function (type, fn) {
    var c = arguments.length;
    if (c === 1) {
      delete evt[type];
    } else if (c === 0) {
      evt = {};
    } else {
      var et = evt[type];
      if (!et) { return thing; }
      et.splice(et.indexOf(fn), 1);
    }
    return thing;
  };
  thing.emit = function () {
    var args = atoa(arguments);
    return thing.emitterSnapshot(args.shift()).apply(this, args);
  };
  thing.emitterSnapshot = function (type) {
    var et = (evt[type] || []).slice(0);
    return function () {
      var args = atoa(arguments);
      var ctx = this || thing;
      if (type === 'error' && opts.throws !== false && !et.length) { throw args.length === 1 ? args[0] : args; }
      et.forEach(function emitter (listen) {
        if (opts.async) { debounce(listen, args, ctx); } else { listen.apply(ctx, args); }
        if (listen._once) { thing.off(type, listen); }
      });
      return thing;
    };
  };
  return thing;
};

},{"./debounce":10,"atoa":16}],13:[function(require,module,exports){
'use strict';

var debounce = require('./debounce');

module.exports = function errored (args, done, disposable) {
  var err = args.shift();
  if (err) { if (disposable) { disposable.discard(); } debounce(done, [err]); return true; }
};

},{"./debounce":10}],14:[function(require,module,exports){
'use strict';

module.exports = require('./_filter')();

},{"./_filter":4}],15:[function(require,module,exports){
'use strict';

module.exports = require('./_map')();

},{"./_map":5}],16:[function(require,module,exports){
module.exports = function atoa (a, n) { return Array.prototype.slice.call(a, n); }

},{}],17:[function(require,module,exports){
var si = typeof setImmediate === 'function', tick;
if (si) {
  tick = function (fn) { setImmediate(fn); };
} else {
  tick = function (fn) { setTimeout(fn, 0); };
}

module.exports = tick;
},{}],18:[function(require,module,exports){
'use strict';

module.exports = function noop () {};

},{}],19:[function(require,module,exports){
'use strict';

var noop = require('./noop');

module.exports = function once (fn) {
  var disposed;
  function disposable () {
    if (disposed) { return; }
    disposed = true;
    (fn || noop).apply(null, arguments);
  }
  disposable.discard = function () { disposed = true; };
  return disposable;
};

},{"./noop":18}],20:[function(require,module,exports){
'use strict';

var atoa = require('atoa');
var a = require('./a');
var once = require('./once');
var emitter = require('./emitter');
var debounce = require('./debounce');

module.exports = function queue (worker, concurrency) {
  var q = [], load = 0, max = concurrency || 1, paused;
  var qq = emitter({
    push: manipulate.bind(null, 'push'),
    unshift: manipulate.bind(null, 'unshift'),
    pause: function pause () { paused = true; },
    resume: function resume () { paused = false; debounce(labor); },
    pending: q
  });
  if (Object.defineProperty && !Object.definePropertyPartial) {
    Object.defineProperty(qq, 'length', { get: function getter () { return q.length; } });
  }
  function manipulate (how, task, done) {
    var tasks = a(task) ? task : [task];
    tasks.forEach(function insert (t) { q[how]({ t: t, done: done }); });
    debounce(labor);
  }
  function labor () {
    if (paused || load >= max) { return; }
    if (!q.length) { if (load === 0) { qq.emit('drain'); } return; }
    load++;
    var job = q.pop();
    worker(job.t, once(complete.bind(null, job)));
    debounce(labor);
  }
  function complete (job) {
    load--;
    debounce(job.done, atoa(arguments, 1));
    debounce(labor);
  }
  return qq;
};

},{"./a":6,"./debounce":10,"./emitter":12,"./once":19,"atoa":16}],21:[function(require,module,exports){
'use strict';

var concurrent = require('./concurrent');
var SERIAL = require('./SERIAL');

module.exports = function series (tasks, done) {
  concurrent(tasks, SERIAL, done);
};

},{"./SERIAL":2,"./concurrent":7}],22:[function(require,module,exports){
'use strict';

var atoa = require('atoa');
var once = require('./once');
var errored = require('./errored');
var debounce = require('./debounce');

module.exports = function waterfall (steps, done) {
  var d = once(done);
  function next () {
    var args = atoa(arguments);
    var step = steps.shift();
    if (step) {
      if (errored(args, d)) { return; }
      args.push(once(next));
      debounce(step, args);
    } else {
      debounce(d, arguments);
    }
  }
  next();
};

},{"./debounce":10,"./errored":13,"./once":19,"atoa":16}]},{},[8])(8)
});
//# sourceMappingURL=data:application/json;charset:utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCJDT05DVVJSRU5UTFkuanMiLCJTRVJJQUwuanMiLCJfZWFjaC5qcyIsIl9maWx0ZXIuanMiLCJfbWFwLmpzIiwiYS5qcyIsImNvbmN1cnJlbnQuanMiLCJjb250cmEuanMiLCJjdXJyeS5qcyIsImRlYm91bmNlLmpzIiwiZWFjaC5qcyIsImVtaXR0ZXIuanMiLCJlcnJvcmVkLmpzIiwiZmlsdGVyLmpzIiwibWFwLmpzIiwibm9kZV9tb2R1bGVzL2F0b2EvYXRvYS5qcyIsIm5vZGVfbW9kdWxlcy90aWNreS90aWNreS1icm93c2VyLmpzIiwibm9vcC5qcyIsIm9uY2UuanMiLCJxdWV1ZS5qcyIsInNlcmllcy5qcyIsIndhdGVyZmFsbC5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTtBQ0FBO0FBQ0E7O0FDREE7QUFDQTs7QUNEQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNaQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUN4QkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzdCQTtBQUNBO0FBQ0E7QUFDQTs7QUNIQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzVCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ2JBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ1pBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDVkE7QUFDQTtBQUNBO0FBQ0E7O0FDSEE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDdERBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNSQTtBQUNBO0FBQ0E7QUFDQTs7QUNIQTtBQUNBO0FBQ0E7QUFDQTs7QUNIQTtBQUNBOztBQ0RBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDUEE7QUFDQTtBQUNBO0FBQ0E7O0FDSEE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ2RBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDeENBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNSQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIoZnVuY3Rpb24gZSh0LG4scil7ZnVuY3Rpb24gcyhvLHUpe2lmKCFuW29dKXtpZighdFtvXSl7dmFyIGE9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtpZighdSYmYSlyZXR1cm4gYShvLCEwKTtpZihpKXJldHVybiBpKG8sITApO3ZhciBmPW5ldyBFcnJvcihcIkNhbm5vdCBmaW5kIG1vZHVsZSAnXCIrbytcIidcIik7dGhyb3cgZi5jb2RlPVwiTU9EVUxFX05PVF9GT1VORFwiLGZ9dmFyIGw9bltvXT17ZXhwb3J0czp7fX07dFtvXVswXS5jYWxsKGwuZXhwb3J0cyxmdW5jdGlvbihlKXt2YXIgbj10W29dWzFdW2VdO3JldHVybiBzKG4/bjplKX0sbCxsLmV4cG9ydHMsZSx0LG4scil9cmV0dXJuIG5bb10uZXhwb3J0c312YXIgaT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2Zvcih2YXIgbz0wO288ci5sZW5ndGg7bysrKXMocltvXSk7cmV0dXJuIHN9KSIsIm1vZHVsZS5leHBvcnRzID0gSW5maW5pdHk7XG4iLCJtb2R1bGUuZXhwb3J0cyA9IDE7XG4iLCIndXNlIHN0cmljdCc7XG5cbnZhciBfbWFwID0gcmVxdWlyZSgnLi9fbWFwJyk7XG5cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gZWFjaCAoY29uY3VycmVuY3kpIHtcbiAgcmV0dXJuIF9tYXAoY29uY3VycmVuY3ksIHRoZW4pO1xuICBmdW5jdGlvbiB0aGVuIChjb2xsZWN0aW9uLCBkb25lKSB7XG4gICAgcmV0dXJuIGZ1bmN0aW9uIG1hc2sgKGVycikge1xuICAgICAgZG9uZShlcnIpOyAvLyBvbmx5IHJldHVybiB0aGUgZXJyb3IsIG5vIG1vcmUgYXJndW1lbnRzXG4gICAgfTtcbiAgfVxufTtcbiIsIid1c2Ugc3RyaWN0JztcblxudmFyIGEgPSByZXF1aXJlKCcuL2EnKTtcbnZhciBfbWFwID0gcmVxdWlyZSgnLi9fbWFwJyk7XG5cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gZmlsdGVyIChjb25jdXJyZW5jeSkge1xuICByZXR1cm4gX21hcChjb25jdXJyZW5jeSwgdGhlbik7XG4gIGZ1bmN0aW9uIHRoZW4gKGNvbGxlY3Rpb24sIGRvbmUpIHtcbiAgICByZXR1cm4gZnVuY3Rpb24gZmlsdGVyIChlcnIsIHJlc3VsdHMpIHtcbiAgICAgIGZ1bmN0aW9uIGV4aXN0cyAoaXRlbSwga2V5KSB7XG4gICAgICAgIHJldHVybiAhIXJlc3VsdHNba2V5XTtcbiAgICAgIH1cbiAgICAgIGZ1bmN0aW9uIG9maWx0ZXIgKCkge1xuICAgICAgICB2YXIgZmlsdGVyZWQgPSB7fTtcbiAgICAgICAgT2JqZWN0LmtleXMoY29sbGVjdGlvbikuZm9yRWFjaChmdW5jdGlvbiBvbWFwcGVyIChrZXkpIHtcbiAgICAgICAgICBpZiAoZXhpc3RzKG51bGwsIGtleSkpIHsgZmlsdGVyZWRba2V5XSA9IGNvbGxlY3Rpb25ba2V5XTsgfVxuICAgICAgICB9KTtcbiAgICAgICAgcmV0dXJuIGZpbHRlcmVkO1xuICAgICAgfVxuICAgICAgaWYgKGVycikgeyBkb25lKGVycik7IHJldHVybjsgfVxuICAgICAgZG9uZShudWxsLCBhKHJlc3VsdHMpID8gY29sbGVjdGlvbi5maWx0ZXIoZXhpc3RzKSA6IG9maWx0ZXIoKSk7XG4gICAgfTtcbiAgfVxufTtcbiIsIid1c2Ugc3RyaWN0JztcblxudmFyIGEgPSByZXF1aXJlKCcuL2EnKTtcbnZhciBvbmNlID0gcmVxdWlyZSgnLi9vbmNlJyk7XG52YXIgY29uY3VycmVudCA9IHJlcXVpcmUoJy4vY29uY3VycmVudCcpO1xudmFyIENPTkNVUlJFTlRMWSA9IHJlcXVpcmUoJy4vQ09OQ1VSUkVOVExZJyk7XG52YXIgU0VSSUFMID0gcmVxdWlyZSgnLi9TRVJJQUwnKTtcblxubW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbiBfbWFwIChjYXAsIHRoZW4sIGF0dGFjaGVkKSB7XG4gIGZ1bmN0aW9uIGFwaSAoY29sbGVjdGlvbiwgY29uY3VycmVuY3ksIGl0ZXJhdG9yLCBkb25lKSB7XG4gICAgdmFyIGFyZ3MgPSBhcmd1bWVudHM7XG4gICAgaWYgKGFyZ3MubGVuZ3RoID09PSAyKSB7IGl0ZXJhdG9yID0gY29uY3VycmVuY3k7IGNvbmN1cnJlbmN5ID0gQ09OQ1VSUkVOVExZOyB9XG4gICAgaWYgKGFyZ3MubGVuZ3RoID09PSAzICYmIHR5cGVvZiBjb25jdXJyZW5jeSAhPT0gJ251bWJlcicpIHsgZG9uZSA9IGl0ZXJhdG9yOyBpdGVyYXRvciA9IGNvbmN1cnJlbmN5OyBjb25jdXJyZW5jeSA9IENPTkNVUlJFTlRMWTsgfVxuICAgIHZhciBrZXlzID0gT2JqZWN0LmtleXMoY29sbGVjdGlvbik7XG4gICAgdmFyIHRhc2tzID0gYShjb2xsZWN0aW9uKSA/IFtdIDoge307XG4gICAga2V5cy5mb3JFYWNoKGZ1bmN0aW9uIGluc2VydCAoa2V5KSB7XG4gICAgICB0YXNrc1trZXldID0gZnVuY3Rpb24gaXRlcmF0ZSAoY2IpIHtcbiAgICAgICAgaWYgKGl0ZXJhdG9yLmxlbmd0aCA9PT0gMykge1xuICAgICAgICAgIGl0ZXJhdG9yKGNvbGxlY3Rpb25ba2V5XSwga2V5LCBjYik7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgaXRlcmF0b3IoY29sbGVjdGlvbltrZXldLCBjYik7XG4gICAgICAgIH1cbiAgICAgIH07XG4gICAgfSk7XG4gICAgY29uY3VycmVudCh0YXNrcywgY2FwIHx8IGNvbmN1cnJlbmN5LCB0aGVuID8gdGhlbihjb2xsZWN0aW9uLCBvbmNlKGRvbmUpKSA6IGRvbmUpO1xuICB9XG4gIGlmICghYXR0YWNoZWQpIHsgYXBpLnNlcmllcyA9IF9tYXAoU0VSSUFMLCB0aGVuLCB0cnVlKTsgfVxuICByZXR1cm4gYXBpO1xufTtcbiIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbiBhIChvKSB7IHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwobykgPT09ICdbb2JqZWN0IEFycmF5XSc7IH07XG4iLCIndXNlIHN0cmljdCc7XG5cbnZhciBhdG9hID0gcmVxdWlyZSgnYXRvYScpO1xudmFyIGEgPSByZXF1aXJlKCcuL2EnKTtcbnZhciBvbmNlID0gcmVxdWlyZSgnLi9vbmNlJyk7XG52YXIgcXVldWUgPSByZXF1aXJlKCcuL3F1ZXVlJyk7XG52YXIgZXJyb3JlZCA9IHJlcXVpcmUoJy4vZXJyb3JlZCcpO1xudmFyIGRlYm91bmNlID0gcmVxdWlyZSgnLi9kZWJvdW5jZScpO1xudmFyIENPTkNVUlJFTlRMWSA9IHJlcXVpcmUoJy4vQ09OQ1VSUkVOVExZJyk7XG5cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gY29uY3VycmVudCAodGFza3MsIGNvbmN1cnJlbmN5LCBkb25lKSB7XG4gIGlmICh0eXBlb2YgY29uY3VycmVuY3kgPT09ICdmdW5jdGlvbicpIHsgZG9uZSA9IGNvbmN1cnJlbmN5OyBjb25jdXJyZW5jeSA9IENPTkNVUlJFTlRMWTsgfVxuICB2YXIgZCA9IG9uY2UoZG9uZSk7XG4gIHZhciBxID0gcXVldWUod29ya2VyLCBjb25jdXJyZW5jeSk7XG4gIHZhciBrZXlzID0gT2JqZWN0LmtleXModGFza3MpO1xuICB2YXIgcmVzdWx0cyA9IGEodGFza3MpID8gW10gOiB7fTtcbiAgcS51bnNoaWZ0KGtleXMpO1xuICBxLm9uKCdkcmFpbicsIGZ1bmN0aW9uIGNvbXBsZXRlZCAoKSB7IGQobnVsbCwgcmVzdWx0cyk7IH0pO1xuICBmdW5jdGlvbiB3b3JrZXIgKGtleSwgbmV4dCkge1xuICAgIGRlYm91bmNlKHRhc2tzW2tleV0sIFtwcm9jZWVkXSk7XG4gICAgZnVuY3Rpb24gcHJvY2VlZCAoKSB7XG4gICAgICB2YXIgYXJncyA9IGF0b2EoYXJndW1lbnRzKTtcbiAgICAgIGlmIChlcnJvcmVkKGFyZ3MsIGQpKSB7IHJldHVybjsgfVxuICAgICAgcmVzdWx0c1trZXldID0gYXJncy5zaGlmdCgpO1xuICAgICAgbmV4dCgpO1xuICAgIH1cbiAgfVxufTtcbiIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIGN1cnJ5OiByZXF1aXJlKCcuL2N1cnJ5JyksXG4gIGNvbmN1cnJlbnQ6IHJlcXVpcmUoJy4vY29uY3VycmVudCcpLFxuICBzZXJpZXM6IHJlcXVpcmUoJy4vc2VyaWVzJyksXG4gIHdhdGVyZmFsbDogcmVxdWlyZSgnLi93YXRlcmZhbGwnKSxcbiAgZWFjaDogcmVxdWlyZSgnLi9lYWNoJyksXG4gIG1hcDogcmVxdWlyZSgnLi9tYXAnKSxcbiAgZmlsdGVyOiByZXF1aXJlKCcuL2ZpbHRlcicpLFxuICBxdWV1ZTogcmVxdWlyZSgnLi9xdWV1ZScpLFxuICBlbWl0dGVyOiByZXF1aXJlKCcuL2VtaXR0ZXInKVxufTtcbiIsIid1c2Ugc3RyaWN0JztcblxudmFyIGF0b2EgPSByZXF1aXJlKCdhdG9hJyk7XG5cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gY3VycnkgKCkge1xuICB2YXIgYXJncyA9IGF0b2EoYXJndW1lbnRzKTtcbiAgdmFyIG1ldGhvZCA9IGFyZ3Muc2hpZnQoKTtcbiAgcmV0dXJuIGZ1bmN0aW9uIGN1cnJpZWQgKCkge1xuICAgIHZhciBtb3JlID0gYXRvYShhcmd1bWVudHMpO1xuICAgIG1ldGhvZC5hcHBseShtZXRob2QsIGFyZ3MuY29uY2F0KG1vcmUpKTtcbiAgfTtcbn07XG4iLCIndXNlIHN0cmljdCc7XG5cbnZhciB0aWNreSA9IHJlcXVpcmUoJ3RpY2t5Jyk7XG5cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gZGVib3VuY2UgKGZuLCBhcmdzLCBjdHgpIHtcbiAgaWYgKCFmbikgeyByZXR1cm47IH1cbiAgdGlja3koZnVuY3Rpb24gcnVuICgpIHtcbiAgICBmbi5hcHBseShjdHggfHwgbnVsbCwgYXJncyB8fCBbXSk7XG4gIH0pO1xufTtcbiIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSByZXF1aXJlKCcuL19lYWNoJykoKTtcbiIsIid1c2Ugc3RyaWN0JztcblxudmFyIGF0b2EgPSByZXF1aXJlKCdhdG9hJyk7XG52YXIgZGVib3VuY2UgPSByZXF1aXJlKCcuL2RlYm91bmNlJyk7XG5cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gZW1pdHRlciAodGhpbmcsIG9wdGlvbnMpIHtcbiAgdmFyIG9wdHMgPSBvcHRpb25zIHx8IHt9O1xuICB2YXIgZXZ0ID0ge307XG4gIGlmICh0aGluZyA9PT0gdW5kZWZpbmVkKSB7IHRoaW5nID0ge307IH1cbiAgdGhpbmcub24gPSBmdW5jdGlvbiAodHlwZSwgZm4pIHtcbiAgICBpZiAoIWV2dFt0eXBlXSkge1xuICAgICAgZXZ0W3R5cGVdID0gW2ZuXTtcbiAgICB9IGVsc2Uge1xuICAgICAgZXZ0W3R5cGVdLnB1c2goZm4pO1xuICAgIH1cbiAgICByZXR1cm4gdGhpbmc7XG4gIH07XG4gIHRoaW5nLm9uY2UgPSBmdW5jdGlvbiAodHlwZSwgZm4pIHtcbiAgICBmbi5fb25jZSA9IHRydWU7IC8vIHRoaW5nLm9mZihmbikgc3RpbGwgd29ya3MhXG4gICAgdGhpbmcub24odHlwZSwgZm4pO1xuICAgIHJldHVybiB0aGluZztcbiAgfTtcbiAgdGhpbmcub2ZmID0gZnVuY3Rpb24gKHR5cGUsIGZuKSB7XG4gICAgdmFyIGMgPSBhcmd1bWVudHMubGVuZ3RoO1xuICAgIGlmIChjID09PSAxKSB7XG4gICAgICBkZWxldGUgZXZ0W3R5cGVdO1xuICAgIH0gZWxzZSBpZiAoYyA9PT0gMCkge1xuICAgICAgZXZ0ID0ge307XG4gICAgfSBlbHNlIHtcbiAgICAgIHZhciBldCA9IGV2dFt0eXBlXTtcbiAgICAgIGlmICghZXQpIHsgcmV0dXJuIHRoaW5nOyB9XG4gICAgICBldC5zcGxpY2UoZXQuaW5kZXhPZihmbiksIDEpO1xuICAgIH1cbiAgICByZXR1cm4gdGhpbmc7XG4gIH07XG4gIHRoaW5nLmVtaXQgPSBmdW5jdGlvbiAoKSB7XG4gICAgdmFyIGFyZ3MgPSBhdG9hKGFyZ3VtZW50cyk7XG4gICAgcmV0dXJuIHRoaW5nLmVtaXR0ZXJTbmFwc2hvdChhcmdzLnNoaWZ0KCkpLmFwcGx5KHRoaXMsIGFyZ3MpO1xuICB9O1xuICB0aGluZy5lbWl0dGVyU25hcHNob3QgPSBmdW5jdGlvbiAodHlwZSkge1xuICAgIHZhciBldCA9IChldnRbdHlwZV0gfHwgW10pLnNsaWNlKDApO1xuICAgIHJldHVybiBmdW5jdGlvbiAoKSB7XG4gICAgICB2YXIgYXJncyA9IGF0b2EoYXJndW1lbnRzKTtcbiAgICAgIHZhciBjdHggPSB0aGlzIHx8IHRoaW5nO1xuICAgICAgaWYgKHR5cGUgPT09ICdlcnJvcicgJiYgb3B0cy50aHJvd3MgIT09IGZhbHNlICYmICFldC5sZW5ndGgpIHsgdGhyb3cgYXJncy5sZW5ndGggPT09IDEgPyBhcmdzWzBdIDogYXJnczsgfVxuICAgICAgZXQuZm9yRWFjaChmdW5jdGlvbiBlbWl0dGVyIChsaXN0ZW4pIHtcbiAgICAgICAgaWYgKG9wdHMuYXN5bmMpIHsgZGVib3VuY2UobGlzdGVuLCBhcmdzLCBjdHgpOyB9IGVsc2UgeyBsaXN0ZW4uYXBwbHkoY3R4LCBhcmdzKTsgfVxuICAgICAgICBpZiAobGlzdGVuLl9vbmNlKSB7IHRoaW5nLm9mZih0eXBlLCBsaXN0ZW4pOyB9XG4gICAgICB9KTtcbiAgICAgIHJldHVybiB0aGluZztcbiAgICB9O1xuICB9O1xuICByZXR1cm4gdGhpbmc7XG59O1xuIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgZGVib3VuY2UgPSByZXF1aXJlKCcuL2RlYm91bmNlJyk7XG5cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gZXJyb3JlZCAoYXJncywgZG9uZSwgZGlzcG9zYWJsZSkge1xuICB2YXIgZXJyID0gYXJncy5zaGlmdCgpO1xuICBpZiAoZXJyKSB7IGlmIChkaXNwb3NhYmxlKSB7IGRpc3Bvc2FibGUuZGlzY2FyZCgpOyB9IGRlYm91bmNlKGRvbmUsIFtlcnJdKTsgcmV0dXJuIHRydWU7IH1cbn07XG4iLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0gcmVxdWlyZSgnLi9fZmlsdGVyJykoKTtcbiIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSByZXF1aXJlKCcuL19tYXAnKSgpO1xuIiwibW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbiBhdG9hIChhLCBuKSB7IHJldHVybiBBcnJheS5wcm90b3R5cGUuc2xpY2UuY2FsbChhLCBuKTsgfVxuIiwidmFyIHNpID0gdHlwZW9mIHNldEltbWVkaWF0ZSA9PT0gJ2Z1bmN0aW9uJywgdGljaztcbmlmIChzaSkge1xuICB0aWNrID0gZnVuY3Rpb24gKGZuKSB7IHNldEltbWVkaWF0ZShmbik7IH07XG59IGVsc2Uge1xuICB0aWNrID0gZnVuY3Rpb24gKGZuKSB7IHNldFRpbWVvdXQoZm4sIDApOyB9O1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IHRpY2s7IiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uIG5vb3AgKCkge307XG4iLCIndXNlIHN0cmljdCc7XG5cbnZhciBub29wID0gcmVxdWlyZSgnLi9ub29wJyk7XG5cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gb25jZSAoZm4pIHtcbiAgdmFyIGRpc3Bvc2VkO1xuICBmdW5jdGlvbiBkaXNwb3NhYmxlICgpIHtcbiAgICBpZiAoZGlzcG9zZWQpIHsgcmV0dXJuOyB9XG4gICAgZGlzcG9zZWQgPSB0cnVlO1xuICAgIChmbiB8fCBub29wKS5hcHBseShudWxsLCBhcmd1bWVudHMpO1xuICB9XG4gIGRpc3Bvc2FibGUuZGlzY2FyZCA9IGZ1bmN0aW9uICgpIHsgZGlzcG9zZWQgPSB0cnVlOyB9O1xuICByZXR1cm4gZGlzcG9zYWJsZTtcbn07XG4iLCIndXNlIHN0cmljdCc7XG5cbnZhciBhdG9hID0gcmVxdWlyZSgnYXRvYScpO1xudmFyIGEgPSByZXF1aXJlKCcuL2EnKTtcbnZhciBvbmNlID0gcmVxdWlyZSgnLi9vbmNlJyk7XG52YXIgZW1pdHRlciA9IHJlcXVpcmUoJy4vZW1pdHRlcicpO1xudmFyIGRlYm91bmNlID0gcmVxdWlyZSgnLi9kZWJvdW5jZScpO1xuXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uIHF1ZXVlICh3b3JrZXIsIGNvbmN1cnJlbmN5KSB7XG4gIHZhciBxID0gW10sIGxvYWQgPSAwLCBtYXggPSBjb25jdXJyZW5jeSB8fCAxLCBwYXVzZWQ7XG4gIHZhciBxcSA9IGVtaXR0ZXIoe1xuICAgIHB1c2g6IG1hbmlwdWxhdGUuYmluZChudWxsLCAncHVzaCcpLFxuICAgIHVuc2hpZnQ6IG1hbmlwdWxhdGUuYmluZChudWxsLCAndW5zaGlmdCcpLFxuICAgIHBhdXNlOiBmdW5jdGlvbiBwYXVzZSAoKSB7IHBhdXNlZCA9IHRydWU7IH0sXG4gICAgcmVzdW1lOiBmdW5jdGlvbiByZXN1bWUgKCkgeyBwYXVzZWQgPSBmYWxzZTsgZGVib3VuY2UobGFib3IpOyB9LFxuICAgIHBlbmRpbmc6IHFcbiAgfSk7XG4gIGlmIChPYmplY3QuZGVmaW5lUHJvcGVydHkgJiYgIU9iamVjdC5kZWZpbmVQcm9wZXJ0eVBhcnRpYWwpIHtcbiAgICBPYmplY3QuZGVmaW5lUHJvcGVydHkocXEsICdsZW5ndGgnLCB7IGdldDogZnVuY3Rpb24gZ2V0dGVyICgpIHsgcmV0dXJuIHEubGVuZ3RoOyB9IH0pO1xuICB9XG4gIGZ1bmN0aW9uIG1hbmlwdWxhdGUgKGhvdywgdGFzaywgZG9uZSkge1xuICAgIHZhciB0YXNrcyA9IGEodGFzaykgPyB0YXNrIDogW3Rhc2tdO1xuICAgIHRhc2tzLmZvckVhY2goZnVuY3Rpb24gaW5zZXJ0ICh0KSB7IHFbaG93XSh7IHQ6IHQsIGRvbmU6IGRvbmUgfSk7IH0pO1xuICAgIGRlYm91bmNlKGxhYm9yKTtcbiAgfVxuICBmdW5jdGlvbiBsYWJvciAoKSB7XG4gICAgaWYgKHBhdXNlZCB8fCBsb2FkID49IG1heCkgeyByZXR1cm47IH1cbiAgICBpZiAoIXEubGVuZ3RoKSB7IGlmIChsb2FkID09PSAwKSB7IHFxLmVtaXQoJ2RyYWluJyk7IH0gcmV0dXJuOyB9XG4gICAgbG9hZCsrO1xuICAgIHZhciBqb2IgPSBxLnBvcCgpO1xuICAgIHdvcmtlcihqb2IudCwgb25jZShjb21wbGV0ZS5iaW5kKG51bGwsIGpvYikpKTtcbiAgICBkZWJvdW5jZShsYWJvcik7XG4gIH1cbiAgZnVuY3Rpb24gY29tcGxldGUgKGpvYikge1xuICAgIGxvYWQtLTtcbiAgICBkZWJvdW5jZShqb2IuZG9uZSwgYXRvYShhcmd1bWVudHMsIDEpKTtcbiAgICBkZWJvdW5jZShsYWJvcik7XG4gIH1cbiAgcmV0dXJuIHFxO1xufTtcbiIsIid1c2Ugc3RyaWN0JztcblxudmFyIGNvbmN1cnJlbnQgPSByZXF1aXJlKCcuL2NvbmN1cnJlbnQnKTtcbnZhciBTRVJJQUwgPSByZXF1aXJlKCcuL1NFUklBTCcpO1xuXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uIHNlcmllcyAodGFza3MsIGRvbmUpIHtcbiAgY29uY3VycmVudCh0YXNrcywgU0VSSUFMLCBkb25lKTtcbn07XG4iLCIndXNlIHN0cmljdCc7XG5cbnZhciBhdG9hID0gcmVxdWlyZSgnYXRvYScpO1xudmFyIG9uY2UgPSByZXF1aXJlKCcuL29uY2UnKTtcbnZhciBlcnJvcmVkID0gcmVxdWlyZSgnLi9lcnJvcmVkJyk7XG52YXIgZGVib3VuY2UgPSByZXF1aXJlKCcuL2RlYm91bmNlJyk7XG5cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gd2F0ZXJmYWxsIChzdGVwcywgZG9uZSkge1xuICB2YXIgZCA9IG9uY2UoZG9uZSk7XG4gIGZ1bmN0aW9uIG5leHQgKCkge1xuICAgIHZhciBhcmdzID0gYXRvYShhcmd1bWVudHMpO1xuICAgIHZhciBzdGVwID0gc3RlcHMuc2hpZnQoKTtcbiAgICBpZiAoc3RlcCkge1xuICAgICAgaWYgKGVycm9yZWQoYXJncywgZCkpIHsgcmV0dXJuOyB9XG4gICAgICBhcmdzLnB1c2gob25jZShuZXh0KSk7XG4gICAgICBkZWJvdW5jZShzdGVwLCBhcmdzKTtcbiAgICB9IGVsc2Uge1xuICAgICAgZGVib3VuY2UoZCwgYXJndW1lbnRzKTtcbiAgICB9XG4gIH1cbiAgbmV4dCgpO1xufTtcbiJdfQ==
