import test from 'blue-tape';
import { polyfill } from 'es6-promise';

import { WorkerController, XdvipdfmxController, XeLaTeXController } from '../../workercontroller';

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
    t.ok(result.ret, `${filename} should exist`);
    t.ok(result.ret.length, `${filename} should have nonempty content`);
  });
};

test('xetex.worker.js can compile hello_world.tex to hello_world.xdv', t => {
  var controller = new XeLaTeXController(
    new XdvipdfmxController('xdvipdfmx.worker.js'), 'xetex.worker.js');
  controller.trimManifestPrefix = 'texlive-basic/';
  return controller.reload()
    .then(_ => controller.createDataFile(
      '.', 'hello_world.tex',
      '\\documentclass{article}\\begin{document}Hello, world!\\end{document}',
      [],
      true))
    .then(_ => controller.invokeMain(['-interaction=nonstopmode', '-no-pdf', 'hello_world.tex']))
    .then(_ => assertFileHasContentAsync(t, controller, 'hello_world.xdv'))
    .then(_ => controller.terminate());
});

test('XeLaTeXController can compile hello_world.tex to hello_world.pdf', t => {
  var xelatex = new XeLaTeXController(
    new XdvipdfmxController('xdvipdfmx.worker.js'), 'xetex.worker.js');
  return xelatex.reload()
    .then(_ => {
      return xelatex.compileSourceString(
        '\\documentclass{article}\\begin{document}Hello, world!\\end{document}')
        .then(data => {
          t.ok(data.length, 'PDF content should be nonempty');
        });
    })
    .then(_ => xelatex.terminate());
});
