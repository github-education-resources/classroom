# rails-erb-loader

[![npm version](https://img.shields.io/npm/v/rails-erb-loader.svg?style=flat-square)](https://www.npmjs.com/package/rails-erb-loader)
[![npm downloads](https://img.shields.io/npm/dm/rails-erb-loader.svg?style=flat-square)](https://npm-stat.com/charts.html?package=rails-erb-loader&from=2016-11-07)
[![Standard - JavaScript Style Guide](https://img.shields.io/badge/code%20style-standard-brightgreen.svg?style=flat-square)](http://standardjs.com/)
[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)

> Embedded Ruby (`.erb`) webpack loader for Ruby projects.

Compiles Embedded Ruby template files in any Ruby project. Files are built using either the `Erubis` or `ERB` gem.

## Table of Contents
- [Install](#install)
- [Usage](#usage)
- [Configuration](#configuration)
  - [Options](#options)
  - [Dependencies](#dependencies)
- [Contribute](#contribute)
- [License](#license)

## Install

### npm

```console
$ npm install rails-erb-loader --save-dev
```

### yarn

```console
$ yarn add -D rails-erb-loader
```

## Usage

Add `rails-erb-loader` to your rules.

```js
// webpack.config.js

module.exports = {
    module: {
      rules: [
        {
          test: /\.erb$/,
          enforce: 'pre',
          loader: 'rails-erb-loader'
        },
      ]
    }
  }
};
```

Now you can use `.erb` files in your project, for example:

`app/assets/javascripts/UserFormFields.jsx.erb`
```erb
/* rails-erb-loader-dependencies models/user models/image */

export default function UserFormFields() {
  return (
    <div>
      <label htmlFor='avatar'>
        Avatar
      </label>
      <ImageField id='avatar' maxSize={<%= Image::MAX_SIZE %>} />
      <label htmlFor='name'>
        Name
      </label>
      <input
        id='name'
        type='text'
        maxLength={<%= User::MAX_NAME_LENGTH %>}
      />
      <label htmlFor='age'>
        Age
      </label>
      <input
        id='age'
        type='number'
        min={<%= User::MIN_AGE %>}
        max={<%= User::MAX_AGE %>}
      />
    </div>
  )
}
```

## Configuration

### Options

Can be configured with [UseEntry#options](https://webpack.js.org/configuration/module/#useentry).

| Option | Default | Description |
| ------ | ------- | ----------- |
| `dependenciesRoot` | `"app"` | The root of your Rails project, relative to webpack's working directory. |
| `engine` | `"erb"` | ERB Template engine, `"erubi"`, `"erubis"` and `"erb"` are supported. |
| `runner` | `"./bin/rails runner"` | Command to run Ruby scripts, relative to webpack's working directory. |

For example, if your webpack process is running in a subdirectory of your Rails project:

```js
{
  loader: 'rails-erb-loader',
  options: {
    runner: '../bin/rails runner',
    dependenciesRoot: '../app',
  }
}
```

Also supports building without Rails:

```js
{
  loader: 'rails-erb-loader',
  options: {
    runner: 'ruby',
    engine: 'erb'
  }
}
```

### Dependencies

If your `.erb` files depend on files in your Ruby project, you can list them explicitly. Inclusion of the `rails-erb-loader-dependency` (or `-dependencies`) comment will tell webpack to watch these files - causing webpack-dev-server to rebuild when they are changed.

#### Watch individual files

List dependencies in the comment. `.rb` extension is optional.

```js
/* rails-erb-loader-dependencies models/account models/user */
```

#### Watch a whole directory

To watch all files in a directory, end the path in a `/`.

```js
/* rails-erb-loader-dependencies ../config/locales/ */
```

## Contribute

Questions, bug reports and pull requests welcome. See [GitHub issues](https://github.com/usabilityhub/rails-erb-loader/issues).

## License

MIT
