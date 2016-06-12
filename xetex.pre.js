/**
 * Preamble to xdvipdfmx.worker.js.
 *
 * @license The preamble and postamble are copyright (c) 2016 by David Xu.
 *
 * The rest of this file is a derivative work of the XeTeX system that is
 * Copyright (c) 1994-2008 by SIL International
 * Copyright (c) 2009-2012 by Jonathan Kew
 * Copyright (c) 2010-2012 by Han The Thanh
 * Copyright (c) 2012-2015 by Khaled Hosny
 * Copyright (c) 2012-2013 by Jiang Jiang
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
 *
 * Except as contained in this notice, the name of the copyright holders shall
 * not be used in advertising or otherwise to promote the sale, use or other
 * dealings in this Software without prior written authorization from the
 * copyright holders.
 */
/* global ENV, ENVIRONMENT_IS_NODE, FS, NODEFS */
var Module = {
  'thisProgram': 'cwd/xelatex',
  'preInit': function() {
    if (ENVIRONMENT_IS_NODE) {
      FS.mkdir('cwd');
      FS.mount(NODEFS, {'root': '.'}, 'cwd');
    }
  },
  'preRun': function() {
    if (ENVIRONMENT_IS_NODE) {
      ENV['TEXMFDIST'] = '{cwd,cwd/texlive,cwd/texlive-basic,cwd/texlive-full}/texmf-dist';
      ENV['TEXMFCNF'] = 'cwd:$TEXMFDIST/web2c:';
      ENV['TEXINPUTS'] = 'cwd:';
      ENV['TEXFORMATS'] = 'cwd:';
    }
  }
};
