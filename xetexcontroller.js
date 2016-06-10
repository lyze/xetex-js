/* global MessageChannel, Worker */
/**
 * @license Copyright David Xu, 2016
 */

/**
 * Controller for a worker that will run a xetex process.
 *
 * The xetex worker does not automatically load the program. Manually trigger
 * loading by calling {@link #reload}. The xetex worker does not automatically
 * reload its image when it exits.
 *
 * The worker also communicates {@code stdout} and {@code stdin}.
 *
 * @example
 * var controller = new XeTeXController('xetex.worker.js', response => {
 *   switch (response.channel) {
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
export class XeTeXController {
  /**
   * Creates a controller for a worker that will run a xetex process. The worker
   * immediately begins the initialization process.
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
   * Reloads the worker image.
   *
   * @return {Promise} a promise that resolves to a {@link Date} object
   * describing when the runtime was initialized
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
   *   arguments: ['/', 'xelatex.fmt', 'xetex/xelatex.fmt', true, false],
   *   ret: null,
   * });
   * @example
   * // Special case for FS.mount
   * controller.sendMessage({
   *   namespace: 'FS', command: 'mount',
   *   arguments: ['IDBFS', {}, '/will-be-persisted-after-calling-FS.syncfs']
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

  /**
   * Delegates to {@code Worker.postMessage}.
   *
   * @param {...*} args the arguments to pass to {@code Worker.postMessage}
   */
  postMessage(...args) {
    this.worker.postMessage(...args);
  }
}
