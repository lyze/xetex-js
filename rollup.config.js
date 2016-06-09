import buble from 'rollup-plugin-buble';
import uglify from 'rollup-plugin-uglify';

export default {
  entry: 'xetexcontroller.js',
  plugins: [
    buble(),
    uglify({preserveComments: 'some'})
  ],
  targets: [
    {format: 'umd', dest: 'xetexcontroller.umd.js', moduleName: 'xetexcontroller'}
  ],
  sourceMap: true
};
