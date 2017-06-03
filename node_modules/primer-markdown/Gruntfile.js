/*!
 * GitHub User Content Stylesheets -- rendered markdown and syntax highlighting
 * https://github.com/primer/user-content
 * Copyright 2014 GitHub, Inc.
 * Licensed under MIT (https://github.com/primer/user-content/blob/master/LICENSE.md)
 */

module.exports = function(grunt) {

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    banner: '/*!\n' +
            ' * GitHub User Content Stylesheets v<%= pkg.version %> (<%= pkg.homepage %>)\n' +
            ' * Copyright <%= grunt.template.today("yyyy") %> <%= pkg.author %>\n' +
            ' * Licensed under <%= pkg.license.type %> (<%= pkg.license.url %>).\n' +
            ' */\n',

    sass: {
      dist: {
        files: {
          'dist/user-content.css': 'components/user-content.scss'
        }
      }
    },

    csscomb: {
      options: {
        config: 'components/.csscomb.json'
      },
      dist: {
        files: {
          'dist/user-content.css': 'dist/user-content.css'
        }
      }
    },

    cssmin: {
      options: {
        banner: '', // set to empty; see bellow
        keepSpecialComments: '*', // set to '*' because we already add the banner in sass
        noAdvanced: true, // disable advanced optimizations since it causes many issues
        report: 'min'
      },
      dist: {
        src: 'dist/user-content.css',
        dest: 'dist/user-content.min.css'
      }
    },

    usebanner: {
      dist: {
        options: {
          position: 'top',
          banner: '<%= banner %>'
        },
        files: {
          src: [
            'dist/*.css'
          ]
        }
      }
    },

    watch: {
      scss: {
        files: [
          'components/*.scss'
        ],
        tasks: ['sass']
      }
    }
  });

  // These plugins provide necessary tasks
  require('load-grunt-tasks')(grunt, {scope: 'devDependencies'});
  require('time-grunt')(grunt);

  // Register the tasks
  grunt.registerTask('dist-css', ['sass', 'csscomb', 'cssmin', 'usebanner']);
  grunt.registerTask('dist', ['dist-css']);
  grunt.registerTask('build', ['dist']);
  grunt.registerTask('default', ['dist']);
};
