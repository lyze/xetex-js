/* global ENVIRONMENT_IS_NODE, FS, NODEFS */
var Module = {
  thisProgram: './xelatex',
  preInit: function() {
    FS.createDataFile('.', Module.thisProgram, 'Dummy file for kpathsea.', true, true);
    if (ENVIRONMENT_IS_NODE) {
      FS.mount(NODEFS, {root: '.'}, '.'); // TODO... hmmm....
    }
  }
};
