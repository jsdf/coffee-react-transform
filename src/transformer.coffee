
# Import the helpers we need.
{count, starts, compact, last, repeat,
locationDataToString,  throwSyntaxError} = require './helpers'

Parser = require './parser'
serialise = require './serialiser'

module.exports.transform = (code, opts) ->
  serialise new Parser().parse code, opts
