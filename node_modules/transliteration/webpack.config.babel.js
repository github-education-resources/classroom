import webpack from 'webpack';
const config = {
  devtool: 'source-map',
  entry: {
    node: './src/main/index.js',
  },
  output: {
    path: 'dist/node',
    filename: '[name].js',
    umdNamedDefine: true,
  },
  module: {
    loaders: [
      {
        test: /\.js$/,
        loader: 'babel-loader?presets[]=es2015-ie',
      }
    ]
  },
  plugins: [
    new webpack.NoEmitOnErrorsPlugin(),
    new webpack.optimize.OccurrenceOrderPlugin(),
    new webpack.optimize.UglifyJsPlugin({
      compress: {
        warnings: false,
        unused: true,
        dead_code: true,
      },
      output: {
        comments: false,
      }
    }),
  ]
};
export default config;
