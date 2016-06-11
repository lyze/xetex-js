// import buble from 'rollup-plugin-buble'; // https://gitlab.com/Rich-Harris/buble/issues/69
import babel from 'rollup-plugin-babel';
import uglify from 'rollup-plugin-uglify';

export default {
  entry: 'workercontroller.js',
  plugins: [
    babel({presets: ['es2015-rollup']}),
    // buble({
    //   transforms: {dangerousForOf: true}
    // }),
    uglify({preserveComments: 'some'})
  ],
  targets: [
    {
      format: 'umd',
      dest: 'workercontroller.umd.js',
      moduleName: 'workercontroller'
    }
  ],
  sourceMap: true
};
