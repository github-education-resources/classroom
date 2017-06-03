'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.replaceStr = undefined;

var _utils = require('./utils');

var _charmap = require('../../data/charmap.json');

var _charmap2 = _interopRequireDefault(_charmap);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

let charmap = {};
const defaultOptions = {
  unknown: '[?]',
  replace: [],
  replaceAfter: [],
  ignore: [],
  trim: true
};
let configOptions = {};

/* istanbul ignore next */
const replaceStr = exports.replaceStr = (source, replace) => {
  let str = source;
  for (const item of replace) {
    if (item[0] instanceof RegExp) {
      if (!item[0].global) {
        item[0] = new RegExp(item[0].toString().replace(/^\/|\/$/), `${item[0].flags}g`);
      }
    } else if (typeof item[0] === 'string') {
      item[0] = new RegExp((0, _utils.escapeRegExp)(item[0]), 'g');
    }
    if (item[0] instanceof RegExp) {
      str = str.replace(item[0], item[1]);
    }
  }
  return str;
};

/**
 * @param {string} sourceStr The string which is being transliterated
 * @param {object} options options
 */
/* istanbul ignore next */
const transliterate = (sourceStr, options) => {
  const opt = options ? (0, _utils.mergeOptions)(defaultOptions, options) : (0, _utils.mergeOptions)(defaultOptions, configOptions);
  let str = String(sourceStr);
  let i, j, splitted, result, ignore, ord;
  if (opt.ignore instanceof Array && opt.ignore.length > 0) {
    for (i in opt.ignore) {
      splitted = str.split(opt.ignore[i]);
      result = [];
      for (j in splitted) {
        ignore = opt.ignore.slice(0);
        ignore.splice(i, 1);
        result.push(transliterate(splitted[j], (0, _utils.mergeOptions)(opt, { ignore, trim: false })));
      }
      return result.join(opt.ignore[i]);
    }
  }
  str = replaceStr(str, opt.replace);
  str = (0, _utils.fixChineseSpace)(str);
  const strArr = (0, _utils.ucs2decode)(str);
  const strArrNew = [];

  for (ord of strArr) {
    // These characters are also transliteratable. Will improve it later if needed
    if (ord > 0xffff) {
      strArrNew.push(opt.unknown);
    } else {
      const offset = ord >> 8;
      if (typeof charmap[offset] === 'undefined') {
        charmap[offset] = _charmap2.default[offset] || [];
      }
      ord &= 0xff;
      const text = charmap[offset][ord];
      if (typeof text === 'undefined' || text === null) {
        strArrNew.push(opt.unknown);
      } else {
        strArrNew.push(charmap[offset][ord]);
      }
    }
  }
  // trim spaces at the beginning and ending of the string
  if (opt.trim && strArrNew.length > 1) {
    opt.replaceAfter.push([/(^ +?)|( +?$)/g, '']);
  }
  let strNew = strArrNew.join('');

  strNew = replaceStr(strNew, opt.replaceAfter);
  return strNew;
};

transliterate.setCharmap = customCharmap => {
  charmap = customCharmap || charmap;
  return charmap;
};

transliterate.config = options => {
  if (options === undefined) {
    return configOptions;
  }
  configOptions = (0, _utils.mergeOptions)(defaultOptions, options);
  return configOptions;
};

exports.default = transliterate;