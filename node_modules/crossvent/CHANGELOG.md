# 1.5.3 Mortal Kombat 3

- Crossvent now ignores API limitations on the server-side, instead of throwing

# v1.5.2 Fix Up

- Fixed a bug in IE8 where attempting to remove an undefined event listener would throw

# v1.5.1 Power Up

- Crossvent now exports an empty API on the server-side, instead of throwing

# v1.5.0 Classic Poets

- Fall back to classic events for non-made-up event types

# v1.4.0 Fabricator

- Added optional custom event model for `.fabricate`

# v1.3.2 Ice Bug

- `e.which` gets normalized across browsers, `e.keyCode` is used if not present

# v1.3.1 Fire Bug

- Use `fireEvent` and `createEventObject` when their modern counterparts are missing

# v1.2.0 Flag The Bug

- Added ability to use a `capture` parameter in event removal as well

# v1.1.0 Capture The Flag

- Added ability to use a `capture` parameter

# v1.0.0 IPO

- Initial Public Release
