import { ucs2decode, fixChineseSpace, escapeRegExp, mergeOptions } from './utils';
import data from '../../data/charmap.json';

let charmap = {};
const defaultOptions = {
  unknown: '[?]',
  replace: [],
  replaceAfter: [],
  ignore: [],
  trim: true,
};
let configOptions = {};

/* istanbul ignore next */
export const replaceStr = (source, replace) => {
  let str = source;
  for (const item of replace) {
    if (item[0] instanceof RegExp) {
      if (!item[0].global) {
        item[0] = new RegExp(item[0].toString().replace(/^\/|\/$/), `${item[0].flags}g`);
      }
    } else if (typeof item[0] === 'string') {
      item[0] = new RegExp(escapeRegExp(item[0]), 'g');
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
  const opt = options ? mergeOptions(defaultOptions, options) : mergeOptions(defaultOptions, configOptions);
  let str = String(sourceStr);
  let i, j, splitted, result, ignore, ord;
  if (opt.ignore instanceof Array && opt.ignore.length > 0) {
    for (i in opt.ignore) {
      splitted = str.split(opt.ignore[i]);
      result = [];
      for (j in splitted) {
        ignore = opt.ignore.slice(0);
        ignore.splice(i, 1);
        result.push(transliterate(splitted[j], mergeOptions(opt, { ignore, trim: false })));
      }
      return result.join(opt.ignore[i]);
    }
  }
  str = replaceStr(str, opt.replace);
  str = fixChineseSpace(str);
  const strArr = ucs2decode(str);
  const strArrNew = [];

  for (ord of strArr) {
    // These characters are also transliteratable. Will improve it later if needed
    if (ord > 0xffff) {
      strArrNew.push(opt.unknown);
    } else {
      const offset = ord >> 8;
      if (typeof charmap[offset] === 'undefined') {
        charmap[offset] = data[offset] || [];
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

transliterate.setCharmap = (customCharmap) => {
  charmap = customCharmap || charmap;
  return charmap;
};

transliterate.config = (options) => {
  if (options === undefined) {
    return configOptions;
  }
  configOptions = mergeOptions(defaultOptions, options);
  return configOptions;
};

export default transliterate;
