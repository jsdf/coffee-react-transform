#!/usr/bin/env node
var fs = require('fs')
var browserifyAssets = require('browserify-assets')
var chokidar = require('chokidar')


function build() {
  var b = browserifyAssets({
    extensions: [".coffee"],
    cacheFile: './browserify-cache.json',
  })
    .transform(require('coffee-reactify'))
    .add(require.resolve('./'))
    .on('log', function(msg){ console.log(msg) })
    .on('allBundlesComplete', function(msg){ console.log('finished') })
    .on('assetStream', function(assetStream) {
      assetStream
        .on('error', function (err) { console.error(err) })
        .pipe(fs.createWriteStream('./bundles/bundle.css'))
    })
    .bundle()
      .on('error', function (err) { console.error(err) })
      .pipe(fs.createWriteStream('./bundles/bundle.js'))
}

var watcher = chokidar.watch('./src/', {ignored: /[\/\\]\./, persistent: true})
  .on('change', function (change) {
    console.log('changed '+change)
    build()
  })

console.log('watching')
build()
