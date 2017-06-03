(function (Object, Array) {
  'use strict';
  if (!Array.prototype.forEach) {
    Array.prototype.forEach = function (fn, ctx) {
      if (this === void 0 || this === null || typeof fn !== 'function') {
        throw new TypeError();
      }
      var t = this;
      var len = t.length;
      for (var i = 0; i < len; i++) {
        if (i in t) { fn.call(ctx, t[i], i, t); }
      }
    };
  }
  if (!Array.prototype.indexOf) {
    Array.prototype.indexOf = function (what, start) {
      if (this === undefined || this === null) {
        throw new TypeError();
      }
      var length = this.length;
      start = +start || 0;
      if (Math.abs(start) === Infinity) {
        start = 0;
      } else if (start < 0) {
        start += length;
        if (start < 0) { start = 0; }
      }
      for (; start < length; start++) {
        if (this[start] === what) {
          return start;
        }
      }
      return -1;
    };
  }
  if (!Array.prototype.filter) {
    Array.prototype.filter = function (fn, ctx) {
      var f = [];
      this.forEach(function (v, i, t) {
        if (fn.call(ctx, v, i, t)) { f.push(v); }
      }, ctx);
      return f;
    };
  }
  if (!Function.prototype.bind) {
    Function.prototype.bind = function (context) {
      if (typeof this !== 'function') {
        throw new TypeError('Function.prototype.bind - what is trying to be bound is not callable');
      }
      var curried = Array.prototype.slice.call(arguments, 1);
      var original = this;
      var NoOp = function () {};
      var bound = function () {
        var ctx = this instanceof NoOp && context ? this : context;
        var args = curried.concat(Array.prototype.slice.call(arguments));
        return original.apply(ctx, args);
      };
      NoOp.prototype = this.prototype;
      bound.prototype = new NoOp();
      return bound;
    };
  }
  if (!Object.keys) {
    Object.keys = function (o) {
      var keys = [];
      for (var k in o) {
        if (o.hasOwnProperty(k)) {
          keys.push(k);
        }
      }
      return keys;
    };
  }
  if (Object.defineProperty) { // test for IE8 partial implementation
    try { Object.defineProperty({}, 'x', {}); } catch (e) { Object.definePropertyPartial = true; }
  }
})(Object, Array);
