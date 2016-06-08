/* global __dirname, process */
import { execFile, execFileSync } from 'child_process';
import fs from 'fs';
import path from 'path';

import test from 'tape';

const PATH_TO_XELATEX = path.join(__dirname, '..', 'xelatex.js');

const DEFAULT_ENV = {
  cwd: path.join(__dirname, '..')
};

const tex = filename => {
  if (filename) {
    return path.join(__dirname, 'samples', filename);
  }
  return path.join(__dirname, 'samples');
};

const _xelatex = (fn, args = [], options = {}) => {
  args = [PATH_TO_XELATEX, ...args];
  options.env = Object.assign(DEFAULT_ENV, options.env);
  return fn(process.execPath, args, options);
};

// returns a promise of [stdio, stdout, stderr]
const xelatexSync = (...rest) => _xelatex(execFileSync, ...rest);

const xelatex = (...rest) => _xelatex(execFile, ...rest);

              // 'TEXMFDIST = /texlive-basic/texmf-dist\n' +
              // 'TEXMFLOCAL = /texlive-basic/texmf-local\n' +
              // 'TEXMFCONFIG = /texlive-basic/texmf-config\n' +
              // 'TEXMF = {!!$TEXMFDIST,!!$TEXMFLOCAL,!!$TEXMFCONFIG}\n',

test('xelatex.js exists', t => {
  fs.access(PATH_TO_XELATEX, fs.F_OK, t.end);
});


test('xelatex has a version', t => {
  var stdout = xelatex(['-version'], (e, stdout, stderr) => {
    console.warn(stderr);
    if (stdout.startsWith('XeTeX 3.1415926-')) {
      t.pass('has a version string');
    } else {
      t.fail(`Unexpected stdout: <${stdout}>`);
    }
    t.end();
  });
});

test('xelatex can start up', t => {
  xelatex([], (e, stdout, stderr) => {
    if (stdout.toString().startsWith('This is XeTeX, Version ')) {
      t.pass('has a version string');
    } else {
      t.fail(`Unexpected stdout: <${stdout}>`);
    }
    t.end();
  });
});

test('xelatex can compile hello world', t => {
  fs.unlink(tex('hello_world.pdf'), _ => {
    fs.access(tex('hello_world.pdf'), e => {
      t.ok(e, `${tex('hello_world.pdf')} should not exist`);

      xelatex([`-output-directory=${tex()}`, tex('hello_world.tex')], (e, stdout, stderr) => {
        fs.access('hello_world.pdf', (e, data) => {
          t.notOk(e, 'file should exist');
          t.ok(data, 'file content should exist');
        });
      });
      t.end(e);
    });
  });
});
