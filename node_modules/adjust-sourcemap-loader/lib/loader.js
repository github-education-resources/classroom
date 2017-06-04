'use strict';

var path = require('path');

var loaderUtils = require('loader-utils'),
    camelcase   = require('camelcase'),
    defaults    = require('lodash.defaults');

var PACKAGE_NAME = require('../package.json').name;

var process = require('./process');

/**
 * Webpack loader that manipulates the source-map of a preceding loader.
 * @this {object} The loader context
 * @param {string} content The content
 * @param {object} sourceMap The source-map
 * @returns {string|String}
 */
function loader(content, sourceMap) {
  /* jshint validthis:true */

  // loader result is cacheable
  this.cacheable();

  // webpack 1: prefer loader query, else options object
  // webpack 2; prefer loader options
  var options = defaults({sep: path.sep}, loaderUtils.getOptions(this), this.options[camelcase(PACKAGE_NAME)]);

  // process the source-map
  var outputMap = process(this, options, sourceMap);

  // need to use callback when there are multiple arguments
  this.callback(null, content, outputMap);
}

module.exports = loader;