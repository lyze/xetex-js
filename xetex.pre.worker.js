/* global FS, Module */
if (typeof Module === 'undefined') {
  Module = {};
}

Module.noInitialRun = true;

Module.print = function (data) {
  self.postMessage({channel: 'stdout', data: data});
};

Module.printErr = function (data) {
  var showStackTrace = false;
  self.postMessage({channel: 'stderr', data: data});
};


var handleModuleMessage = function (rpc) {
  Module[rpc.command](rpc.arguments);
};

var handleFSMessage = function (rpc) {
  FS[rpc.command](rpc.arguments);
};

self.onmessage = function (e) {
  var rpc = e.data[0];
  switch (rpc.namespace) {
  case 'Module':
    handleModuleMessage(rpc);
    break;

  case 'FS':
    handleFSMessage(rpc);
    break;

  default:
    throw new Error('Unknown namespace: ' + e.namespace);
  }
};
