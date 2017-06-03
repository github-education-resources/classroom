# ticky

```shell
npm install ticky --save
```

# ticky(fn)

Run a callback as soon as possible using one of the following. To keep things lean, `process.nextTick` won't be bundled when it comes to browserify.

- `setImmediate`
- `process.nextTick`
- `setTimeout`

# license

mit