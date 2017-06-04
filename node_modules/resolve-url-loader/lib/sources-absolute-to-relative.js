/*
 * MIT License http://opensource.org/licenses/MIT
 * Author: Ben Holloway @bholloway
 */
'use strict';

var path = require('path');

/**
 * Convert the given array of absolute URIs to relative URIs (in place).
 * @param {Array} sources The source map sources array
 * @param {string} basePath The base path to make relative to
 */
module.exports = function sourcesAbsoluteToRelative(sources, basePath) {
  sources.forEach(sourceToRelative);

  function sourceToRelative(value, i, array) {
    array[i] = path.relative(basePath, value);
  }
};