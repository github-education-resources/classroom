# Transliteration

[![Build Status](https://travis-ci.org/andyhu/node-transliteration.svg)](https://travis-ci.org/andyhu/node-transliteration)
[![Dependencies](https://img.shields.io/david/andyhu/node-transliteration.svg)](https://github.com/andyhu/node-transliteration/blob/master/package.json)
[![Dev Dependencies](https://img.shields.io/david/dev/andyhu/node-transliteration.svg)](https://github.com/andyhu/node-transliteration/blob/master/package.json)
[![Coverage Status](https://coveralls.io/repos/github/andyhu/node-transliteration/badge.svg?branch=master)](https://coveralls.io/github/andyhu/node-transliteration?branch=master)
[![Codacy grade](https://img.shields.io/codacy/grade/a752bacd344a4b6b94b2dcbe6debea1f.svg)](https://github.com/andyhu/node-transliteration)
[![NPM Version](https://img.shields.io/npm/v/transliteration.svg)](https://www.npmjs.com/package/transliteration)
[![Bower Version](https://img.shields.io/bower/v/transliteration.svg)](https://github.com/andyhu/node-transliteration)
[![NPM Download](https://img.shields.io/npm/dm/transliteration.svg)](https://www.npmjs.com/package/transliteration)
[![License](https://img.shields.io/npm/l/transliteration.svg)](https://github.com/andyhu/node-transliteration/blob/master/LICENSE.txt)
[![PRs](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/andyhu/node-transliteration)

[![Sauce Test Status](https://saucelabs.com/browser-matrix/node-transliteration.svg)](https://saucelabs.com/u/node-transliteration)

Transliteration module for node.js, browser and command line. It provides the ability to transliterate unicode characters into corresponding pure ASCII, so it can be safely displayed, used as URL slug or as file name.

This module also provide a slugify function with flexible configurations.

## Install in Node.js

```bash
npm install transliteration --save
```
```javascript
var transliteration = require('transliteration');
var slug = tr.slugify;
var tr = transliteration.transliterate
//import { transliterate as tr, slugify as slug } from 'transliteration'; /* For ES6 syntax */

tr('你好, world!'); // Ni Hao , world!
slugify('你好, world!'); // ni-hao-world
```

## Download the library and use in browser
```bash
# Install bower if not already installed
# npm install bower -g
bower install transliteration
```
```html
<html>
<head>
  <script src="bower_components/transliteration/transliteration.min.js"></script>
</head>
<body>
  <script>
    transl('你好, world!'); // Ni Hao , world!
    slugify('你好, world!'); // ni-hao-world
  </script>
</body>
</html>
```

### Browser compatibility
`transliteration` module should support all major browsers including IE 6-8 (with `es5-shim`)

## Install command line tools globally

```bash
npm install transliteration -g

transliterate 你好 # Ni Hao
slugify 你好 # ni-hao
```

## Breaking changes since 1.0.0
Please note that the code has been entirely refactored since version 1.0.0. Be careful when you plan to upgrade from v0.1.x or v0.2.x to v1.0.x

__Changes:__
* This module has been rewritten with ES6, means that it cannot be directly `require`d in the old way. You can either use `require('transliteration').transliterate` or ES6 import `import { transliterate as tr, slugify as slug } from 'transliteration'` to load the module.
* The `options` parameter of `transliterate` now is an `Object` (In 0.1.x it's a string `unknown`).
* Unknown string will be transliterated as `[?]` instead of `?`.
* In browser, global variables has changed to `window.transl` and `windnow.slugify`. Other global variables are removed.

## Usage

### transliterate(str, options)

Transliterate the string `str`. Characters which this module doesn't recognise will be converted to the character in the `unknown` parameter, defaults to `[?]`.

__Options:__
```javascript
{
  /* Unicode characters that are not in the database will be replaced with `unknown` */
  unknown: '[?]', // default: [?]
  /* Custom replacement of the strings before transliteration */
  replace: [[source1, target1], [source2, target2], ...], // default: []
  /* Strings in the ignore list will be bypassed from transliteration */
  ignore: [str1, str2] // default: []
}
```

__Example__
```javascript
var tr = require('transliteration').transliterate;
// import { tr } from 'transliteration'; /* For ES6 syntax */
tr('你好，世界'); // Ni Hao , Shi Jie
tr('Γεια σας, τον κόσμο'); // Geia sas, ton kosmo
tr('안녕하세요, 세계'); // annyeonghaseyo, segye
tr('你好，世界', { replace: [['你', 'You']], ignore: ['好'] }) // You 好, Shi Jie
// or use configurations
tr({ replace: [['你', 'You']], ignore: ['好'] });
tr('你好，世界') // You 好, Shi Jie
// get configurations
console.log(tr.config());
```

### slugify(str, options)

Converts unicode string to slugs. So it can be safely used in URL or file name.

__Options:__
```javascript
{
  /* Whether to force slags to be lowercased */
  lowercase: false, // default: true
  /* Separator of the slug */
  separator: '-', // default: '-'
  /* Custom replacement of the strings before transliteration */
  replace: [[source1, target1], [source2, target2], ...], // default: []
  /* Strings in the ignore list will be bypassed from transliteration */
  ignore: [str1, str2] // default: []
}
```
If no `options` parameter provided it will use the above default values.

__Example:__
```javascript
var slugify = require('transliteration').slugify; // import { slugify } from 'transliteration'; /* For ES6 syntax */
slugify('你好，世界'); // ni-hao-shi-jie
slugify('你好，世界', { lowercase: false, separator: '_' }); // Ni_Hao_Shi_Jie
slugify('你好，世界', { replace: [['你好', 'Hello'], ['世界', 'world']], separator: '_' }); // hello_world
slugify('你好，世界', { ignore: ['你好'] }); // 你好shi-jie
// or use configurations
slugify.config({ lowercase: false, separator: '_' });
slugify('你好，世界'); // Ni_Hao_Shi_Jie
// get configurations
console.log(slugify.config());
```

### Usage in browser
`Transliteration` module can be run in the browser as well.

It supports AMD / CommonJS standard or it could be just loaded as global variables (UMD).

When use in browser, by default it will create global variables under `window` object:
```javascript
transl('你好, World'); // window.transl
// or
slugify('Hello, 世界'); // window.slugify
```
If the name of the variables conflict with other libraries in your project or you prefer not to use global variables, you can then call noConfilict() before loading other libraries which contails the possible conflict.:

__Load the library globally__

```javascript
var tr = transl.noConflict();
console.log(transl); // undefined
tr('你好, World'); // Ni Hao , World
var slug = slugify.noConfilict();
slug('你好, World'); // ni-hao-world
console.log(slugify); // undefined
```

For detailed example, please check the demo at [example.html](http://rawgit.com/andyhu/node-transliteration/master/demo/example.html).

### Usage in command line
```
➜  ~ transliterate --help
Usage: transliterate <unicode> [options]

Options:
  --version      Show version number                                                       [boolean]
  -u, --unknown  Placeholder for unknown characters                        [string] [default: "[?]"]
  -r, --replace  Custom string replacement                                     [array] [default: []]
  -i, --ignore   String list to ignore                                         [array] [default: []]
  -h, --help     Show help                                                                 [boolean]

Examples:
  transliterate "你好, world!" -r 好=good -r          Replace `,` into `!` and `world` into
  "world=Shi Jie"                                     `shijie`.
                                                      Result: Ni good, Shi Jie!
  transliterate "你好，世界!" -i 你好 -i ，           Ignore `你好` and `，`.
                                                      Result: 你好，Shi Jie !
                                                      Result: 你好,world!
```

```
➜  ~ slugify --help
Usage: slugify <unicode> [options]

Options:
  --version        Show version number                                                     [boolean]
  -l, --lowercase  Use lowercase                                           [boolean] [default: true]
  -s, --separator  Separator of the slug                                     [string] [default: "-"]
  -r, --replace    Custom string replacement                                   [array] [default: []]
  -i, --ignore     String list to ignore                                       [array] [default: []]
  -h, --help       Show help                                                               [boolean]

Examples:
  slugify "你好, world!" -r 好=good -r "world=Shi     Replace `,` into `!` and `world` into
  Jie"                                                `shijie`.
                                                      Result: ni-good-shi-jie
  slugify "你好，世界!" -i 你好 -i ，                 Ignore `你好` and `，`.
                                                      Result: 你好，shi-jie

```

### Notice about Japanese language
`Transliteration` support nearly every common languages including CJK (Chinese, Japanese and Korean). Note that Kanji characters in Japanese will be translierated as Chinese Pinyin. I couldn't find a better way to distinguash Chinese Hanzi and Japanese Kanji. So if you would like to romanize Japanese Kanji, please consider [kuroshiro](https://github.com/hexenq/kuroshiro.js).
