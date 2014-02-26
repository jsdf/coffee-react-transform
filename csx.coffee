
# Import the helpers we need.
{count, starts, compact, last, repeat,
locationDataToString,  throwSyntaxError} = require './helpers'

# ast node builders
astLeafNode = (type, value = null) -> {type, value}
astBranchNode = (type, value = null, children = []) -> {type, value, children}

exports.rewrite = (code, opts) ->
  serialise new Parser().parse code, opts

exports.Parser = Parser = class Parser
  parse: (code, opts = {}) ->
    @ast = astBranchNode ROOT # abstract syntax tree
    @activeStates = [@ast] # stack tracking current ast position (initialised with root node)
    @chunkLine = 0 # The start line for the current @chunk.
    @chunkColumn =  0 # The start column of the current @chunk.
    code = @clean code # The stripped, cleaned original source code.

    i = 0
    while @chunk = code[i..]
      consumed = \
        @csxStart() or
        @csxEscape() or
        @csxUnescape() or
        @csxEnd() or
        @csxText() or
        @coffeescriptCode()

      # Update position
      [@chunkLine, @chunkColumn] = @getLineAndColumnFromChunk consumed

      i += consumed
    
    unless @activeBranchNode() == @ast
      throwSyntaxError \
        "Unexpected EOF: unclosed #{@activeBranchNode().type}",
        first_line: @chunkLine, first_column: @chunkColumn

    @ast # return completed ast

  # lex/parse states

  csxStart: ->
    return 0 unless match = OPENING_TAG.exec @chunk
    [input, tagName, attributesText, unneededJunk, selfClosing] = match

    @pushActiveBranchNode astBranchNode CSX_EL, tagName
    @addLeafNodeToActiveBranch @rewriteAttributes attributesText

    # console.log CSX_START

    if selfClosing
      @popActiveBranchNode() # close csx tag
      # console.log CSX_END

    input.length

  csxEscape: ->
    return 0 unless @activeBranchNode().type == CSX_EL and @chunk.charAt(0) == '{'

    @pushActiveBranchNode astBranchNode CSX_ESC
    # console.log CSX_ESC_START
    return 1

  csxUnescape: ->
    return 0 unless @activeBranchNode().type == CSX_ESC and @chunk.charAt(0) == '}'
    
    @popActiveBranchNode() # close csx escape
    # console.log CSX_ESC_END
    return 1

  csxEnd: ->
    return 0 unless @activeBranchNode().type == CSX_EL
    return 0 unless match = CLOSING_TAG.exec @chunk
    [input, tagName] = match

    unless tagName == @activeBranchNode().value
      throwSyntaxError \
        "CSX_START tag #{@activeBranchNode().value} doesn't match CSX_END tag #{tagName}",
        first_line: @chunkLine, first_column: @chunkColumn

    @popActiveBranchNode() # close csx tag
    # console.log CSX_END

    input.length

  csxText: ->
    return 0 unless @activeBranchNode().type == CSX_EL

    unless @newestNode().type == CSX_TEXT
      @addLeafNodeToActiveBranch astLeafNode CSX_TEXT, '' # init value as string

    # newestNode is (now) CSX_TEXT
    @newestNode().value += @chunk.charAt 0

    return 1

  # fallthrough
  coffeescriptCode: ->
    # return 0 unless @activeBranchNode().type == ROOT or @activeBranchNode().type == CSX_ESC
    
    unless @newestNode().type == CS
      @addLeafNodeToActiveBranch astLeafNode CS, '' # init value as string

    # newestNode is (now) CS
    @newestNode().value += @chunk.charAt 0
    
    return 1

  # ast helpers

  activeBranchNode: -> last(@activeStates)

  newestNode: -> last(@activeBranchNode().children) or @activeBranchNode()

  pushActiveBranchNode: (node) ->
    @activeBranchNode().children.push(node)
    @activeStates.push(node)

  popActiveBranchNode: -> @activeStates.pop()

  addLeafNodeToActiveBranch: (node) ->
    @activeBranchNode().children.push(node)

  # TODO: implement attributes
  rewriteAttributes: (attributesText) ->
    astBranchNode CSX_ATTRIBUTES, null, do ->
      while attrMatches = TAG_ATTRIBUTES.exec attributesText
        unless attrMatches[1] # has attribute
          throwSyntaxError \
            "Invalid attribute #{attrMatches[0]} in #{attributesText}",
            first_line: @chunkLine, first_column: @chunkColumn

        if attrMatches[2] # "value"
          astBranchNode(CSX_ATTR_PAIR, null, [
            astLeafNode(CSX_ATTR_KEY, "\"#{attrMatches[1]}\"")
            astLeafNode(CSX_ATTR_VAL, "\"#{attrMatches[2]}\"")
          ])
        else if attrMatches[3] # 'value'
          astBranchNode(CSX_ATTR_PAIR, null, [
            astLeafNode(CSX_ATTR_KEY, "\"#{attrMatches[1]}\"")
            astLeafNode(CSX_ATTR_VAL, "'#{attrMatches[3]}'")
          ])
        else if attrMatches[4] # {value}
          astBranchNode(CSX_ATTR_PAIR, null, [
            astLeafNode(CSX_ATTR_KEY, "\"#{attrMatches[1]}\"")
            astBranchNode(CSX_ESC, null, [astLeafNode(CS, attrMatches[4])])
          ])
        else if attrMatches[5] # value
          astBranchNode(CSX_ATTR_PAIR, null, [
            astLeafNode(CSX_ATTR_KEY, "\"#{attrMatches[1]}\"")
            astLeafNode(CSX_ATTR_VAL, "\"#{attrMatches[5]}\"")
          ])
        else
          astBranchNode(CSX_ATTR_PAIR, null, [
            astLeafNode(CSX_ATTR_KEY, "\"#{attrMatches[1]}\"")
            astLeafNode(CSX_ATTR_VAL, 'true')
          ])

  # helpers (from cs lexer)
  
  # Preprocess the code to remove leading and trailing whitespace, carriage
  # returns, etc.
  clean: (code) ->
    code = code.slice(1) if code.charCodeAt(0) is BOM
    code = code.replace(/\r/g, '').replace TRAILING_SPACES, ''
    if WHITESPACE.test code
      code = "\n#{code}"
      @chunkLine--
    code

  # Returns the line and column number from an offset into the current chunk.
  #
  # `offset` is a number of characters into @chunk.
  getLineAndColumnFromChunk: (offset) ->
    if offset is 0
      return [@chunkLine, @chunkColumn]

    if offset >= @chunk.length
      string = @chunk
    else
      string = @chunk[..offset-1]

    lineCount = count string, '\n'

    column = @chunkColumn
    if lineCount > 0
      lines = string.split '\n'
      column = last(lines).length
    else
      column += string.length

    [@chunkLine + lineCount, column]


exports.serialise = serialise = (ast) ->
  serialiseNode = (node) -> serialisers[node.type](node)

  genericBranchSerialiser = (node) ->
    node.children
      .map((child) -> serialiseNode child)
      .join('')

  genericLeafSerialiser = (node) -> node.value

  serialisers =
    ROOT: genericBranchSerialiser
    CSX_EL: (node) ->
      childrenSerialised = node.children
        .map((child) -> serialiseNode child)
        .filter((child) -> child?) # filter empty text nodes
        .join(', ')
      "#{node.value}(#{childrenSerialised})"
    CSX_ESC: (node) ->
      childrenSerialised = node.children
        .map((child) -> serialiseNode child)
        .join('')
      "(#{childrenSerialised})"
    # not implemented yet
    CSX_ATTRIBUTES: (node) ->
      if node.children.length
        childrenSerialised = node.children
          .map((child) -> serialiseNode child)
          .join(', ')
        "{#{childrenSerialised}}"
      else
        "null"
    CSX_ATTR_PAIR: (node) ->
      node.children
        .map((child) -> serialiseNode child)
        .join(': ')
    # leaf nodes
    CS: genericLeafSerialiser
    CSX_TEXT: (node) ->
      # current react behaviour is to trim whitespace from text nodes
      trimmedValue = node.value.trim()
      if trimmedValue == ''
        # empty/whitespace-only nodes return null so they can be filtered out
        null
      else
        "'''#{trimmedValue}'''"
    CSX_ATTR_KEY: genericLeafSerialiser
    CSX_ATTR_VAL: genericLeafSerialiser

  serialiseNode(ast)


# Constants
# ---------

# branch (state) node types
ROOT = 'ROOT'
CSX_EL = 'CSX_EL'
CSX_ESC = 'CSX_ESC'
CSX_ATTRIBUTES = 'CSX_ATTRIBUTES'
CSX_ATTR_PAIR = 'CSX_ATTR_PAIR'

# leaf (value) node types
CS = 'CS'
CSX_TEXT = 'CSX_TEXT'
CSX_ATTR_KEY = 'CSX_ATTR_KEY'
CSX_ATTR_VAL = 'CSX_ATTR_VAL'

# tokens
# these aren't really used as there aren't distinct lex/parse steps
# they're just names for use in debugging
CSX_START = 'CSX_START'
CSX_END = 'CSX_END'
CSX_ESC_START = 'CSX_ESC_START'
CSX_ESC_END = 'CSX_ESC_END'

# JSX tag matching regexes

# [1] tag name
# [2] attributes text
# [3] 
# [4] self closing?
OPENING_TAG = /^<([-A-Za-z0-9_]+)((?:\s+[\w-]+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|(?:{(.|\n)*?})|[^>\s]+))?)*)\s*(\/?)>/

# [1] tag name
CLOSING_TAG = /^<\/([-A-Za-z0-9_]+)[^>]*>/

# [0] attr=val
# [1] attr
# [2] "val" double quoted
# [3] 'val' single quoted
# [4] {val} {cs escaped}
# [5] val bare
# exec multiple times until null
TAG_ATTRIBUTES = /([-A-Za-z0-9_]+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')|(?:{((?:\\.|[^}])*)})|([^>\s]+)))?/g


# from coffeescript lexer

# The character code of the nasty Microsoft madness otherwise known as the BOM.
BOM = 65279

WHITESPACE = /^[^\n\S]+/

COMMENT    = /^###([^#][\s\S]*?)(?:###[^\n\S]*|###$)|^(?:\s*#(?!##[^#]).*)+/

# Token cleaning regexes.
TRAILING_SPACES = /\s+$/


