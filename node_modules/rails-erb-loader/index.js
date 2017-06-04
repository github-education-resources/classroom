var fs = require('fs')
var exec = require('child_process').exec
var path = require('path')
var getOptions = require('loader-utils').getOptions
var defaults = require('lodash.defaults')

function pushAll (dest, src) {
  Array.prototype.push.apply(dest, src)
}

/* Create a delimeter that is unlikely to appear in parsed code. I've split this
 * string deliberately in case this file accidentally ends up being transpiled
 */
var ioDelimiter = '_' + '_RAILS_ERB_LOADER_DELIMETER__'

/* Match any block comments that start with the string `rails-erb-loader-*`. */
var configCommentRegex = /\/\*\s*rails-erb-loader-([a-z-]*)\s*([\s\S]*?)\s*\*\//g

/* Absolute path to the Ruby script that does the ERB transformation. */
var transformerPath = '"' + path.join(__dirname, 'erb_transformer.rb') + '"'

/* Takes a path and attaches `.rb` if it has no extension nor trailing slash. */
function defaultFileExtension (dependency) {
  return /((\.\w*)|\/)$/.test(dependency) ? dependency : dependency + '.rb'
}

/* Get each space separated path, ignoring any empty strings. */
function parseDependenciesList (root, string) {
  return string.split(/\s+/).reduce(function (accumulator, dependency) {
    if (dependency.length > 0) {
      var absolutePath = path.resolve(root, defaultFileExtension(dependency))
      accumulator.push(absolutePath)
    }
    return accumulator
  }, [])
}

/* Update config object in place with comments from file */
function parseDependencies (source, root) {
  var dependencies = []
  var match = null
  while ((match = configCommentRegex.exec(source))) {
    var option = match[1]
    var value = match[2]
    switch (option) {
      case 'dependency':
      case 'dependencies':
        pushAll(dependencies, parseDependenciesList(root, value))
        break
      default:
        console.warn(
          'WARNING: Unrecognized configuration command ' +
          '"rails-erb-loader-' + option + '". Comment ignored.'
        )
    }
  }
  return dependencies
}

/* Launch Rails in a child process and run the `erb_transformer.rb` script to
 * output transformed source.
 */
function transformSource (runner, engine, source, map, callback) {
  var child = exec(
    runner + ' ' + transformerPath + ' ' + ioDelimiter + ' ' + engine,
    function (error, stdout) {
      // Output is delimited to filter out unwanted warnings or other output
      // that we don't want in our files.
      var sourceRegex = new RegExp(ioDelimiter + '([\\s\\S]+)' + ioDelimiter)
      var matches = stdout.match(sourceRegex)
      var transformedSource = matches && matches[1]
      callback(error, transformedSource, map)
    }
  )
  child.stdin.on('error', function (error) {
    if (error.code === 'EPIPE') {
      // When the `runner` command is not found, stdin will not be open.
      // Attemping to write then causes an EPIPE error. Ignore this because the
      // `exec` callback gives a more meaningful error that we show to the user.
    } else {
      console.error(
        'rails-erb-loader encountered an unexpected error while writing to stdin: "' +
        error.message + '". Please report this to the maintainers.'
      )
    }
  })
  child.stdin.write(source)
  child.stdin.end()
}

function addDependencies (loader, paths, callback) {
  var remaining = paths.length

  if (remaining === 0) callback(null)

  paths.forEach(function (path) {
    fs.stat(path, function (error, stats) {
      if (error) {
        if (error.code === 'ENOENT') {
          callback(new Error('Could not find dependency "' + path + '"'))
        } else {
          callback(error)
        }
      } else {
        if (stats.isFile()) {
          loader.addDependency(path)
        } else if (stats.isDirectory()) {
          loader.addContextDependency(path)
        } else {
          console.warning(
            'rails-erb-loader ignored dependency that was neither a file nor a directory'
          )
        }
        remaining--
        if (remaining === 0) callback(null)
      }
    })
  })
}

module.exports = function railsErbLoader (source, map) {
  var loader = this

  // Mark loader cacheable. Must be called explicitly in webpack 1.
  // see: https://webpack.js.org/guides/migrating/#cacheable
  loader.cacheable()

  // Get options passed in the loader query, or use defaults.
  // Modifying the return value of `getOptions` is not permitted.
  var config = defaults({}, getOptions(loader), {
    dependenciesRoot: 'app',
    runner: './bin/rails runner',
    engine: 'erb'
  })

  // Dependencies are only useful in development, so don't bother searching the
  // file for them otherwise.
  var dependencies = process.env.NODE_ENV === 'development'
    ? parseDependencies(source, config.dependenciesRoot)
    : []

  var callback = loader.async()

  // Register watchers for any dependencies.
  addDependencies(loader, dependencies, function (error) {
    if (error) {
      callback(error)
    } else {
      transformSource(config.runner, config.engine, source, map, callback)
    }
  })
}
