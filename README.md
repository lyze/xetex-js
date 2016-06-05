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
*   `xetex.js` an ES6 module to interact with `xetex.worker.js`.
*   `xetex.umd.js` a UMD module to interact with `xetex.worker.js`.
*   `xetex.worker.js` the compiled JavaScript file that ought to be loaded into
    a
    [web worker](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API).
    *   `xetex.pre.worker.js` a file whose contents is added before the
         generated JavaScript, and appears at the beginning of
         `xetex.worker.js`. This file contains glue to call the
         [Module](https://kripken.github.io/emscripten-site/docs/api_reference/module.html)
         and
         [FS API](https://kripken.github.io/emscripten-site/docs/api_reference/Filesystem-API.html)s
         from `xetex.js`.
*   `xetex/xelatex.fmt` a TeX memory dump that needs to be available in order to
    compile garden variety LaTeX documents.
*   `texlive.lst` a manifest file that lists all of the usable files in the TeX
    Live (basic) distribution. The example uses this manifest file to create a
    virtual filesystem environment that is necessary to compile LaTeX documents.


## Running the example

The example uses the TeX Live basic distribution. An internet connection is
required to download it.

0.  `npm install`
1.  `make texlive.lst`
2.   `npm start`
3.   Visit `example/index.html`.


## Porting notes

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



# License

Distributed under the MIT license. Refer to [LICENSE](LICENSE) for more details.
