'use strict';

var contra = typeof contra !== 'undefined' ? contra : require('..');
var a = typeof assert !== 'undefined' ? assert : require('assert');

a.falsy = function (value, message) { a.equal(false, !!value, message); };

describe('concurrent()', function () {
  it('should return the results as expected', function (done) {
    var items = {
      a: 'a',
      b: { m: 2 },
      c: 'c',
      d: 'foo',
      e: [2],
      z: [3, 6, 7]
    };
    var tasks = {};
    Object.keys(items).forEach(function (key) {
      tasks[key] = fn(items[key]);
    });

    function fn (result) {
      return function (d) {
        setTimeout(function () {
          d(null, result);
        }, Math.random());
      };
    }

    function d (err, results) {
      a.deepEqual(results, items);
      done();
    }

    contra.concurrent(tasks, 4, d);
  });
});

describe('map()', function () {
  it('should return the results as expected', function (done) {
    var items = {
      a: 'a',
      b: { m: 2 },
      c: 'c',
      d: 'foo',
      e: [2],
      z: [3, 6, 7]
    };

    function mapper (item, done) {
      setTimeout(function () {
        done(null, item);
      }, Math.random());
    }

    function d (err, results) {
      a.falsy(err);
      a.deepEqual(results, items);
      done();
    }

    contra.map(items, 4, mapper, d);
  });
});
