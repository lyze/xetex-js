# xetex-js

This is a port of XeTeX to JavaScript using Emscripten.

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

*   `xetex.js` module for a JavaScript engine.
*   `xelatex.js` same module as `xetex.js` except with a different name.
*   `xelatex` executable. Runs with `#!/usr/bin/env node`.
*   `xdvipdfmx.js` module for a Javascript engine.
*   `xdvipdfmx` executable. **Not yet Emscriptified.** Runs with `#!/usr/bin/env node`.
    This is the required backend to produce PDF output from `xelatex`. Note that
    this should live next to `xelatex`.
*   `xetex.worker.js`compiled JavaScript file that ought to be loaded into a
    browser as a
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

If `xdvipdfmx` is not built or can't be found, attempts to create PDFs will fail
mysteriously with
```
! I can't write on file `hello_world.pdf'.
```

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

Emscripten's linking model is rather monolithic. It does not support true
dynamic linking. As a result, we have to patch the code and redefine some macros
to prevent duplicate symbols
([like in this issue](https://github.com/kripken/emscripten/issues/831)). The
duplicate symbols come from `freetype2` because `xetex` depends on `fontconfig`
and `freetype2`, but `fontconfig` also depends on `freetype2`.


## Hints

One major bottleneck is the creation of a `xelatex.fmt` memory dump, which
downloads the full TeX Live distribution. If you have a full TeX Live
distribution on your computer, you can set `USE_SYSTEM_TL=1` when you invoke
`make`. You can also skip this step and use a prebuilt `xelatex.fmt` for the
same version of XeTeX, even if the `xelatex.fmt` file was originally built
natively, The file is just a memory dump of the XeTeX engine, and supposing that
the Emscripten compilation is correct, the produced/consumed dump formats should
be equivalent.

There is a lot of output when running `make`. Standard output is sent to
`make.log` by default and standard error is kept on the screen. You may want to
invoke the build with `make 2>&1 | tee log.txt`. Errors during the build are to
be expected (but the overall invocation should be successful), since the
strategy is to `make` as far as possible before replacing missing tools from
the corresponding native build tree.

Configuring [`kpathsea`](https://www.tug.org/texinfohtml/kpathsea.html) search
paths is tricky, so refer to the example for more guidance.

One of the first things that XeTeX does on startup is to stat for the location
of the executable. However, when using a web worker, the program image doesn't
actually exist on the virtual filesystem. The workaround is to set
`Module.thisProgram` to some path, say `./xelatex`, and then ensure that there
is a dummy file at that path in the actual filesystem:
```js
FS.createDataFile('/', Module.thisProgram, 'Dummy file for kpathsea.', true, true);
```
This is what `xetex.pre.worker.js` does.

When using the executable file in a terminal-like environment, we can make our
Em-XeTeX behave more closely to native XeTeX. One major limitation is that
[the root directory of the native filesystem cannot be mounted as the root of the virtual filesystem](https://github.com/kripken/emscripten/issues/2040).
This is adressed by mounting the (native) current working directory in the
virtual directory `/cwd`. Thus, the file [xetex.pre.js](xetex.pre.js) employs
some trickery to have `kpathsea` search `/cwd` as well.


# License

Distributed under the MIT license. Refer to [LICENSE](LICENSE) for more details.
