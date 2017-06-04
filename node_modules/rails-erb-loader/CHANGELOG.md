# Change Log

## [5.0.1] - 2017-05-16
 - Support projects in paths containing spaces. #35

## [5.0.0] - 2017-04-01
 - **Breaking** Set default engine to `ERB`. - #31
 - Add support for `Erubi` engine. - #31

## [4.0.0] - 2017-04-01
- **Breaking** Remove support for webpack 1 style configuration under `config.railsErbLoader` - #28
- **Breaking** Remove support for `dependencies` in configuration (only via config comments) - #29
- **Breaking** Remove `cacheable` option and comment - all files are cacheable by default - #27
- **Breaking** Error when a dependency comment points to a non-existant file/directory - #29
- Support adding a directory as a depedency - #29
- Better error handling on invalid `runner` option. - #26
- Skip parsing comments in production - #29

## [3.2.0] - 2016-12-12
- Add `engine` config option to specify templating engine. - #21
- Add `runner` config option to specify Ruby executable. - #21
- Deprecate `rails` config option in preference for more flexible `runner`

## [3.1.0] - 2016-12-11
- Added `rails` option - #20

## [3.0.1] - 2016-11-30
- Ensure support back to Node 0.10.0 - #13, #17
- Remove dependency `node-uuid` - #15
- Include MIT license text

## [3.0.0] - 2016-11-19
- **Breaking** Use `Erubis` instead of `ERB` gem to render templates. This gem is bundled by default with Rails 3.0 and above. - #7

## [2.0.0] - 2016-11-07
- **Breaking** Rename project from `uh-erb-loader` to `rails-erb-loader` - #6
- **Breaking** Add file caching by default - #4
- Add support for query parameters
 - `cacheable`
 - `dependencies`
 - `dependenciesRoot`
 - `parseComments`
- Add configuration comments
 - `rails-erb-loader-depedencies`
 - `rails-erb-loader-depedencies-root` (undocumented)
 - `rails-erb-loader-cacheable`

## [1.1.1] - 2016-11-07
Deprecate `uh-erb-loader` in favor of `rails-erb-loader`.

## [1.1.0] - 2016-05-26
- Ignore unwanted output from Rails by delimiting desired output. - #1

## [1.0.0] - 2016-05-05
Initial release
