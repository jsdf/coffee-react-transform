
Parser = require './parser'
serialise = require './serialiser'

module.exports.transform = (code, opts) ->
  serialise(new Parser().parse(code, opts))
