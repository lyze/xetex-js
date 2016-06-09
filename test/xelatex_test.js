/* global __dirname, process */
import { execFile, execFileSync } from 'child_process';
import fs from 'fs';
import path from 'path';

import test from 'tape';

const PROJECT_ROOT = path.join(__dirname, '..');
const PATH_TO_XELATEX = path.join(PROJECT_ROOT, 'xelatex.js');

const DEFAULT_ENV = {
  cwd: path.join(__dirname, '..')
};

// Returns the path on the filesystem to a sample tex file.
const actualPath = filename => {
  if (filename) {
    return path.join(__dirname, 'samples', filename);
  }
  return path.join(__dirname, 'samples');
};

// Returns a path usable by the virtual xelatex filesystem for a sample tex
// file.
const xelatexPath = filename => {
  return path.join('cwd', path.relative(PROJECT_ROOT, actualPath(filename)));
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
    t.error(e, 'exit status ok');
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

test('xelatex can compile hello_world.tex to XDV', t => {
  const xelatexOutputDir = xelatexPath();
  const xelatexInputFile = xelatexPath('hello_world.tex');
  const outputFile = actualPath('hello_world.xdv');
  fs.unlink(outputFile, _ => {
    fs.access(outputFile, e => {
      t.ok(e, `${outputFile} does not exist before compiling`);
      xelatex([
        '-no-pdf', `-output-directory=${xelatexOutputDir}`, xelatexInputFile
      ], (e, stdout, stderr) => {
        t.error(e, 'exit status ok');
        fs.readFile(outputFile, (e, data) => {
          t.error(e, `${outputFile} should exist`);
          t.ok(data, `${outputFile} should have some content`);
        });
      });

      t.end();
    });
  });
});
