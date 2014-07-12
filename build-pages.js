#!/usr/bin/env node
var fs = require('fs')
var browserify = require('browserify-incremental')
var chokidar = require('chokidar')
var less = require('less')
var through = require('through')

var bundler, watcher

var stylePath = './src/style.less'
var codePath = './src/try-cr'

function log() { console.log.apply(console, arguments) }
function build() {
  log('bundling...')
  console.time('js bundled')
  console.time('css bundled')
  bundler.bundle()
    .pipe(fs.createWriteStream('./bundles/bundle.js'))
    .on('close', function() { console.timeEnd('js bundled') })
  buildStyles(stylePath)
    .pipe(fs.createWriteStream('./bundles/bundle.css'))
    .on('close', function() { console.timeEnd('css bundled') })
}

function buildStyles(lessFile) {
  var outstream = through()
  fs.readFile(lessFile, {encoding: 'utf8'}, function(err, lessCss) {
    if (err) return console.error(err)
    less.render(lessCss, function (err, css) {
      if (err) return console.error(err)
      outstream.end(css)
    })
  })
  return outstream
}

bundler = browserify({
  extensions: [".coffee"],
  cacheFile: './browserify-cache.json',
})
  .transform('coffee-reactify')
  .add(codePath)

watcher = chokidar.watch('./src/', {ignored: /[\/\\]\./, persistent: true})
  .on('change', function (change) {
    log('changed '+change)
    build()
  })

log('watching...')