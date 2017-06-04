var assert = require('assert');

var pathCompleteExtname = require('./index.js');

var isWindows = process.platform === 'win32';


// ---


describe('pathCompleteExtname', function () {

  it('should pass all existing nodejs unit tests', function () {

    // Original tests that would not pass in this new implementation
    // are left commented out here for reference
    assert.equal(pathCompleteExtname(''), '');
    assert.equal(pathCompleteExtname('/path/to/file'), '');
    assert.equal(pathCompleteExtname('/path/to/file.ext'), '.ext');
    assert.equal(pathCompleteExtname('/path.to/file.ext'), '.ext');
    assert.equal(pathCompleteExtname('/path.to/file'), '');
    assert.equal(pathCompleteExtname('/path.to/.file'), '');
    assert.equal(pathCompleteExtname('/path.to/.file.ext'), '.ext');
    assert.equal(pathCompleteExtname('/path/to/f.ext'), '.ext');
    assert.equal(pathCompleteExtname('/path/to/..ext'), '.ext');
    assert.equal(pathCompleteExtname('file'), '');
    assert.equal(pathCompleteExtname('file.ext'), '.ext');
    assert.equal(pathCompleteExtname('.file'), '');
    assert.equal(pathCompleteExtname('.file.ext'), '.ext');
    assert.equal(pathCompleteExtname('/file'), '');
    assert.equal(pathCompleteExtname('/file.ext'), '.ext');
    assert.equal(pathCompleteExtname('/.file'), '');
    assert.equal(pathCompleteExtname('/.file.ext'), '.ext');
    assert.equal(pathCompleteExtname('.path/file.ext'), '.ext');
    //assert.equal(pathCompleteExtname('file.ext.ext'), '.ext');
    assert.equal(pathCompleteExtname('file.'), '.');
    assert.equal(pathCompleteExtname('.'), '');
    assert.equal(pathCompleteExtname('./'), '');
    assert.equal(pathCompleteExtname('.file.ext'), '.ext');
    assert.equal(pathCompleteExtname('.file'), '');
    assert.equal(pathCompleteExtname('.file.'), '.');
    //assert.equal(pathCompleteExtname('.file..'), '.');
    assert.equal(pathCompleteExtname('..'), '');
    assert.equal(pathCompleteExtname('../'), '');
    //assert.equal(pathCompleteExtname('..file.ext'), '.ext');
    assert.equal(pathCompleteExtname('..file'), '.file');
    //assert.equal(pathCompleteExtname('..file.'), '.');
    //assert.equal(pathCompleteExtname('..file..'), '.');
    assert.equal(pathCompleteExtname('...'), '.');
    assert.equal(pathCompleteExtname('...ext'), '.ext');
    //assert.equal(pathCompleteExtname('....'), '.');
    assert.equal(pathCompleteExtname('file.ext/'), '.ext');
    assert.equal(pathCompleteExtname('file.ext//'), '.ext');
    assert.equal(pathCompleteExtname('file/'), '');
    assert.equal(pathCompleteExtname('file//'), '');
    assert.equal(pathCompleteExtname('file./'), '.');
    assert.equal(pathCompleteExtname('file.//'), '.');

    if (isWindows) {
      // On windows, backspace is a path separator.
      assert.equal(pathCompleteExtname('.\\'), '');
      assert.equal(pathCompleteExtname('..\\'), '');
      assert.equal(pathCompleteExtname('file.ext\\'), '.ext');
      assert.equal(pathCompleteExtname('file.ext\\\\'), '.ext');
      assert.equal(pathCompleteExtname('file\\'), '');
      assert.equal(pathCompleteExtname('file\\\\'), '');
      assert.equal(pathCompleteExtname('file.\\'), '.');
      assert.equal(pathCompleteExtname('file.\\\\'), '.');

    } else {
      // On unix, backspace is a valid name component like any other character.
      assert.equal(pathCompleteExtname('.\\'), '');
      assert.equal(pathCompleteExtname('..\\'), '.\\');
      assert.equal(pathCompleteExtname('file.ext\\'), '.ext\\');
      assert.equal(pathCompleteExtname('file.ext\\\\'), '.ext\\\\');
      assert.equal(pathCompleteExtname('file\\'), '');
      assert.equal(pathCompleteExtname('file\\\\'), '');
      assert.equal(pathCompleteExtname('file.\\'), '.\\');
      assert.equal(pathCompleteExtname('file.\\\\'), '.\\\\');
    }
  });


  // ---


  it('should retrieve file extensions with two dots', function () {
    assert.equal(pathCompleteExtname('jquery.min.js'), '.min.js');
    assert.equal(pathCompleteExtname('package.tar.gz'), '.tar.gz');
  });


  // ---


  it('should ignore dots on path', function () {
    assert.equal(pathCompleteExtname('/path.to/jquery.min.js'), '.min.js');
  });


  // ---


  it('should not consider initial dot as part of extension', function () {
    assert.equal(pathCompleteExtname('some.path/.yo-rc.json'), '.json');
    assert.equal(pathCompleteExtname('/.yo-rc.json'), '.json');
    assert.equal(pathCompleteExtname('.yo-rc.json'), '.json');
  });


  // ---


  it('should accept a three-dots file extension', function () {
    assert.equal(pathCompleteExtname('some.path/myamazingfile.some.thing.zip'), '.some.thing.zip');
  });


  // ---


  it('should also ignore initial dot if three-dots are present', function () {
    assert.equal(pathCompleteExtname('some.path/.some.thing.zip'), '.thing.zip');
  });


  // ---


  it('should also get version numbers as extensions', function () {
    assert.equal(pathCompleteExtname('some.path/something.0.6.7.js'), '.0.6.7.js');
    assert.equal(pathCompleteExtname('some.path/something.1.2.3.min.js'), '.1.2.3.min.js');
  });

});

