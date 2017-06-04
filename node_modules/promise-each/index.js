const Promise = require('any-promise')
const assert = require('assert')

module.exports = each

// apply a function to all values
// should only be used for side effects
// (fn) -> prom
function each (fn) {
  assert.equal(typeof fn, 'function')
  return function (arr) {
    arr = Array.isArray(arr) ? arr : [arr]

    return arr.reduce(function (prev, curr, i) {
      return prev.then(function () { return fn(curr, i, arr.length) })
    }, Promise.resolve()).then(function () {})
  }
}
