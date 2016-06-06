/* global MessageChannel, Worker */
/**
 * @license Copyright David Xu, 2016
 */

/**
 * Controller for a worker that will run a xetex process.
 *
 * The xetex worker automatically reloads its image when it exits. The worker
 * sends a message back to the controller when the code module is reloaded,
 * including the first time that it is loaded. The worker also communicates
 * {@code stdout} and {@code stdin}.
 *
 * @example
 * var controller = new XeTeX('xetex.worker.js', response => {
 *   switch (response.channel) {
 *     case 'ready':
 *       console.log('Ready.')
 *       console.log(`worker image reloaded at ${event.time}`);
 *       prepareVirtualFS(controller);
 *       break;
 *
 *     case 'stdout':
 *       console.log(response.data);
 *       break;
 *
 *     case 'stderr':
 *       console.warn(response.data);
 *       break;
 *   }
 * }, e => {
 *   console.error(e);
 * });
 */
export class XeTeX {
  /**
   * Creates a controller for a worker that will run a xetex process.
   *
   * @constructor
   * @param {string} workerPath the URL of the xetex worker
   * @param {function(MessageEvent)=} onMessageFn handler for {@code onmessage}
   * @param {function(MessageEvent)=} onErrorFn handler for {@code onerror}
   */
  constructor(workerPath, onMessageFn, onErrorFn) {
    this.worker = new Worker(workerPath);
    this.worker.onmessage = onMessageFn ? onMessageFn : e => console.log(e);
    this.worker.onerror = onErrorFn ? onErrorFn : e => console.error(e);
  }

  /**
   * Delegates to {@code Worker.postMessage}.
   *
   * @param {...*} args the arguments to pass to {@code Worker.postMessage}
   */
  postMessage(...args) {
    this.worker.postMessage(...args);
  }

  /**
   * Sends the specified message to the worker.
   *
   * @example
   * controller.sendMessage({
   *   namespace: 'Module', command: 'callMain',
   *   arguments: [['-interaction=nonstopmode', './source.tex']]
   * })
   * @example
   * // Specify a success value if ordinarily the return value is not structured cloneable.
   * controller.sendMessage({
   *   namespace: 'FS', command: 'createLazyFile',
   *   arguments: ['/', 'xelatex.fmt', 'xetex/xelatex.fmt', true, false],
   *   ret: null,
   * });
   * @param {Object} message the message to send
   * @return {Promise} a promise that is resolved when the requested worker
   * action completes
   */
  sendMessage(message) {
    return new Promise((resolve, reject) => {
      var messageChannel = new MessageChannel();
      messageChannel.port1.onmessage = event => {
        if (event.data.error) {
          reject(event.data.error);
        } else {
          resolve(event.data);
        }
      };
      this.postMessage(message, [messageChannel.port2]);
    });
  }
}
