{inspect} = require 'util'
Parser = require '../src/parser'

exports.printTree = (code) ->
  exports.inspect new Parser().parse(code)

exports.inspect = (obj) ->
  console.log inspect obj, showHidden: true, depth: null