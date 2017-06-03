/* global window */
/**
 * Some of tests are taken from Text-Unidecode-0.04/test.pl
 *
 * @see <http://search.cpan.org/~sburke/Text-Unidecode-0.04/lib/Text/Unidecode.pm>
 */
import test from 'tape';
import 'es5-shim';

const transl = window.transl;

const defaultOptions = {
  unknown: '[?]',
  replace: [],
  replaceAfter: [],
  ignore: [],
};

test('#transliterate()', (q) => {
  test('- Purity tests', (t) => {
    const tests = [];
    for (let i = 1; tests.length < 127; tests.push(String.fromCharCode(i++)));

    tests.forEach((str) => {
      t.equal(transl(str), str, `${str.charCodeAt(0).toString(16)} ${str}`);
    });
    t.end();
  });

  test('- Basic string tests', (t) => {
    const tests = [
      '',
      1 / 10,
      'I like pie.',
      '\n',
      '\r\n',
      'I like pie.\n',
    ];

    tests.forEach((str) => {
      t.equal(transl(str.toString()), str.toString(), str);
    });
    t.end();
  });

  test('- Complex tests', (t) => {
    const tests = [
      ['\u00C6neid', 'AEneid'],
      ['\u00E9tude', 'etude'],
      ['\u5317\u4EB0', 'Bei Jing'],
      //  Chinese
      ['\u1515\u14c7\u14c7', 'shanana'],
      //  Canadian syllabics
      ['\u13d4\u13b5\u13c6', 'taliqua'],
      //  Cherokee
      ['\u0726\u071b\u073d\u0710\u073a', 'ptu\'i'],
      //  Syriac
      ['\u0905\u092d\u093f\u091c\u0940\u0924', 'abhijiit'],
      //  Devanagari
      ['\u0985\u09ad\u09bf\u099c\u09c0\u09a4', 'abhijiit'],
      //  Bengali
      ['\u0d05\u0d2d\u0d3f\u0d1c\u0d40\u0d24', 'abhijiit'],
      //  Malayalaam
      ['\u0d2e\u0d32\u0d2f\u0d3e\u0d32\u0d2e\u0d4d', 'mlyaalm'],
      //  the Malayaalam word for 'Malayaalam'
      //  Yes, if we were doing it right, that'd be 'malayaalam', not 'mlyaalm'
      ['\u3052\u3093\u307e\u3044\u8336', 'genmaiCha'],
      //  Japanese, astonishingly unmangled.
      [`\u0800\u1400${unescape('%uD840%uDD00')}`, '[?][?][?]'],
      // Unknown characters
    ];

    for (const [str, result] of tests) {
      t.equal(transl(str), result, `${str}-->${result}`);
    }
    t.end();
  });

  test('- With ignore option', (t) => {
    const tests = [
      ['\u00C6neid', ['\u00C6'], '\u00C6neid'],
      ['\u4F60\u597D\uFF0C\u4E16\u754C\uFF01', ['\uFF0C', '\uFF01'], 'Ni Hao\uFF0CShi Jie\uFF01'],
      ['\u4F60\u597D\uFF0C\u4E16\u754C\uFF01', ['\u4F60\u597D', '\uFF01'], '\u4F60\u597D,Shi Jie\uFF01'],
    ];
    for (const [str, ignore, result] of tests) {
      t.equal(transl(str, { ignore }), result, `${str}-->${result}`);
    }
    t.end();
  });

  test('- With replace option', (t) => {
    const tests = [
      ['\u4F60\u597D\uFF0C\u4E16\u754C\uFF01', [['\u4F60\u597D', 'Hola']], 'Hola,Shi Jie !'],
    ];
    for (const [str, replace, result] of tests) {
      t.equal(transl(str, { replace }), result, `${str}-->${result}`);
    }
    t.end();
  });
  q.end();
});

test('#transliterage.config()', (t) => {
  transl.config(defaultOptions);
  t.deepEqual(transl.config(), defaultOptions, 'read current config');
  t.end();
});
