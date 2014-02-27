fs = require 'fs'
{spawn, exec} = require 'child_process'

# ANSI Terminal Colors.
bold = red = green = reset = ''
unless process.env.NODE_DISABLE_COLORS
  bold  = '\x1B[0;1m'
  red   = '\x1B[0;31m'
  green = '\x1B[0;32m'
  reset = '\x1B[0m'
  
# Log a message with a color.
log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')


# Build transformer from source.
build = (cb) ->
  run ['--bare', '-o', './', '--compile', './csx-transformer.coffee', './helpers.coffee', './index.coffee'], cb

# Run CoffeeScript command
run = (args, cb) ->
  proc =         spawn 'coffee', [].concat(args)
  proc.stdout.on 'data', (buffer) -> log buffer.toString(), green
  proc.stderr.on 'data', (buffer) -> log buffer.toString(), red
  proc.on        'exit', (status) ->
		cb() if typeof cb is 'function'

test = -> run(['test.coffee'])

task 'build', 'build csx transformer from source', build

task 'test', 'run tests', test

task 'watch:test', 'watch and run tests', ->
  fs.watchFile './csx-transformer.coffee', interval: 1000, test
  fs.watchFile './test.coffee', interval: 1000, test
  log "watching..." , green
