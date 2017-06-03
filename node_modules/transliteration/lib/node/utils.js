'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
// Credit: https://github.com/bestiejs/punycode.js/blob/master/LICENSE-MIT.txt
const ucs2decode = exports.ucs2decode = string => {
  const output = [];
  let counter = 0;
  while (counter < string.length) {
    const value = string.charCodeAt(counter++);
    if (value >= 0xD800 && value <= 0xDBFF && counter < string.length) {
      // high surrogate, and there is a next character
      const extra = string.charCodeAt(counter++);
      if ((extra & 0xFC00) === 0xDC00) {
        // low surrogate
        output.push(((value & 0x3FF) << 10) + (extra & 0x3FF) + 0x10000);
      } else {
        // unmatched surrogate; only append this code unit, in case the next
        // code unit is the high surrogate of a surrogate pair
        output.push(value);
        counter--;
      }
    } else {
      output.push(value);
    }
  }
  return output;
};

// add additional space between Chinese and English.
const fixChineseSpace = exports.fixChineseSpace = str => str.replace(/([^\u4e00-\u9fa5\W])([\u4e00-\u9fa5])/g, '$1 $2');

// Escape regular expression string
const escapeRegExp = exports.escapeRegExp = sourceStr => {
  let str = sourceStr;
  if (str === null || str === undefined) {
    str = '';
  }
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&');
};

/**
 * Merge configuration options. Use deep merge if option is an array.
 */
const mergeOptions = exports.mergeOptions = (defaultOptions, options) => {
  const result = {};
  const opt = options || {};
  for (const key in defaultOptions) {
    result[key] = opt[key] === undefined ? defaultOptions[key] : opt[key];
    if (result[key] instanceof Array) {
      result[key] = result[key].slice(0);
    }
    // convert object version of the 'replace' option into array version
    if (key === 'replace' && typeof result[key] === 'object' && !(result[key] instanceof Array)) {
      const replaceArr = [];
      for (const source in result.replace) {
        replaceArr.push([source, result.replace[source]]);
      }
      result.replace = replaceArr;
    }
  }
  return result;
};

const parseCmdEqualOption = exports.parseCmdEqualOption = option => {
  let opt = option || {};
  const replaceToken = '__REPLACE_TOKEN__';
  let tmpToken = replaceToken;
  let result;
  while (opt.indexOf(tmpToken) > -1) {
    tmpToken += tmpToken;
  }
  // escape for \\=
  if (opt.match(/[^\\]\\\\=/)) {
    opt = opt.replace(/([^\\])\\\\=/g, '$1\\=');
    // escape for \=
  } else if (opt.match(/[^\\]\\=/)) {
    opt = opt.replace(/([^\\])\\=/g, `$1${tmpToken}`);
  }
  result = opt.split('=').map(value => value.replace(new RegExp(tmpToken, 'g'), '='));
  if (result.length !== 2) {
    result = false;
  }
  return result;
};