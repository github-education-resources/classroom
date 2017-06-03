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
