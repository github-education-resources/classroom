#!/usr/bin/env node
import yargs from 'yargs';
import { parseCmdEqualOption as parseE } from '../../lib/node/utils'; // eslint-disable-line import/no-unresolved
import { default as slugify } from '../../lib/node/slugify'; // eslint-disable-line import/no-unresolved

const STDIN_ENCODING = 'utf-8';
const options = {
  lowercase: true,
  separator: '-',
  replace: [],
  ignore: [],
};

const argv = yargs
  .version()
  .usage('Usage: $0 <unicode> [options]')
  .option('l', {
    alias: 'lowercase',
    default: options.lowercase,
    describe: 'Use lowercase',
    type: 'boolean',
  })
  .options('s', {
    alias: 'separator',
    default: '-',
    describe: 'Separator of the slug',
    type: 'string',
  })
  .option('r', {
    alias: 'replace',
    default: options.replace,
    describe: 'Custom string replacement',
    type: 'array',
  })
  .option('i', {
    alias: 'ignore',
    default: options.ignore,
    describe: 'String list to ignore',
    type: 'array',
  })
  .option('S', {
    alias: 'stdin',
    default: false,
    describe: 'Use stdin as input',
    type: 'boolean',
  })
  .help('h')
  .option('h', {
    alias: 'help',
  })
  .example('$0 "你好, world!" -r 好=good -r "world=Shi Jie"',
    'Replace `,` into `!` and `world` into `shijie`.\nResult: ni-good-shi-jie')
  .example('$0 "你好，世界!" -i 你好 -i ，',
    'Ignore `你好` and `，`.\nResult: 你好，shi-jie')
  .wrap(100)
  .argv;

options.lowercase = !!argv.l;
options.separator = argv.separator;
if (argv.replace.length) {
  for (const repl of argv.replace) {
    const tmp = parseE(repl);
    if (tmp === false) {
      console.error(`Bad argument -r or --replace. Please type '${argv.$0} --help' for help.`);
      process.exit(1);
    }
    options.replace.push(tmp);
  }
}
options.ignore = argv.ignore;

if (argv.stdin) {
  process.stdin.setEncoding(STDIN_ENCODING);
  process.stdin.on('readable', () => {
    const chunk = process.stdin.read();
    if (chunk !== null) {
      process.stdout.write(slugify(chunk, options));
    }
  });
  process.stdin.on('end', () => console.log(''));
} else {
  if (argv._.length !== 1) {
    console.error(`Invalid argument. Please type '${argv.$0} --help' for help.`);
  }
  console.log(slugify(argv._[0], options));
}
