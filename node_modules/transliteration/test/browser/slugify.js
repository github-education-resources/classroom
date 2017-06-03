/* global window */
import test from 'tape';
import 'es5-shim';

const slugify = window.slugify;

const defaultOptions = {
  lowercase: true,
  separator: '-',
  replace: [],
  replaceAfter: [],
  ignore: [],
};

test('#slugify()', (q) => {
  const tests = [
    ['\u4F60\u597D, \u4E16\u754C!', {}, 'ni-hao-shi-jie'],
    ['\u4F60\u597D, \u4E16\u754C!', { separator: '_' }, 'ni_hao_shi_jie'],
    ['\u4F60\u597D, \u4E16\u754C!', { lowercase: false }, 'Ni-Hao-Shi-Jie'],
    ['\u4F60\u597D, \u4E16\u754C!', { ignore: ['!', ','] }, 'ni-hao,shi-jie!'],
    ['\u4F60\u597D, \u4E16\u754C!', { replace: [['\u4E16\u754C', '\u672A\u6765']] }, 'ni-hao-wei-lai'],
    ['\u4F60\u597D, \u4E16\u754C!', { replace: [['\u4F60\u597D', 'Hello '], ['\u4E16\u754C', 'World ']] }, 'hello-world'],
    ['\u4F60\u597D, \u4E16\u754C!', { separator: ', ', replace: [['\u4F60\u597D', 'Hola '], ['\u4E16\u754C', 'mundo ']], ignore: ['¡', '!'], lowercase: false }, 'Hola, mundo!'],
  ];
  test('Generate slugs', (t) => {
    for (const [str, options, slug] of tests) {
      t.equal(slugify(str, options), slug, `${str}-->${slug}`);
    }
    t.end();
  });
  q.end();
});

test('#slugify.config()', (q) => {
  test('Get config', (t) => {
    slugify.config(defaultOptions);
    t.deepEqual(slugify.config(), defaultOptions, 'read current config');
    t.end();
  });
  const tests = [
    ['\u4F60\u597D, \u4E16\u754C!', {}, 'ni-hao-shi-jie'],
    ['\u4F60\u597D, \u4E16\u754C!', { separator: '_' }, 'ni_hao_shi_jie'],
    ['\u4F60\u597D, \u4E16\u754C!', { lowercase: false }, 'Ni-Hao-Shi-Jie'],
    ['\u4F60\u597D, \u4E16\u754C!', { ignore: ['!', ','] }, 'ni-hao,shi-jie!'],
    ['\u4F60\u597D, \u4E16\u754C!', { replace: [['\u4E16\u754C', '\u672A\u6765']] }, 'ni-hao-wei-lai'],
    ['\u4F60\u597D, \u4E16\u754C!', { replace: [['\u4F60\u597D', 'Hello '], ['\u4E16\u754C', 'World ']] }, 'hello-world'],
    ['\u4F60\u597D, \u4E16\u754C!', { separator: ', ', replace: [['\u4F60\u597D', 'Hola '], ['\u4E16\u754C', 'mundo ']], ignore: ['¡', '!'], lowercase: false }, 'Hola, mundo!'],
  ];
  test('Generate slugs', (t) => {
    for (const [str, options, slug] of tests) {
      slugify.config(options);
      t.equal(slugify(str), slug, `${str}-->${slug}`);
    }
    t.end();
  });
  q.end();
});
