<img src="assets/postcss.png" alt="PostCSS Logo" width="200" height="200"/>

# PostCSS Smart Import <br/>[![Sponsored by][sponsor-img]][sponsor] [![Version][npm-version-img]][npm] [![Downloads][npm-downloads-img]][npm] [![Build Status Unix][travis-img]][travis] [![Build Status Windows][appveyor-img]][appveyor] [![Dependencies][deps-img]][deps]

[PostCSS] plugin for loading/including other files (transform `@import` rules by inlining content) and quering/referring assets (referred in `url()` functions).

[PostCSS]: https://github.com/postcss/postcss
[sponsor-img]: https://img.shields.io/badge/Sponsored%20by-Sebastian%20Software-692446.svg
[sponsor]: https://www.sebastian-software.de
[deps]: https://david-dm.org/sebastian-software/postcss-smart-import
[deps-img]: https://david-dm.org/sebastian-software/postcss-smart-import.svg
[npm]: https://www.npmjs.com/package/postcss-smart-import
[npm-downloads-img]: https://img.shields.io/npm/dm/postcss-smart-import.svg
[npm-version-img]: https://img.shields.io/npm/v/postcss-smart-import.svg
[travis-img]: https://img.shields.io/travis/sebastian-software/postcss-smart-import/master.svg?branch=master&label=unix%20build
[appveyor-img]: https://img.shields.io/appveyor/ci/swernerx/postcss-smart-import-0se3r/master.svg?label=windows%20build
[travis]: https://travis-ci.org/sebastian-software/postcss-smart-import
[appveyor]: https://ci.appveyor.com/project/swernerx/postcss-smart-import-0se3r/branch/master

Think of `postcss-import` + `postcss-url` + `postcss-assets`.

This plugin can consume local files, `node_modules` or `web_modules`.
To resolve path of an `@import` rule, it can look into root directory (by default `process.cwd()`), `web_modules`, `node_modules`
or local modules. _When importing a module, it will look for `index.[css,sss,scss,sass]` or file referenced in `package.json` in the `style`, `browser`, `main` fields._
You can also provide manually multiples paths where to look at.





## Links

- [GitHub](https://github.com/sebastian-software/postcss-smart-import)
- [NPM](https://www.npmjs.com/package/postcss-smart-import)


**Notes:**

- **This plugin should probably be used as the first plugin of your list.
This way, other plugins will work on the AST as if there were only a single file
to process, and will probably work as you can expect**.
- This plugin works great with
[postcss-url](https://github.com/postcss/postcss-url) plugin,
which will allow you to adjust assets `url()` (or even inline them) after
inlining imported files.
- In order to optimize output, **this plugin will only import a file once**.
Tests are made from the path & the content of imported files (using a hash
table).
If this behavior is not what you want, look at `skipDuplicates` option


## Installation

```console
$ npm install postcss-smart-import
```

## Usage

If your stylesheets are not in the same place where you run postcss
(`process.cwd()`), you will need to use `from` option to make relative imports
work from input dirname.

```js
// dependencies
var fs = require("fs")
var postcss = require("postcss")
var smartImport = require("postcss-smart-import")

// css to be processed
var css = fs.readFileSync("css/input.css", "utf8")

// process css
postcss()
  .use(smartImport())
  .process(css, {
    // `from` option is required so relative import can work from input dirname
    from: "css/input.css"
  })
  .then(function (result) {
    var output = result.css

    console.log(output)
  })
```

Using this `input.css`:

```css
/* can consume `node_modules`, `web_modules` or local modules */
@import "cssrecipes-defaults"; /* == @import "./node_modules/cssrecipes-defaults/index.css"; */
@import "normalize.css"; /* == @import "./node_modules/normalize.css/normalize.css"; */

@import "css/foo.css"; /* relative to stylesheets/ according to `from` option above */

body {
  background: black;
}
```

will give you:

```css
/* ... content of ./node_modules/cssrecipes-defaults/index.css */
/* ... content of ./node_modules/normalize.css/normalize.css */

/* ... content of foo.css */

body {
  background: black;
}
```

Checkout [tests](test) for more examples.

### Options

#### `root`

Type: `String`  
Default: `process.cwd()` or _dirname of
[the postcss `from`](https://github.com/postcss/postcss#node-source)_

Define the root where to resolve path (eg: place where `node_modules` are).
Should not be used that much.  
_Note: nested `@import` will additionally benefit of the relative dirname of
imported files._

#### `path`

Type: `String|Array`  
Default: `[]`

A string or an array of paths in where to look for files.

#### `transform`

Type: `Function`  
Default: `null`

A function to transform the content of imported files. Take one argument (file
  content) and should return the modified content or a resolved promise with it.
`undefined` result will be skipped.

```js
transform: function(css) {
  return postcss([somePlugin]).process(css).then(function(result) {
    return result.css;
  });
}
```

#### `plugins`

Type: `Array`  
Default: `undefined`

An array of plugins to be applied on each imported files.

#### `onImport`

Type: `Function`  
Default: `null`

Function called after the import process. Take one argument (array of imported
files).

#### `resolve`

Type: `Function`  
Default: `null`

You can overwrite the default path resolving way by setting this option.
This function gets `(id, basedir, importOptions)` arguments and returns full
path, array of paths or promise resolving paths.
You can use [resolve](https://github.com/substack/node-resolve) for that.

#### `load`

Type: `Function`  
Default: null

You can overwrite the default loading way by setting this option.
This function gets `(filename, importOptions)` arguments and returns content or
promised content.

#### `skipDuplicates`

Type: `Boolean`  
Default: `true`

By default, similar files (based on the same content) are being skipped.
It's to optimize output and skip similar files like `normalize.css` for example.
If this behavior is not what you want, just set this option to `false` to
disable it.

#### `addDependencyTo`

Type: `Object`  
Default: null

An object with `addDependency()` method, taking file path as an argument.
Called whenever a file is imported.
You can use it for hot-reloading in webpack `postcss-loader` like this:

```js
var smartImport = require("postcss-smart-import")

postcss: function(webpack) {
  return [
    smartImport({
      addDependencyTo: webpack
      /* Is equivalent to
      onImport: function (files) {
        files.forEach(this.addDependency)
      }.bind(webpack)
      */
    })
  ]
}
```

#### Example with some options

```js
var postcss = require("postcss")
var smartImport = require("postcss-smart-import")

postcss()
  .use(smartImport({
    path: ["src/css"],
    transform: require("css-whitespace")
  }))
  .process(cssString)
  .then(function (result) {
    var css = result.css
  })
```

---

## Contributing

* Pull requests and Stars are always welcome.
* For bugs and feature requests, please create an issue.
* Pull requests must be accompanied by passing automated tests (`$ npm test`).

## [License](license)



## Copyright

<img src="https://raw.githubusercontent.com/sebastian-software/s15e-javascript/master/assets/sebastiansoftware.png" alt="Sebastian Software GmbH Logo" width="250" height="200"/>

Copyright 2016-2017<br/>[Sebastian Software GmbH](http://www.sebastian-software.de)
