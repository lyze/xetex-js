# xetex-js

This is a port of XeTeX to JavaScript.

See the example for usage in a web browser. Compilation of LaTeX documents
occurs strictly in the browser. Since filesystem access needs to be emulated,
the example does so by lazily retrieving files (like styles and class
definitions). This project also provides a straightforward Promise-based
interface to interact with a web worker running XeTeX.

This project has an optional dependency on TeX Live. It is optional in the sense
that it is not actually necessary to build XeTeX, but the end program would
otherwise be unable to actually compile your garden-variety LaTeX documents.


## Building from scratch

Note that building from scratch and running the example are orthogonal concerns,
since the generated artifacts are checked in.

An internet connection is required.

1.  [Install Emscripten.](https://kripken.github.io/emscripten-site/)
2.  Run `make`.

Artifacts:

*   `xetex.bc` linked bitcode that can be compiled into JavaScript
*   `xetex.js` executable for a JavaScript engine
*   `xetex.worker.js`compiled JavaScript file that ought to be loaded into a
    browser
    [web worker](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API).
    *   `xetex.pre.worker.js` and `xetex.post.worker.js` files whose contents are
        added before/after the generated JavaScript `xetex.worker.js`. They contain
        contain glue to call the
        [Module](https://kripken.github.io/emscripten-site/docs/api_reference/module.html)
        and
        [FS API](https://kripken.github.io/emscripten-site/docs/api_reference/Filesystem-API.html)s
        from `xetexcontroller.js`.
*   `xetexcontroller.js` ES6 browser module to interact with `xetex.worker.js`.
*   `xetexcontroller.umd.js` UMD browser module to interact with `xetex.worker.js`.
*   `xetex/xelatex.fmt` TeX memory dump that needs to be available in order to
    compile garden-variety LaTeX documents.
*   `texlive.lst` manifest file that lists all of the usable files in the TeX
    Live (basic) distribution. The example uses this manifest file to create a
    virtual filesystem environment that is necessary to compile LaTeX documents.


## Running the example

The example uses the TeX Live basic distribution. An internet connection is
required to download it.

0.  `npm install`
1.  `make texlive.lst`
2.   `npm start`
3.   Visit `example/index.html`.


## Known limitations

It is not feasible to execute the main function multiple times because there are
memory leaks. The easiest (and best) way to run the program multiple times with
a clean state is to create a new instance every time.

[Emscripten does not have a pluggable filesystem at this time.](https://github.com/kripken/emscripten/issues/777)

If you use
[Emscripten's `MEMFS`](https://kripken.github.io/emscripten-site/docs/api_reference/Filesystem-API.html#memfs)
and you need to run the program multiple times, you will have to reconstruct the
filesystem for each new instance.


## Port notes

The build follows the Emscripten recommendation to build the project to both
native and JavaScript targets. Executables are generated to be used by later
steps in the build. Since, the generated JavaScript code cannot be run directly,
the required executables are copied from the native build and then the build is
continued.


## Hints

One major bottleneck is the creation of a `xelatex.fmt` memory dump, which
downloads the full TeX Live distribution. If you have a full TeX Live
distribution on your computer, you can set `USE_SYSTEM_TL=1` when you invoke
`make`. This part can most likely be improved.

There is a lot of output when running `make`. Standard output is sent to
`make.log` by default and standard error is kept on the screen. You may want to
invoke the build with `make 2>&1 | tee log.txt`. Errors during the build are to
be expected (but the overall invocation should be successful), since the
strategy is to `make` as far as possible before replacing missing tools from
the corresponding native build tree.

Configuring [`kpathsea`](https://www.tug.org/texinfohtml/kpathsea.html) search
paths is tricky, so refer to the example for more guidance.

One of the first things that `xetex` does on startup is to stat for the location
of the executable. However, the program image doesn't actually exist on the
filesystem. If using the web worker, this is already handled. The way this is
done is to set `Module.thisProgram` to some path, say `./xelatex`, and then
ensure that there is a dummy file at that path in the actual filesystem:
```
FS.createDataFile('/', Module.thisProgram, 'Dummy file for kpathsea.', true, true);
```
This is what `xetex.pre.worker.js` does.


# License

Distributed under the MIT license. Refer to [LICENSE](LICENSE) for more details.
