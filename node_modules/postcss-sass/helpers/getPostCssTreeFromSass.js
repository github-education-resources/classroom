var fs = require('fs');
var sassToPostCss = require('../');

module.exports = function (fileName) {
    var source = fs.readFileSync(
        './__tests__/sass/' + fileName + '.sass',
        'utf-8'
    );
    return sassToPostCss(source);
};
