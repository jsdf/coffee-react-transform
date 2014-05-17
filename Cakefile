fs = require 'fs'
path = require 'path'
{spawn, exec} = require 'child_process'

# ANSI Terminal Colors.
bold = red = green = reset = ''
unless process.env.NODE_DISABLE_COLORS
  bold  = '\x1B[0;1m'
  red   = '\x1B[0;31m'
  green = '\x1B[0;32m'
  reset = '\x1B[0m'


SOURCEFILES = ['transformer', 'parser', 'serialiser', 'symbols', 'helpers']
TESTFILES = ['test.coffee','output-testcases.txt','eval-testcases.txt']
JSFILES = ['htmlelements.js', 'occurrences.js', 'stringescape.js']
  
# Log a message with a color.
log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')

# Build transformer from source.
build = (cb) ->
  run 'mkdir', ['-p','bin', 'lib'], ->
    compile SOURCEFILES, 'src/', 'lib/', ->
      copy JSFILES, 'src/', 'lib/', cb

copy = (srcFiles, srcDir, destDir, cb) ->
  files = srcFiles.map((filename) -> path.join(srcDir, filename))
  run 'cp', files.concat([destDir]), cb

compile = (srcFiles, srcDir, destDir, cb) ->
  args = [
    '--bare',
    '--output', destDir,
    '--compile'
  ].concat srcFiles.map((filename) -> path.join(srcDir, "#{filename}.coffee"))

  coffee args, cb

# Run CoffeeScript command
coffee = (args, cb) -> run 'coffee', args, cb

run = (executable, args = [], cb) ->
  proc =         spawn executable, args
  proc.stdout.on 'data', (buffer) -> log buffer.toString(), green
  proc.stderr.on 'data', (buffer) -> log buffer.toString(), red
  proc.on        'exit', (status) ->
		cb() if typeof cb is 'function'

test = -> coffee ['test/test.coffee']

task 'build', 'build cjsx transformer from source', build

task 'test', 'run tests', test

task 'watch:test', 'watch and run tests', ->
  TESTFILES.forEach (testfile) ->
    fs.watchFile "test/#{testfile}", interval: 1000, test
  SOURCEFILES.forEach (sourcefile) ->
    fs.watchFile "src/#{sourcefile}.coffee", interval: 1000, test
  log "watching..." , green
