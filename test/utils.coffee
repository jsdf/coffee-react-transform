{inspect} = require 'util'
Parser = require '../src/parser'

module.exports.printTree = (code) ->
  console.log inspect new Parser().parse(code), showHidden: true, depth: null
