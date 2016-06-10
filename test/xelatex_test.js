/* global __dirname, process */
import { execFile, execFileSync } from 'child_process';
import fs from 'fs';
import path from 'path';

import test from 'blue-tape';

const PROJECT_ROOT = path.join(__dirname, '..');
const PATH_TO_XELATEX = path.join(PROJECT_ROOT, 'xelatex.js');
const PATH_TO_XDVIPDFMX = path.join(PROJECT_ROOT, 'xdvipdfmx.js');

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
const virtualPath = filename => {
  return path.join('cwd', path.relative(PROJECT_ROOT, actualPath(filename)));
};

const _execFileAsync = (exe, args = []) => {
  args = [exe, ...args];
  return new Promise((resolve, reject) => {
    execFile(process.execPath, args, DEFAULT_ENV, (e, stdout, stderr) => {
      if (e) {
        reject([e, stdout, stderr]);
      } else {
        resolve([stdout, stderr]);
      }
    });
  });
};

const xelatex = args => _execFileAsync(PATH_TO_XELATEX, args);

const xdvipdfmx = args => _execFileAsync(PATH_TO_XDVIPDFMX, args);

test('xelatex.js exists', t => {
  fs.access(PATH_TO_XELATEX, fs.F_OK, t.end);
});

test('xelatex has a version', t => {
  return xelatex(['-version']).then(([stdout, stderr]) => {
    if (stdout.startsWith('XeTeX 3.1415926-')) {
      t.pass('has a version string');
    } else {
      t.fail(`Unexpected stdout: <${stdout}>`);
    }
  });
});

test('xelatex can start up', t => {
  return xelatex().then(_ => {
    t.fail('xelatex should have a nonzero status code if neither arguments nor standard input are given.');
  }, ([e, stdout, stderr]) => {
    if (stdout.startsWith('This is XeTeX')) {
      t.pass('has a version string');
    } else {
      t.fail(`Unexpected stdout: <${stdout}>`);
    }
  });
});

test('xdvipdfmx has a version', t => {
  return xdvipdfmx(['-h']).then(([stdout, stderr]) => {
    if (stdout.trim().startsWith('This is xdvipdfmx')) {
      t.pass('has a version string');
    } else {
      t.fail(`Unexpected stdout: <${stdout}>`);
    }
  });
});


const ensureFileDoesNotExist = (t, file) => new Promise((resolve, reject) => {
  fs.unlink(file, _ => {
    fs.access(file, e => {
      t.ok(e, `${file} does not exist`);
      if (e) { // truthy => file exists error---just what the doctor ordered
        resolve(e);
      } else {
        reject();
      }
    });
  });
});

const checkNonEmptyContent = (t, filename) => new Promise((resolve, reject) => {
  fs.readFile(filename, (e, data) => {
    t.error(e, `${filename} should exist`);
    t.ok(data, `${filename} should have some content`);
    if (e) {
      reject(e);
    } else {
      resolve(filename);
    }
  });
});


test('xelatex can compile hello_world.tex', t => {
  const virtualOutputDir = virtualPath();
  const virtualTex = virtualPath('hello_world.tex');
  const outputXdv = actualPath('hello_world.xdv');
  const virtualXdv = virtualPath('hello_world.xdv');
  const virtualPdf = virtualPath('hello_world.pdf');
  const outputPdf = actualPath('hello_world.pdf');

  return ensureFileDoesNotExist(t, outputXdv)
    .then(_ => xelatex([
      '-no-pdf', `-output-directory=${virtualOutputDir}`, virtualTex
    ]))
    .then(_ => checkNonEmptyContent(t, outputXdv))

    .then(_ => {
      t.test('xdvipdfmx can convert hello_world.xdv to PDF', tt => {
        return ensureFileDoesNotExist(t, outputPdf)
          .then(_ => xdvipdfmx(['-o', virtualPdf, virtualXdv]))
          .then(_ => checkNonEmptyContent(tt, outputPdf));
      });
    });
});
