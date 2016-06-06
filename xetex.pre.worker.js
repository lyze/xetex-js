/**
 * Preamble to xetex.worker.js.
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
var Module = {
  thisProgram: './xelatex',
  print: function(data) {
    self.postMessage({channel: 'stdout', data: data});
  },
  printErr: function(data) {
    self.postMessage({channel: 'stderr', data: data});
  },
  onRuntimeInitialized: function () {
    self.postMessage({
      channel: 'ready',
      time: new Date()
    });
  }
};

var xetexCore = function(Module) {
  Module.preInit = function() {
    try {
      FS.createDataFile('/', Module.thisProgram, 'Dummy file for kpathsea', true, true);
    } catch (e) {
      if (e.errno === ERRNO_CODES.EEXIST) {
        return;
      }
      throw e;
    }
  };

// Generated code starts here.
