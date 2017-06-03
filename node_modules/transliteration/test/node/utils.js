import test from 'tape';
import * as utils from '../../src/main/utils';

test('#ucs2decode()', (q) => {
  const data = [
    // Every Unicode symbol is tested separately. These are just the extra
    // tests for symbol combinations:
    {
      description: 'Consecutive astral symbols',
      decoded: [127829, 119808, 119558, 119638],
      encoded: [0xD83C, 0xDF55, 0xD835, 0xDC00, 0xD834, 0xDF06, 0xD834, 0xDF56],
    },
    {
      description: 'U+D800 (high surrogate) followed by non-surrogates',
      decoded: [55296, 97, 98],
      encoded: [0xD800, 0x61, 0x62],
    },
    {
      description: 'U+DC00 (low surrogate) followed by non-surrogates',
      decoded: [56320, 97, 98],
      encoded: [0xDC00, 0x61, 0x62],
    },
    {
      description: 'High surrogate followed by another high surrogate',
      decoded: [0xD800, 0xD800],
      encoded: [0xD800, 0xD800],
    },
    {
      description: 'Unmatched high surrogate, followed by a surrogate pair, followed by an unmatched high surrogate',
      decoded: [0xD800, 0x1D306, 0xD800],
      encoded: [0xD800, 0xD834, 0xDF06, 0xD800],
    },
    {
      description: 'Low surrogate followed by another low surrogate',
      decoded: [0xDC00, 0xDC00],
      encoded: [0xDC00, 0xDC00],
    },
    {
      description: 'Unmatched low surrogate, followed by a surrogate pair, followed by an unmatched low surrogate',
      decoded: [0xDC00, 0x1D306, 0xDC00],
      encoded: [0xDC00, 0xD834, 0xDF06, 0xDC00],
    },
    {
      description: 'High surrogate followed by a low surrogate',
      decoded: [0x10400],
      encoded: [0xD801, 0xDC00],
    },
  ];
  test('Return ucs2 code array of a string', (t) => {
    data.forEach(({ description, encoded, decoded }) => {
      t.deepEqual(utils.ucs2decode(String.fromCharCode(...encoded)), decoded, description);
    });
    t.end();
  });
  q.end();
});

test('#escapeRegex()', (t) => {
  const escaped = '\\^\\$\\.\\*\\+\\?\\(\\)\\[\\]\\{\\}\\|\\\\';
  const unescaped = '^$.*+?()[]{}|\\';

  t.equal(utils.escapeRegExp(unescaped + unescaped), escaped + escaped, 'should escape values');

  t.equal(utils.escapeRegExp('abc'), 'abc', 'should handle strings with nothing to escape');

  /* eslint-disable no-sparse-arrays,no-confusing-arrow */
  const values = [, null, undefined, ''];
  const expected = values.map(() => '');
  const actual = values.map((value, index) =>
  /* eslint-enable no-sparse-arrays,no-confusing-arrow */
    index ? utils.escapeRegExp(value) : utils.escapeRegExp(),
  );

  t.deepEqual(expected, actual, 'should return an empty string for empty values');
  t.end();
});

test('#parseCmdEqualOption', (t) => {
  t.deepEqual(utils.parseCmdEqualOption('a=b'), ['a', 'b'], 'a=b');
  t.deepEqual(utils.parseCmdEqualOption('a\\==b'), ['a=', 'b'], 'a\\==b');
  t.deepEqual(utils.parseCmdEqualOption('a\\\\=b'), ['a\\', 'b'], 'a\\\\=b');
  t.equal(utils.parseCmdEqualOption('a==b'), false, 'a==b');
  t.deepEqual(utils.parseCmdEqualOption('a__REPLACE_TOKEN__=b'), ['a__REPLACE_TOKEN__', 'b'], 'a__REPLACE_TOKEN__=b');
  t.end();
});

test('#mergeOptions', (t) => {
  const opt = { a: 'b' };
  t.deepEqual(utils.mergeOptions(opt, 'abc'), opt, 'extrame case with option="abc"');
  t.end();
});

