import browserify from 'browserify';
import gulp from 'gulp';
import source from 'vinyl-source-stream';
import buffer from 'vinyl-buffer';
import uglify from 'gulp-uglify';
import babel from 'gulp-babel';
import sourcemaps from 'gulp-sourcemaps';
import gutil from 'gulp-util';
import rename from 'gulp-rename';
import babelify from 'babelify';
import es3ify from 'gulp-es3ify';
import rimraf from 'rimraf';

const SRC_BROWSER_PATH = 'src/main/browser.js';
const SRC_NODE_PATH = ['src/main/*.js', '!src/main/browser.js', '!src/main/data.js'];
const SRC_BIN_PATH = 'src/bin/*.js';
const DEST_BROWSER_PATH = 'lib/browser/';
const DEST_NODE_PATH = 'lib/node/';
const DEST_BIN_PATH = 'lib/bin/';

gulp.task('default', ['build:browser', 'build:node', 'build:bin']);

gulp.task('build:browser', ['clean:browser'], () =>
  browserify(SRC_BROWSER_PATH, { debug: true })
    .transform(babelify, { presets: ['es2015-ie'], plugins: ['add-module-exports'] })
    .bundle()
    .pipe(source('transliteration.js'))
    .pipe(buffer())
    .pipe(sourcemaps.init({ loadMaps: true }))
      .pipe(es3ify())
      .pipe(gulp.dest(DEST_BROWSER_PATH))
      .pipe(rename('transliteration.min.js'))
      .pipe(uglify())
      .on('error', gutil.log)
    .pipe(sourcemaps.write('./'))
    .pipe(gulp.dest(DEST_BROWSER_PATH))
    .pipe(gutil.noop()),
);

gulp.task('build:node', ['clean:node'], () =>
  gulp.src(SRC_NODE_PATH)
    .pipe(babel())
    .pipe(gulp.dest(DEST_NODE_PATH)),
);

gulp.task('build:bin', ['clean:bin'], () =>
  gulp.src(SRC_BIN_PATH)
    .pipe(babel())
    .pipe(rename({ extname: '' }))
    .pipe(gulp.dest(DEST_BIN_PATH)),
);

gulp.task('clean:browser', cb => rimraf('lib/browser/*', cb));

gulp.task('clean:node', cb => rimraf('lib/node/*', cb));

gulp.task('clean:bin', cb => rimraf('lib/bin/*', cb));
