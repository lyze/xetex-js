/* global ENVIRONMENT_IS_NODE, FS, NODEFS */

var Module = {
  thisProgram: './xelatex'
};

if (ENVIRONMENT_IS_NODE) {
  FS.mount(NODEFS, {root: '.'}, '.');
}
