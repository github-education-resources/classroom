'use strict';

var concurrent = require('./concurrent');
var SERIAL = require('./SERIAL');

module.exports = function series (tasks, done) {
  concurrent(tasks, SERIAL, done);
};
