import * as esbuild from 'esbuild'

await esbuild.build({
  entryPoints: ['app.js'],
  bundle: true,
  outfile: '../priv/static/assets/app.js',
})