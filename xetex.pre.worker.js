/* global FS, Module */
if (typeof Module === 'undefined') {
  Module = {};
}

Module.preInit = function () {
  FS.createDataFile('/', Module['thisProgram'], 'dummy for kpathsea', true, true);
};

Module.print = function (data) {
  self.postMessage({channel: 'stdout', data: data});
};

Module.printErr = function (data) {
  var showStackTrace = false;
  self.postMessage({channel: 'stderr', data: data});
};

var replyThroughPort = function (event, msg, altMsg) {
  if (event.ports.length === 0) {
    return;
  }
  var replyPort = event.ports[0];
  try {
    replyPort.postMessage(msg);
  } catch (e) {
    if (e instanceof DOMException && e.code === DOMException.DATA_CLONE_ERR) {
      console.warn(e, msg);
      replyPort.postMessage(altMsg);
    } else {
      throw e;
    }
  }
};

var execute = function (event, handler, message) {
  try {
    var retVal = handler(message);
    var ret = message.hasOwnProperty('ret') ? message['ret'] : retVal;
    replyThroughPort(event, {ret: ret}, {ret: null});
  } catch (e) {
    console.error(e);
    var errorObj = e instanceof Error ? {
      message: e.message,
      stack: e.stack
    } : e;
    replyThroughPort(event, {error: errorObj}, {error: e.toString()});
  }
};

var executeAsync = function (event, asyncHandler, message) {
  asyncHandler(message).then(function (retVal) {
    var ret = message.hasOwnProperty('ret') ? message['ret'] : retVal;
    replyThroughPort(event, {ret: ret}, {ret: null});
  }, function (e) {
    console.error(e);
    replyThroughPort(event, {error: e}, {error: e.toString()});
  });
};

var isRunning = false;

var asyncCallMain = function (data) {
  console.assert(data.namespace === 'Module' && data.command === 'callMain',
                 'expected handler to receive a request for Module.callMain, but instead got ' + data);
  if (isRunning) {
    return Promise.reject(new Error('Program already running'));
  }
  isRunning = true;
  return new Promise(function (resolve, reject) {
    Module.onExit = function (status) {
      isRunning = false;
      if (status === 0) {
        resolve(status);
      } else {
        reject({
          message: 'Program exited with a nonzero status code.',
          status: status
        });
      }
    };
    Module['callMain'].apply(Module, data.arguments);
  });
};

var handleModuleMessage = function (data) {
  return Module[data.command].apply(Module, data.arguments);
};

var handleFSMessage = function (data) {
  return FS[data.command].apply(FS, data.arguments);
};

self.onmessage = function (e) {
  var data = e.data;
  // Kludge to get an exit status
  if (data.namespace === 'Module' && data.command === 'callMain') {
    executeAsync(e, asyncCallMain, data);
    return;
  }
  var handler;
  switch (data.namespace) {
  case 'Module':
    handler = handleModuleMessage;
    break;
  case 'FS':
    handler = handleFSMessage;
    break;
  default:
    throw new Error('Unknown namespace: ' + e.namespace);
  }
  execute(e, handler, data);
};
