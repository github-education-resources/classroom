'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _transliterate = require('./transliterate');

var _transliterate2 = _interopRequireDefault(_transliterate);

var _utils = require('./utils');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// Slugify
const defaultOptions = {
  lowercase: true,
  separator: '-',
  replace: [],
  replaceAfter: [],
  ignore: []
};
let configOptions = {};

const slugify = (str, options) => {
  const opt = options ? (0, _utils.mergeOptions)(defaultOptions, options) : (0, _utils.mergeOptions)(defaultOptions, configOptions);
  // remove leading and trailing separators
  const sep = (0, _utils.escapeRegExp)(opt.separator);
  opt.replaceAfter.push([/[^a-zA-Z0-9]+/g, opt.separator], [new RegExp(`^(${sep})+|(${sep})+$`, 'g'), '']);
  const transliterateOptions = { replaceAfter: opt.replaceAfter, replace: opt.replace, ignore: opt.ignore };
  let slug = (0, _transliterate2.default)(str, transliterateOptions);
  if (opt.lowercase) {
    slug = slug.toLowerCase();
  }
  return slug;
};

slugify.config = options => {
  if (options === undefined) {
    return configOptions;
  }
  configOptions = (0, _utils.mergeOptions)(defaultOptions, options);
  return configOptions;
};

exports.default = slugify;