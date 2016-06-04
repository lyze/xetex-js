/* global Worker */

export class XeTeX {
  constructor(workerPath, onMessageFn, onErrorFn) {
    this.worker = new Worker(workerPath);
    this.worker.onmessage = onMessageFn ? onMessageFn : e => console.log(e);
    this.worker.onerror = onErrorFn ? onErrorFn : e => console.error(e);
  }

  postMessage(...args) {
    return this.worker.postMessage(args);
  }
}
