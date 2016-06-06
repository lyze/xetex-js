/**
 * Postamble to xetex.worker.js.
 *
 * @license Copyright David Xu, 2016
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
// Generated code ends here.

  return [Module, FS];
};

var FS;

var updateToNewModule = function() {
  if (Module.HEAPU8) {
    Module.HEAPU8.fill(0);  // avoids choking when assertions are enabled.
    Module.calledRun = false; // hack
  }
  var m = xetexCore(Module);
  // update globals
  Module = m[0];
  FS = m[1];
};


var runtimeInitializedCallbacks = [];

Module.onRuntimeInitialized = function () {
  runtimeInitializedCallbacks.forEach(function (callback) {
    callback();
  });
  runtimeInitializedCallbacks = [];
};

var replyThroughPort = function(event, msg, altMsg) {
  if (event.ports.length === 0) {
    return;
  }
  var replyPort = event.ports[0];
  if (msg.error) {
    // Transform errors to allow structured cloning
    var error = msg.error;
    if (error instanceof FS.ErrnoError) {
      msg.error = {
        code: error.code,
        errno: error.errno,
        message: error.message,
        stack: error.stack
      };
    } else if (error instanceof Error) {
      msg.error = {
        message: error.message,
        stack: error.stack
      };
    }
  }
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

var execute = function(event, handler, message) {
  try {
    var retVal = handler(message);
    var ret = message.hasOwnProperty('ret') ? message['ret'] : retVal;
    replyThroughPort(event, {ret: ret}, {ret: null});
  } catch (e) {
    console.error(e);
    replyThroughPort(event, {error: e}, {error: e.toString()});
  }
};

var executeAsync = function(event, asyncHandler, message) {
  asyncHandler(message).then(function(retVal) {
    var ret = message.hasOwnProperty('ret') ? message['ret'] : retVal;
    replyThroughPort(event, {ret: ret}, {ret: null});
  }, function(e) {
    console.error(e);
    replyThroughPort(event, {error: e}, {error: e.toString()});
  });
};

var handleReloadAsync = function () {
  return new Promise(function (resolve) {
    if (runtimeInitializedCallbacks.length === 0) {
      updateToNewModule();
    }
    runtimeInitializedCallbacks.push(function () {
      resolve(new Date());
    });
  });
};

var callMainAsync = function(data) {
  return new Promise(function(resolve, reject) {
    Module.onExit = function(status) {
      if (status === 0) {
        resolve(status);
      } else {
        reject({
          message: 'Program exited with a nonzero status code.',
          status: status
        });
      }
    };
    Module.callMain.apply(Module, data.arguments);
  });
};

var handleModuleMessage = function(data) {
  return Module[data.command].apply(Module, data.arguments);
};

var handleFSMessage = function(data) {
  if (data.command === 'mount' && data.arguments && data.arguments.length > 0) {
    switch (data.arguments[0]) {
    case 'MEMFS':
      data.arguments[0] = MEMFS;
      break;
    case 'NODEFS':
      data.arguments[0] = NODEFS;
      break;
    case 'IDBFS':
      data.arguments[0] = IDBFS;
      break;
    case 'WORKERFS':
      data.arguments[0] = WORKERFS;
      break;
    }
    return FS[data.command].apply(FS, data.arguments);
  }
  return FS[data.command].apply(FS, data.arguments);
};

self.onmessage = function(e) {
  var data = e.data;
  // Kludge to reload the module
  if (e.data === 'reload') {
    // Recreate the module.
    executeAsync(e, handleReloadAsync, data);
    return;
  }

  // Kludge to get an exit status
  if (data.namespace === 'Module' && data.command === 'callMain') {
    executeAsync(e, callMainAsync, data);
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
