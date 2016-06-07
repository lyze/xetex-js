/* global __dirname */
import { fork } from 'child_process';
import fs from 'fs';

import test from 'tape';

const PATH_TO_XELATEX = `${__dirname}/../xelatex.js`;
const xelatex = (...args) => {
  return fork(PATH_TO_XELATEX, ...args);
};

              // 'TEXMFDIST = /texlive-basic/texmf-dist\n' +
              // 'TEXMFLOCAL = /texlive-basic/texmf-local\n' +
              // 'TEXMFCONFIG = /texlive-basic/texmf-config\n' +
              // 'TEXMF = {!!$TEXMFDIST,!!$TEXMFLOCAL,!!$TEXMFCONFIG}\n',

test('xelatex.js exists', t => {
  fs.access(PATH_TO_XELATEX, fs.F_OK, t.end);
});


test('xelatex', suite => {

  suite.test('has a version', t => {
    var p = xelatex(['-version'], {}, (e, stdout, stderr) => {
      t.comment('callback');
      t.notOk(e);
      if (stdout.startsWith('XeTeX 3.1415926-')) {
        t.pass('has a version string');
      } else {
        t.fail(`Unexpected stdout: <${stdout}>`);
      }
      t.end();
    });
  });

  suite.test('can start up', t => {
    xelatex([], {}, (e, stdout, stderr) => {
      t.notOk(e);
      if (stdout.startsWith('This is XeTeX, Version ')) {
        t.pass('has a version string');
      } else {
        t.fail(`Unexpected stdout: <${stdout}>`);
      }
      t.end();
    });
  });
});
