/* global ENV, ENVIRONMENT_IS_NODE, FS, NODEFS */
var Module = {
  thisProgram: './cwd/xelatex',
  preInit: function() {
    if (ENVIRONMENT_IS_NODE) {
      FS.mkdir('cwd');
      FS.mount(NODEFS, {root: '.'}, 'cwd');
    }
  },
  preRun: function() {
    if (ENVIRONMENT_IS_NODE) {
      ENV.TEXMFDIST = '{cwd,cwd/texlive,cwd/texlive-basic,cwd/texlive-full}/texmf-dist';
      ENV.TEXMFCNF = 'cwd/:$TEXMFDIST/web2c/:';
      ENV.TEXINPUTS = 'cwd/:';
      ENV.TEXFORMATS = 'cwd/:';
    }
  }
};
