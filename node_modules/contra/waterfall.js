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
