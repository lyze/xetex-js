/* global MessageChannel, Worker */
/**
 * @license Copyright David Xu, 2016
 */

/**
 * Controller for a worker that will run a xetex process.
 */
export class XeTeX {
  /**
   * Creates a controller for a worker that will run a xetex process.
   *
   * @param {string} workerPath the URL of the xetex worker
   * @param {function(MessageEvent)} onMessageFn
   * @param {function(MessageEvent)} onErrorFn
   */
  constructor(workerPath, onMessageFn, onErrorFn) {
    this.worker = new Worker(workerPath);
    this.worker.onmessage = onMessageFn ? onMessageFn : e => console.log(e);
    this.worker.onerror = onErrorFn ? onErrorFn : e => console.error(e);
  }

  /**
   * Delegates to {@code Worker.postMessage}.
   *
   * @param {...*} args
   */
  postMessage(...args) {
    this.worker.postMessage(...args);
  }

  /**
   * Sends the specified message to the worker.
   *
   * @param {Object} message the message to send
   * @return {Promise} a promise that is resolved when the requested worker
   * action completes.
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
