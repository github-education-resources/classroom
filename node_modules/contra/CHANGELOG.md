# 1.9.4 Ticky Tac

- Bump `ticky@1.0.1`

# 1.9.1 Requirements Met

- Moved modules out of `src` directory so that they can be required like `contra/emitter`

# 1.9.0 Modularity Paradise

- Split the monolithic source code into individual modules

# 1.8.1 Snapchat

- Fixed a use case where the consumer turned the emitter `.off` from within the event listener

# 1.8.0 Hell

- Updated `λ.emitter` to match functionality in `contra.emitter` package

# 1.7.0 Heaven

- Fixed a bug where `done` callbacks weren't optional

# 1.6.9 Context Emission Revisited

- Fixed the context passed to event listeners

# 1.6.8 Cascade of Events

- `λ.emitter` methods return the emitter object for chaining

# 1.6.7 Carbon Emitter

- New options to turn off event listeners on `λ.emitter` objects

# 1.6.5 Throw Up

- `λ.emitter` takes a `throws` option that can turn off error-throwing

# 1.6.4 Context Emission

- `λ.emitter` properly sets `this` to the event emitter object

# 1.6.1 Much Synchronous

- `λ.emitter` takes an optional `options` object

Changes

- `λ.emitter` runs _synchronously_ by default

# 1.5.6 Such Very Golf

- Some more code reduction

# 1.5.5 Stroke Cure

- Reduced source code footprint

Fixes

- Fixed a bug where `done` was mandatory

# 1.5.4 Keyhole Variation

- `λ.each`, `λ.filter`, and `λ.map` support an optional `key` argument in the iterator function.

# 1.5.1 Emitter of Things

- `λ.emitter` can create emitters without passing it any object

# 1.5.0 `<head>`

- Distribution file headers

# 1.4.3 Wonderboy

- Source code readability

# 1.4.0 Baseball Cap

- Added optional _concurrency cap_ argument to remaining concurrent methods: `filter`, `map`, `each`

# 1.3.0 Queue Up!

- Concurrent methods now use a queue internally
- `λ.concurrent` has an optional _concurrency cap_ argument
- Series now use a concurrent queue internally, with `concurrency = 1`

Fixes

- Fixed a bug where queues weren't working concurrently
- Fixed an issue where queues would emit `drain` while processing jobs

# 1.2.2 Polyglot

- Polyfill for `Array.prototype.indexOf` added to `contra.shim.js`

# 1.2.1 This, That

- Switched `window` for `root`

# 1.2.0 Event Organizer

- Added `.off` and `.once` support to event emitter API

# 1.1.2 Clown Car

- Removed unnecessary context from event listeners

# 1.1.1 Down the Drain

- Queue is an emitter
- Queue emits `drain` events

# 1.1.0 Obama Cares

**BREAKING**

- Rename `λ.apply` to `λ.curry`

# 1.0.29 Dot Com Bubble

- Ignore dotfiles in Bower distribution

# 1.0.12 IPO Beast

- Initial Public Release
