
# Import the helpers we need.
{count, starts, compact, last, repeat, invertLiterate,
locationDataToString,  throwSyntaxError} = require './helpers'


# nextTag = (remainingText) ->
#   remainingText.match OPENING_TAG
#   remainingText.match CLOSING_TAG

# getAttributes = (attributesText) ->
#   attributesValues = {}
#   TAG_ATTRIBUTES.lastIndex = 0
#   while attrMatches = TAG_ATTRIBUTES.exec attributesText
#     attributesValues[attrMatches[1]] = attrMatches[2] || attrMatches[4] || true
#   attributesValues

# transformTag = (tagName,attributesText,selfClosing) ->
#   transformedTokens = []
#   attributes = getAttributes(attributesText)
#   unless selfClosing
#     nextTag()



exports.Rewriter = class Rewriter
 rewrite: (code, opts = {}) ->
    @activeStates = [] # stack for states
    @output = [] # buffer for rewritten fragments
    @previousState = null # last state encountered
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

  csxStart: ->
    return 0 unless match = OPENING_TAG.exec @chunk
    [input, tagName, attributesText, selfClosing] = match
    @output.push tagName, '(', rewriteAttributes(attributesText)

    if selfClosing
      @output.push ')'
    else
      @activeStates.push CSX_START

    input.length

  csxEscape: ->
    return 0 unless last(@activeStates) == CSX_START and @chunk.charAt(0) == '{'

    # do we need a comma? TODO REPLACE WITH STATES AST
    if @previousState == CSX_TEXT
    @previousState == CSX_START or
    @previousState == CSX_END or
    @previousState == CSX_ESC_END
      @output.push ','

    @activeStates.push CSX_ESC_START
    @previousState = CSX_ESC_START
    return 1

  csxUnescape: ->
    return 0 unless last(@activeStates) == CSX_ESC_START and @chunk.charAt(0) == '}'
    @activeStates.pop()
    @previousState = CSX_ESC_START
    return 1

  csxEnd: ->
    return 0 unless last(@activeStates) == CSX_START
    return 0 unless match = CLOSING_TAG.exec @chunk
    [input, tagName] = match

    @output.push ')'

    @activeStates.pop()
    @previousState = CSX_END
    input.length

  csxText: ->
    return 0 unless last(@activeStates) == CSX_START

    # do we need a comma? TODO REPLACE WITH STATES AST
    unless @previousState == CSX_TEXT
      if @previousState == CSX_START or
      @previousState == CSX_END or
      @previousState == CSX_ESC_END
        @output.push ','

    @output.push @chunk.charAt 0
    @previousState = CSX_TEXT
    return 1

  coffeescriptCode: ->
    # return 0 unless @activeStates.length == 0 or last(@activeStates) == CSX_ESC_START
    @output.push @chunk.charAt 0
    @previousState = COFFEESCRIPT_CODE
    return 1

  rewriteAttributes: (attributesText) ->

  clean: (code) ->
    code = code.slice(1) if code.charCodeAt(0) is BOM
    code = code.replace(/\r/g, '').replace TRAILING_SPACES, ''
    if WHITESPACE.test code
      code = "\n#{code}"
      @chunkLine--
    code

  # Helpers
  # -------

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

# Constants
# ---------

COFFEESCRIPT_CODE = {}
CSX_START = {}
CSX_END = {}
CSX_ESC_START = {}
CSX_ESC_END = {}
CSX_TEXT = {}


# [1] tag name
# [2] attributes text
# [3] self closing?
OPENING_TAG = /^<([-A-Za-z0-9_]+)((?:\s+\w+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>/

# [1] tag name
CLOSING_TAG = /^<\/([-A-Za-z0-9_]+)[^>]*>/

# exec (call until null)
# [0] attr=val
# [1] attr
# [2] val if quoted
# [3] 
# [4] val if not quoted
TAG_ATTRIBUTES = /^([-A-Za-z0-9_]+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')|([^>\s]+)))?/g


# from coffeescript lexer

# The character code of the nasty Microsoft madness otherwise known as the BOM.
BOM = 65279

WHITESPACE = /^[^\n\S]+/

COMMENT    = /^###([^#][\s\S]*?)(?:###[^\n\S]*|###$)|^(?:\s*#(?!##[^#]).*)+/

# Token cleaning regexes.
TRAILING_SPACES = /\s+$/

