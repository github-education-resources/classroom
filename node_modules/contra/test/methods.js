'use strict';

var contra = typeof contra !== 'undefined' ? contra : require('..');
var a = typeof assert !== 'undefined' ? assert : require('assert');

a.falsy = function (value, message) { a.equal(false, !!value, message); };

describe('waterfall()', function () {
  it('should run tasks in a waterfall', function (done) {
    var cb = false, cc = false;
    function b (next) {
      cb = true;
      a.falsy(cc);
      next(null, 'a');
    }
    function c (d, next) {
      cc = true;
      a.ok(cb);
      a.equal(d, 'a');
      next(null, 'b');
    }
    function d (err, result) {
      a.falsy(err);
      a.ok(cb);
      a.ok(cc);
      a.equal(result, 'b');
      done();
    }
    contra.waterfall([b,c],d);
  });
});

describe('series()', function () {
  it('should run tasks in a series as array', function (done) {
    var cb = false, cc = false;
    function b (next) {
      cb = true;
      a.falsy(cc);
      next(null, 'a');
    }
    function c (next) {
      cc = true;
      a.ok(cb);
      next(null, 'b');
    }
    function d (err, results) {
      a.falsy(err);
      a.ok(cb);
      a.ok(cc);
      a.equal(Object.keys(results).length, 2);
      a.equal(results[0], 'a');
      a.equal(results[1], 'b');
      done();
    }
    contra.series([b,c],d);
  });

  it('should run tasks in a series as object', function (done) {
    var cb = false, cc = false;
    function b (next) {
      cb = true;
      a.falsy(cc);
      next(null, 'a');
    }
    function c (next) {
      cc = true;
      a.ok(cb);
      next(null, 'b');
    }
    function d (err, results) {
      a.falsy(err);
      a.ok(cb);
      a.ok(cc);
      a.equal(Object.keys(results).length, 2);
      a.equal(results.e, 'a');
      a.equal(results.f, 'b');
      done();
    }
    contra.series({ e: b, f: c }, d);
  });

  it('should short-circuit on error', function (done) {
    var cb = false, cc = false;
    function b (next) {
      cb = true;
      a.falsy(cc);
      next('d', 'a');
    }
    function c (next) {
      cc = true;
      a.ok(cb);
      next(null, 'b');
    }
    function d (err, results) {
      a.ok(err);
      a.equal(err, 'd');
      a.ok(cb);
      a.falsy(cc);
      a.falsy(results);
      done();
    }
    contra.series([b,c],d);
  });
});

describe('concurrent()', function () {
  it('should run tasks concurrently as array', function (done) {
    var cb = false, cc = false;
    function b (next) {
      cb = true;
      a.falsy(cc);
      next(null, 'a');
    }
    function c (next) {
      cc = true;
      a.ok(cb);
      next(null, 'b');
    }
    function d (err, results) {
      a.falsy(err);
      a.ok(cb);
      a.ok(cc);
      a.equal(Object.keys(results).length, 2);
      a.equal(results[0], 'a');
      a.equal(results[1], 'b');
      done();
    }
    contra.concurrent([b,c],d);
  });

  it('should run tasks concurrently as object', function (done) {
    var cb = false, cc = false;
    function b (next) {
      cb = true;
      a.falsy(cc);
      next(null, 'a');
    }
    function c (next) {
      cc = true;
      a.ok(cb);
      next(null, 'b');
    }
    function d (err, results) {
      a.falsy(err);
      a.ok(cb);
      a.ok(cc);
      a.equal(Object.keys(results).length, 2);
      a.equal(results.a, 'a');
      a.equal(results.d, 'b');
      done();
    }
    contra.concurrent({ a: b, d: c }, d);
  });

  it('should short-circuit on error', function (done) {
    function b (next) {
      next('b', 'a');
    }
    function c (next) {
      next(null, 'b');
    }
    function d (err, results) {
      a.ok(err);
      a.equal(err, 'b');
      a.falsy(results);
      done();
    }
    contra.concurrent([b,c],d);
  });
});

describe('curry()', function () {
  it('should work with no extra arguments', function () {
    var fn = function (b,c,d) {
      a.equal(b, 1);
      a.equal(c, 3);
      a.equal(d, 'c');
    };
    var applied = contra.curry(fn, 1, 3, 'c');
    applied();
  });

  it('should include extra arguments as well', function () {
    var fn = function (b,c,d,e,f) {
      a.equal(b, 1);
      a.equal(c, 3);
      a.equal(d, 'c');
      a.equal(e, 'd');
      a.equal(f, 'e');
    };
    var applied = contra.curry(fn, 1, 3, 'c');
    applied('d', 'e');
  });

  it('should play well with contra.series', function (done) {
    var cb = false, cc = false;
    function b (n, next) {
      a.equal(n, 1);
      cb = true;
      a.falsy(cc);
      next(null, 'd');
    }
    function c (p, next) {
      a.deepEqual(p, ['a']);
      cc = true;
      a.ok(cb);
      next(null, 'b');
    }
    function d (err, results) {
      a.falsy(err);
      a.ok(cb);
      a.ok(cc);
      a.equal(Object.keys(results).length, 2);
      a.equal(results[0], 'd');
      a.equal(results[1], 'b');
      done();
    }
    contra.series([
      contra.curry(b, 1),
      contra.curry(c, ['a']),
    ], d);
  });
});

describe('each()', function () {
  it('should loop array concurrently', function (done) {
    var n = 0;
    function t (i, done) {
      n++;
      done();
    }
    function d (err, results) {
      a.equal(n, 2);
      a.falsy(err);
      a.falsy(results);
      done();
    }
    contra.each(['b','c'],t,d);
  });

  it('should loop object concurrently', function (done) {
    var n = 0;
    function t (i, done) {
      n++;
      done();
    }
    function d (err, results) {
      a.equal(n, 2);
      a.falsy(err);
      a.falsy(results);
      done();
    }
    contra.each({ a: 'b', b: 'c' }, t, d);
  });

  it('should short-circuit on error', function (done) {
    function t (i, done) {
      done(i);
    }
    function d (err, results) {
      a.ok(err);
      a.falsy(results);
      done();
    }
    contra.each(['b','c','e'],t,d);
  });

  it('should pass array keys to iterator', function(done){
    var items = ['a', 'c', 'e'];
    var keys = [];

    function iterator(item, key, done) {
      setTimeout(function() {
        keys.push(key);
        done();
      }, Math.random());
    }

    function d(err) {
      a.falsy(err);
      a.deepEqual(Object.keys(items), keys);
      done();
    }

    contra.each(items, iterator, d);
  });

  it('should pass object keys to iterator', function(done){
    var items = {a: 'b', c: 'd', e: 'f'};
    var keys = [];

    function iterator(item, key, done) {
      setTimeout(function() {
        keys.push(key);
        done();
      }, Math.random());
    }

    function d(err) {
      a.falsy(err);
      a.deepEqual(Object.keys(items), keys);
      done();
    }

    contra.each(items, iterator, d);
  });
});

describe('each.series()', function () {
  it('should loop array in a series', function (done) {
    var n = 0;
    function t (i, done) {
      n++;
      done();
    }
    function d (err, results) {
      a.equal(n, 2);
      a.falsy(err);
      a.falsy(results);
      done();
    }
    contra.each.series(['b','c'],t,d);
  });

  it('should loop object in a series', function (done) {
    var n = 0;
    function t (i, done) {
      n++;
      done();
    }
    function d (err, results) {
      a.equal(n, 2);
      a.falsy(err);
      a.falsy(results);
      done();
    }
    contra.each.series({ a: 'b', b: 'c' }, t, d);
  });

  it('should short-circuit on error', function (done) {
    var n = 0;
    function t (i, done) {
      n++;
      done(i);
    }
    function d (err, results) {
      a.equal(n, 1);
      a.ok(err);
      a.falsy(results);
      done();
    }
    contra.each.series(['b','c'],t,d);
  });
});

describe('map()', function () {
  it('should map array concurrently', function (done) {
    var n = 4;
    function t (i, done) {
      done(null, n++);
    }
    function d (err, results) {
      a.falsy(err);
      a.equal(Object.keys(results).length, 2);
      a.deepEqual(results, [4, 5]);
      done();
    }
    contra.map(['b','c'],t,d);
  });

  it('should map object concurrently', function (done) {
    var n = 4;
    function t (i, done) {
      done(null, n++);
    }
    function d (err, results) {
      a.falsy(err);
      a.equal(Object.keys(results).length, 2);
      a.deepEqual(results, { a: 4, b: 5 });
      done();
    }
    contra.map({ a: 'b', b: 'c' }, t, d);
  });

  it('should short-circuit on error', function (done) {
    function t (i, done) {
      done(i);
    }
    function d (err, results) {
      a.ok(err);
      a.falsy(results);
      done();
    }
    contra.map(['b','c','e'],t,d);
  });

  it('should pass array keys to iterator', function(done){
    var items = [
      'a',
      { m: 2 },
      'c',
      'foo',
      [2],
      [3, 6, 7]
    ];
    var keys = [];

    function iterator(item, key, done) {
      setTimeout(function() {
        keys.push(key);
        done();
      }, Math.random());
    }

    function d(err) {
      a.falsy(err);
      a.deepEqual(Object.keys(items), keys);
      done();
    }

    contra.map(items, iterator, d);
  });

  it('should pass object keys to iterator', function(done){
    var items = {
      a: 'a',
      b: { m: 2 },
      c: 'c',
      d: 'foo',
      e: [2],
      z: [3, 6, 7]
    };
    var keys = [];

    function iterator(item, key, done) {
      setTimeout(function() {
        keys.push(key);
        done();
      }, Math.random());
    }

    function d(err) {
      a.falsy(err);
      a.deepEqual(Object.keys(items), keys);
      done();
    }

    contra.map(items, iterator, d);
  });
});

describe('map.series()', function () {
  it('should map array in a series', function (done) {
    var n = 4;
    function t (i, done) {
      done(null, n++);
    }
    function d (err, results) {
      a.falsy(err);
      a.equal(Object.keys(results).length, 2);
      a.deepEqual(results, [4, 5]);
      done();
    }
    contra.map.series(['b','c'],t,d);
  });

  it('should map object in a series', function (done) {
    var n = 4;
    function t (i, done) {
      done(null, n++);
    }
    function d (err, results) {
      a.falsy(err);
      a.equal(Object.keys(results).length, 2);
      a.deepEqual(results, { a: 4, b: 5 });
      done();
    }
    contra.map.series({ a: 'b', b: 'c' }, t, d);
  });

  it('should fail on error', function (done) {
    function t (i, done) {
      done(i);
    }
    function d (err, results) {
      a.ok(err);
      a.falsy(results);
      done();
    }
    contra.map.series(['b','c'],t,d);
  });

  it('should short-circuit on error', function (done) {
    var n = 0;
    function t (i, done) {
      n++;
      done(i);
    }
    function d (err, results) {
      a.equal(n, 1);
      a.ok(err);
      a.falsy(results);
      done();
    }
    contra.map.series(['b','c'],t,d);
  });
});


describe('filter()', function () {
  it('should filter array concurrently', function (done) {
    function t (i, done) {
      done(null, typeof i === 'string');
    }
    function d (err, results) {
      a.falsy(err);
      a.equal(results.length, 2);
      a.deepEqual(results, ['b', 'c']);
      done();
    }
    contra.filter([1,2,'b',3,'c',5],t,d);
  });

  it('should filter object concurrently', function (done) {
    function t (i, done) {
      done(null, typeof i === 'string');
    }
    function d (err, results) {
      a.falsy(err);
      a.equal(Object.keys(results).length, 2);
      a.deepEqual(results, { a: 'b', b: 'c' });
      done();
    }
    contra.filter({ n: 3, a: 'b', b: 'c', c: 4, d: 5, e: 6 }, t, d);
  });

  it('should short-circuit on error', function (done) {
    function t (i, done) {
      done(i);
    }
    function d (err, results) {
      a.ok(err);
      a.falsy(results);
      done();
    }
    contra.filter(['b','c','e'],t,d);
  });

  it('should pass array keys to iterator', function(done){
    var items = ['a', 'c', 'e'];
    var keys = [];

    function iterator(item, key, done) {
      setTimeout(function() {
        keys.push(key);
        done();
      }, Math.random());
    }

    function d(err) {
      a.falsy(err);
      a.deepEqual(Object.keys(items), keys);
      done();
    }

    contra.filter(items, iterator, d);
  });

  it('should pass object keys to iterator', function(done){
    var items = {a: 'b', c: 'd', e: 'f'};
    var keys = [];

    function iterator(item, key, done) {
      setTimeout(function() {
        keys.push(key);
        done();
      }, Math.random());
    }

    function d(err) {
      a.falsy(err);
      a.deepEqual(Object.keys(items), keys);
      done();
    }

    contra.filter(items, iterator, d);
  });
});

describe('filter.series()', function () {
  it('should filter array in a series', function (done) {
    function t (i, done) {
      done(null, typeof i === 'string');
    }
    function d (err, results) {
      a.falsy(err);
      a.equal(results.length, 2);
      a.deepEqual(results, ['b', 'c']);
      done();
    }
    contra.filter.series([1,2,'b',3,'c',5],t,d);
  });

  it('should filter object in a series', function (done) {
    function t (i, done) {
      done(null, typeof i === 'string');
    }
    function d (err, results) {
      a.falsy(err);
      a.equal(Object.keys(results).length, 2);
      a.deepEqual(results, { a: 'b', b: 'c' });
      done();
    }
    contra.filter.series({ n: 3, a: 'b', b: 'c', c: 4, d: 5, e: 6 }, t, d);
  });
});

describe('queue()', function () {
  it('should queue things', function (done) {
    var ww;
    function w (job, done) {
      ww = true;
      a.equal(job, 'a');
      done();
    }
    function d (err) {
      a.falsy(err);
      a.ok(ww);
      done();
    }
    var q = contra.queue(w);
    q.push('a', d);
  });

  it('should pause and resume the queue', function (done) {
    var ww;
    function w (job, cb) {
      ww = true;
      a.equal(job, 'a');
      cb();
    }
    function d (err) {
      a.falsy(err);
      a.ok(ww);
      done();
    }
    var q = contra.queue(w);
    q.pause();
    q.push('a', d);
    a.equal(q.pending.length, 1);
    q.resume();
  });

  it('should forward errors', function (done) {
    var ww;
    function w (job, done) {
      ww = true;
      a.equal(job, 'a');
      done('e');
    }
    function d (err) {
      a.equal(err, 'e');
      a.ok(ww);
      done();
    }
    var q = contra.queue(w);
    q.push('a', d);
  });

  it('should emit drain', function (done) {
    var ww;
    function w () {
      a.fail(null, null, 'invoked worker');
    }
    function d () {
      a.fail(null, null, 'invoked job completion');
    }
    function drained () {
      a.falsy(ww);
      done();
    }
    var q = contra.queue(w);
    q.on('drain', drained);
    q.push([], d);
  });
});

describe('emitter()', function () {
  it('should just work', function (done) {
    var thing = { foo: 'bar' };

    contra.emitter(thing);

    a.ok(thing.emit);
    a.ok(thing.on);
    a.ok(thing.once);
    a.ok(thing.off);

    thing.on('something', function (b, c) {
      a.equal(b, 'a');
      a.equal(c, 2);
      done();
    });

    thing.emit('something', 'a', 2);
  });

  it('should just work without arguments', function (done) {
    var thing = contra.emitter();

    a.ok(thing.emit);
    a.ok(thing.on);
    a.ok(thing.once);
    a.ok(thing.off);

    thing.on('something', function (b, c) {
      a.equal(b, 'a');
      a.equal(c, 2);
      done();
    });

    thing.emit('something', 'a', 2);
  });

  it('should run once() listeners once', function (done) {
    var thing = { foo: 'bar' };
    var c = 0;

    contra.emitter(thing);

    function me () {
      c++;
      a.ok(c < 2);
      done();
    }

    thing.once('something', me);
    thing.on('something', function () {
      a.equal(c, 1);
    });

    thing.emit('something');
    thing.emit('something');
  });

  it('shouldn\'t blow up on careless off() calls', function () {
    var thing = { foo: 'bar' };

    contra.emitter(thing);

    // the thing event type doesn't even exist.
    thing.off('something', function () {});
  });

  it('should turn off on() listeners', function (done) {
    var thing = { foo: 'bar' };

    contra.emitter(thing);

    function me () {
      a.fail(null, null, 'invoked on() listener');
    }

    thing.on('something', me);
    thing.off('something', me);
    thing.on('something', done);
    thing.emit('something');
  });

  it('should turn off once() listeners', function (done) {
    var thing = { foo: 'bar' };

    contra.emitter(thing);

    function me () {
      a.fail(null, null, 'invoked once() listener');
    }

    thing.once('something', me);
    thing.off('something', me);
    thing.on('something', done);
    thing.emit('something');
  });

  it('should blow up on error if no listeners', function (done) {
    var thing = { foo: 'bar' };

    contra.emitter(thing);

    a.throws(thing.emit.bind(thing, 'error'));
    done();
  });

  it('should work just fine with at least one error listener', function (done) {
    var thing = { foo: 'bar' };

    contra.emitter(thing);

    thing.on('error', function () {
      done();
    });
    a.doesNotThrow(thing.emit.bind(thing, 'error'));
  });
});
