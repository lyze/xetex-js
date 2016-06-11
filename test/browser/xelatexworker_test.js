import test from 'blue-tape';
import { polyfill } from 'es6-promise';

import { WorkerController, XeLaTeXController } from '../../workercontroller';

polyfill();

test('XeTeX has a version', t => {
  var stdout = [];
  var controller = new WorkerController('xetex.worker.js', msg => {
    if (msg.data.channel === 'stdout') {
      stdout.push(msg.data.data);
    }
  });
  return controller.reload()
    .then(_ => controller.sendMessage({
      namespace: 'Module', command: 'callMain',
      arguments: [['-version']]
    }))
    .then(_ => {
      t.ok(stdout.length, 'should print stuff to stdout');
      t.ok(stdout[0].startsWith('XeTeX 3.1415926-'), 'should have a version');
    })
    .then(_ => controller.terminate());
});

test('XeTeX can start up', t => {
  var stdout = [];
  var controller = new WorkerController('xetex.worker.js', msg => {
    if (msg.data.channel === 'stdout') {
      stdout.push(msg.data.data);
    }
  });
  return controller.reload()
    .then(_ =>
          controller.sendMessage({namespace: 'Module', command: 'callMain'}))
    .then(_ => {
      t.fail('xelatex should have a nonzero status code ' +
             'if neither arguments nor standard input are given.');
    }, _ => {
      t.ok(stdout.length, 'should print stuff to stdout');
      t.ok(stdout[0].startsWith('This is XeTeX'), 'should have a version');
    })
    .then(_ => controller.terminate());
});


const assertFileHasContentAsync = (t, controller, filename) => {
  return controller.readFile(filename).then(result => {
    console.log('result', result);
    t.ok(result.ret, `${filename} should exist`);
    t.ok(result.ret.length, `${filename} should have nonempty content`);
  });
};

test('XeLaTeXController can compile hello_world.tex to hello_world.xdv', t => {
  var xelatex = new XeLaTeXController('xetex.worker.js');
  xelatex.trimManifestPrefix = 'texlive-basic/';
  return xelatex.reload()
    .then(_ => xelatex.createDataFile(
      '.', 'hello_world.tex',
      '\\documentclass{article}\\begin{document}Hello, world!\\end{document}',
      false,
      true))
    .then(_ => xelatex.sendMessage({
      namespace: 'Module', command: 'callMain',
      arguments: [['-interaction=nonstopmode', '-no-pdf', 'hello_world.tex']]
    }))
    .then(_ => assertFileHasContentAsync(t, xelatex, 'hello_world.xdv'));
});
