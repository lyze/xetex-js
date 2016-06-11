/* global MessageChannel, Worker */
/**
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

/**
 * Interacts with a web worker running an Emscriptified program that will
 * respond on a MessageChannel port.
 *
 * The worker does not automatically load (nor run) the program image when it
 * the worker is loaded from its URL. Manually trigger loading by calling {@link
 * #reload}. The worker does not automatically reload (nor run) its image when
 * the program image exits.
 *
 * The worker also communicates `stdout` and `stdin`.
 *
 * @example <caption>Default behavior of `onmessage` and `onerror` handlers.</caption>
 * var controller = new WorkerController('xetex.worker.js', event => {
 *   var response = event.data;
 *   switch (response.channel) {
 *     case 'stdout':
 *       console.log(response.data);
 *       break;
 *
 *     case 'stderr':
 *       console.warn(response.data);
 *       break;
 *
 *     default:
 *       console.log(response);
 *   }
 * }, e => {
 *   console.error(e);
 * });
 */
export class WorkerController {
  /**
   * Creates a controller for a web worker.
   *
   * @param {string} workerPath the URL of the xetex worker
   * @param {function(MessageEvent)=} onMessageFn handler for `onmessage`
   * @param {function(MessageEvent)=} onErrorFn handler for `onerror`
   */
  constructor(workerPath, onMessageFn, onErrorFn) {
    this.worker = new Worker(workerPath);
    this.worker.onmessage = onMessageFn ? onMessageFn : event => {
      var response = event.data;
      switch (response.channel) {
        case 'stdout':
          console.log(response.data);
          break;

        case 'stderr':
          console.warn(response.data);
          break;

        default: // unknown channel
          console.log(response);
      }
    };
    this.worker.onerror = onErrorFn ? onErrorFn : e => console.error(e);
  }

  /**
   * Reloads the worker image.
   *
   * @return {Promise} a promise that resolves to a {@link Date} object
   * describing when the runtime is initialized
   */
  reload() {
    return this.sendMessage('reload');
  }

  /**
   * Sends the specified message to the worker.
   *
   * @example
   * // Causes the worker to reload the program image.
   * controller.sendMessage('reload');
   * @example
   * controller.sendMessage({
   *   namespace: 'Module', command: 'callMain',
   *   arguments: [['-interaction=nonstopmode', 'source.tex']]
   * })
   * @example
   * // Specify a success value if ordinarily the return value is not structured
   * // cloneable. Otherwise, you'll get a warning.
   * controller.sendMessage({
   *   namespace: 'FS', command: 'createLazyFile',
   *   arguments: ['/', 'xelatex.fmt', 'xelatex.fmt', true, false],
   *   ret: null,
   * });
   * @example
   * // Special case for FS.mount
   * controller.sendMessage({
   *   namespace: 'FS', command: 'mount',
   *   arguments: ['IDBFS', {}, '/will-be-persisted-after-calling-FS.syncfs']
   * });
   * @param {Object} message the message to send
   * @param {Array=} opt_transferList an array of transferable objects to
   * transfer ownership from the calling context to the receiving worker
   * @return {Promise} a promise that is resolved when the requested worker
   * action completes
   */
  sendMessage(message, opt_transferList = []) {
    return new Promise((resolve, reject) => {
      var channel = new MessageChannel();
      channel.port1.onmessage = event => {
        if (event.data.error) {
          reject(event.data.error);
        } else {
          resolve(event.data);
        }
      };
      this.postMessage(message, [channel.port2].concat(opt_transferList));
    });
  }

  /**
   * Delegates to {@link Worker#postMessage}.
   *
   * @param {...*} args the arguments to pass to {@link Worker#postMessage}
   */
  postMessage(...args) {
    this.worker.postMessage(...args);
  }


  /**
   * Terminates the worker, rendering this instance useless.
   */
  terminate() {
    this.worker.terminate();
  }
}

/**
 * Interacts with a web worker running `xelatex.worker.js`.
 *
 * When calling {@link #reload()}, an instance of this class will prepare the
 * virtual filesystem with a TeX Live environment. It will lazily load the
 * `xelatex` memory dump at {@link #xelatexFmtUrl}. It will read a manifest file
 * from {@link #texLiveManifestUrl}) and map the distribution into the virtual
 * filesystem in the directory {@link #virtualTexLiveRootDir}. The manifest file
 * is a plain text file that contains lines describing each file in the TeX Live
 * distribution. Every line can either have one or two items (separated by a
 * single space). If there is only a single item on a line, then that item is
 * interpreted as the file to load found at a relative URL of the same name.
 * Otherwise, the second item is a URL from where the file can be retrieved.
 *
 * @extends WorkerController
 * @example <caption>Valid lines in the manifest file</caption>
 * texmf-dist/web2c/texmf.cnf URL_TO_texmf.cnf
 * texmf-dist/ls-R
 * texmf-var/tex/generic/config/language.dat URL_TO_language.dat
 */
export class XeLaTeXController extends WorkerController {

  /**
   * Constructs an instance of this class.
   */
  constructor(...args) {
    super(...args);

    /**
     * The URL of the `xelatex` memory dump.
     *
     * @default 'xelatex.fmt'
     */
    this.xelatexFmtUrl = 'xelatex.fmt';

    /**
     * The URL from which to retrieve a listing of files in the TeX Live
     * distribution.
     *
     * @default 'texlive.lst'
     */
    this.texLiveManifestUrl = 'texlive.lst';

    /**
     * The target root directory in the virtual filesystem of the TeX Live
     * distribution.
     *
     * @default 'texlive'
     */
    this.virtualTexLiveRootDir = 'texlive';
  }

  getTexmfCnfContent() {
    return `TEXMFDIST = /${this.virtualTexLiveRootDir}/texmf-dist\n` +
      `TEXMFLOCAL = /${this.virtualTexLiveRootDir}/texmf-local\n` +
      `TEXMFCONFIG = /${this.virtualTexLiveRootDir}/texmf-config\n` +
      'TEXMF = {!!$TEXMFDIST,!!$TEXMFLOCAL,!!$TEXMFCONFIG}\n';
  }

  _prepareTeXLiveFromManifest(response, resolve, reject) {
    var lines = response.split('\n');
    var commands = [];
    var numFiles = 0;
    commands.push(this.sendMessage({
      namespace: 'FS', command: 'createPath',
      arguments: ['/', this.virtualTexLiveRootDir, true, true],
      ret: null
    }));
    for (let line of lines) {
      if (!line) {
        continue;
      }
      var parts = line.split(' ', 2);
      var path = parts[0];
      var location;
      if (parts.length === 2) {
        location = parts[1];
      } else {
        location = parts[0];
      }
      var lastSlash = path.lastIndexOf('/');
      var vdir = this.virtualTexLiveRootDir + '/';
      var filename;
      if (lastSlash === -1) {
        filename = path;
      } else {
        filename = path.slice(lastSlash + 1);
        var dir = path.slice(0, lastSlash);
        vdir += dir;
        this.sendMessage({
          namespace: 'FS', command: 'createPath',
          arguments: ['/', vdir, true, true],
          ret: null
        });
      }
      if (!filename) {
        console.error(`Not a file: ${path}`);
        continue;
      }
      commands.push(
        this.sendMessage({
          namespace: 'FS', command: 'createLazyFile',
          arguments: [vdir, filename, location, true, false],
          ret: null
        }).then(_ => {
          numFiles++;
        }));

      if (path === 'texmf-dist/web2c/texmf.cnf') {
        // Make the provided web2c/texmf.cnf available on the kpathsea search
        // path. The location of this file needs to come after our custom
        // texmf.cnf in the search order. Don't include these in the count of
        // the number of files because these are not part of the manifest.
        commands.push(this.sendMessage({
          namespace: 'FS', command: 'createPath',
          arguments: ['/', 'share/texmf-dist/web2c/', true, true],
          ret: null
        }));
        // Apparently, a symlink does not work for kpathsea in this virtual
        // Emscripten filesystem environment. It skips over the link.
        commands.push(this.sendMessage({
          namespace: 'FS', command: 'createLazyFile',
          arguments: ['/share/texmf-dist/web2c/', 'texmf.cnf', location, true, false],
          ret: null
        }));
      }
    }

    // Resolve the promise that was given
    Promise.all(commands).then(_ => resolve({numFiles: numFiles}), reject);
  }

  _loadFromManifest() {
    return new Promise((resolve, reject) => {
      var manifestXhr = new XMLHttpRequest();
      manifestXhr.open('GET', this.texLiveManifestUrl);
      manifestXhr.onreadystatechange = () => {
        if (manifestXhr.readyState === XMLHttpRequest.DONE) {
          if (manifestXhr.status === 200) {
            this._prepareTeXLiveFromManifest(manifestXhr.response, resolve, reject);
          } else {
            console.error('Cannot retrieve manifest file.', manifestXhr);
            reject(manifestXhr);
          }
        }
      };
      // kick it off
      manifestXhr.send();
    });
  }

  /**
   * Reloads the image and sets up TeX Live. Files are loaded lazily.
   *
   * @override
   * @return {Promise} a promise that resolves with an object describing the
   * number of virtual files created from the manifest.
   */
  reload() {
    return super.reload().then(_ => {
      var actions = [
        // Create the TeX memory dump in the filesystem.
        this.sendMessage({
          namespace: 'FS', command: 'createLazyFile',
          arguments: ['/', 'xelatex.fmt', this.xelatexFmtUrl, true, false],
          ret: null
        }),

        // Set up some overrides. Remember that earlier definitions override later
        // ones in the kpathsea search path.
        this.sendMessage({
          namespace: 'FS', command: 'createDataFile',
          arguments: ['/', 'texmf.cnf', this.getTexmfCnfContent(), true, false],
          ret: null
        }),

        this._loadFromManifest()
      ];
      // return the stats from loadFromManifest (last in actions array)
      return Promise.all(actions).then(results => results[results.length - 1]);
    });
  }

  /**
   * Creates a file in the virtual filesystem. This is a wrapper around
   * {@link https://kripken.github.io/emscripten-site/docs/api_reference/advanced-apis.html#FS.createDataFile FS.createDataFile}.
   *
   * @param {string} parent the parent directory
   * @param {string} filename the name of the new file
   * @param {string|ArrayBufferView} data the data to write to the file
   * @param {boolean} shouldTransfer whether to transfer ownership of
   * `data`
   * @param {...boolean} opt_perms `canRead`, `canWrite`, `canOwn`
   * @return {Promise} a promise that is resolved when the file is created with
   * the data.
   */
  createDataFile(parent, filename, data, shouldTransfer, ...perms) {
    perms = perms || [];
    return this.sendMessage({
      namespace: 'FS', command: 'createDataFile',
      arguments: [parent, filename, data, ...perms],
      ret: null
    }, shouldTransfer ? [data] : undefined);
  }

  /**
   * Reads the data in the file from the virtual filesystem. This is a wrapper
   * around {@link https://kripken.github.io/emscripten-site/docs/api_reference/Filesystem-API.html#FS.readFile FS.readFile}.
   *
   * @param {string} path the path to the file
   * @param {Object} options the options to pass to
   * {@link https://kripken.github.io/emscripten-site/docs/api_reference/Filesystem-API.html#FS.readFile FS.readFile}
   * @param {string} options.encoding the encoding of the returned data.
   * Normally, the data will be copied from the worker to the calling context.
   * But if the encoding yields data that can be transferable by taking
   * ownership (a much cheaper operation), then this function will do so.
   */
  readFile(path, options) {
    return this.sendMessage({
      namespace: 'FS', command: 'readFile',
      arguments: [path, options],
      retTransfer: options && options.encoding === 'binary'
    });
  }

}
