# Development notes

Version bumping
---------------

Edit the following files:

 * lib/jquery-turbolinks/version.rb
 * package.json
 * src/jquery.turbolinks.coffee

Updating .js files
------------------

Update the .js files from the source CoffeeScript file using: (do this before 
    releasing)

    $ rake build

Testing
-------

Simply use npm/mocha:

    $ npm install
    $ npm test

Or:

    $ rake test

Releasing new versions
----------------------

 * Bump version (see above)
 * Build .js (`rake build`)
 * Release into npm and rubygems (`rake release:all`)
 * Draft release in https://github.com/kossnocorp/jquery.turbolinks/releases

Release it into npm/rubygems using:

    $ rake release:all
