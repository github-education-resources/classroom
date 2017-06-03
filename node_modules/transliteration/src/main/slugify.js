import transliterate from './transliterate';
import { escapeRegExp, mergeOptions } from './utils';

// Slugify
const defaultOptions = {
  lowercase: true,
  separator: '-',
  replace: [],
  replaceAfter: [],
  ignore: [],
};
let configOptions = {};

const slugify = (str, options) => {
  const opt = options ? mergeOptions(defaultOptions, options) : mergeOptions(defaultOptions, configOptions);
  // remove leading and trailing separators
  const sep = escapeRegExp(opt.separator);
  opt.replaceAfter.push([/[^a-zA-Z0-9]+/g, opt.separator], [new RegExp(`^(${sep})+|(${sep})+$`, 'g'), '']);
  const transliterateOptions = { replaceAfter: opt.replaceAfter, replace: opt.replace, ignore: opt.ignore };
  let slug = transliterate(str, transliterateOptions);
  if (opt.lowercase) {
    slug = slug.toLowerCase();
  }
  return slug;
};

slugify.config = (options) => {
  if (options === undefined) {
    return configOptions;
  }
  configOptions = mergeOptions(defaultOptions, options);
  return configOptions;
};

export default slugify;
