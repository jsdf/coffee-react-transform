
# Import the helpers we need.
{count, starts, compact, last, repeat,
locationDataToString,  throwSyntaxError} = require './helpers'

$ = require './symbols'

# parse tree node builders
parseTreeLeafNode = (type, value = null) -> {type, value}
parseTreeBranchNode = (type, value = null, children = []) -> {type, value, children}

module.exports = class Parser
  parse: (code, @opts = {}) ->
    @parseTree = parseTreeBranchNode @opts.root or $.ROOT # concrete syntax tree (initialised with root node)
    @activeStates = [@parseTree] # stack tracking current parse tree position (starting with root)
    @chunkLine = 0 # The start line for the current @chunk.
    @chunkColumn =  0 # The start column of the current @chunk.
    @cjsxPragmaChecked = false
    code = @clean code # The stripped, cleaned original source code.

    i = 0
    while (@chunk = code[i..])
      break if @activeStates.length is 0
      consumed = (
          if @activeBranchNode().type isnt $.CJSX_EL
            @csComment() or
            @csHeredoc() or
            @csString() or
            @csRegex() or
            @jsEscaped()
        ) or
        @cjsxStart() or
        @cjsxEscape() or
        @cjsxUnescape() or
        @cjsxEnd() or
        @cjsxText() or
        @coffeescriptCode()

      # Update position
      [@chunkLine, @chunkColumn] = @getLineAndColumnFromChunk consumed

      i += consumed

    if @activeBranchNode()? and @activeBranchNode() isnt @parseTree
      message = "Unexpected end of input: unclosed #{@activeBranchNode().type}"
      throwSyntaxError message, first_line: @chunkLine, first_column: @chunkColumn

    @remainder = code[i..]

    unless @opts.recursive
      if @remainder.length
        throwSyntaxError \
          "Unexpected return from root state",
          first_line: @chunkLine, first_column: @chunkColumn

    @parseTree # return completed parseTree

  # lex/parse states
  
  # Matches and consumes comments.
  csComment: ->
    return 0 unless match = @chunk.match COMMENT
    [comment, here] = match

    unless @cjsxPragmaChecked
      @cjsxPragmaChecked = true
      if pragmaMatch = comment.match PRAGMA
        if pragmaMatch and pragmaMatch[1] and pragmaMatch[1].length
          prefix = pragmaMatch[1]
        else
          prefix = 'React.DOM'
        @addLeafNodeToActiveBranch parseTreeLeafNode $.CJSX_PRAGMA, prefix
        return comment.length

    @addLeafNodeToActiveBranch parseTreeLeafNode $.CS_COMMENT, comment
    comment.length

  # Matches heredocs
  csHeredoc: ->
    return 0 unless match = HEREDOC.exec @chunk
    heredoc = match[0]

    @addLeafNodeToActiveBranch parseTreeLeafNode $.CS_HEREDOC, heredoc

    heredoc.length

  # Matches strings, including multi-line strings. Ensures that quotation marks
  # are balanced within the string's contents, and within nested interpolations.
  csString: ->
    switch quote = @chunk.charAt 0
      when "'" then [string] = SIMPLESTR.exec @chunk
      when '"' then string = @balancedString @chunk, '"'
    return 0 unless string

    @addLeafNodeToActiveBranch parseTreeLeafNode $.CS_STRING, string

    string.length


  csRegex: ->
    return 0 if @chunk.charAt(0) isnt '/'
    return length if length = @csHeregex()

    # clever js regex heuristics should go here...
    # except as we haven't actually parsed most of the code,
    # we can't look at tokens to figure out if this is actually division
    # maybe search backward and do a hacky sort of mini parse?

    return 0 unless match = REGEX.exec @chunk
    [match, regex, flags] = match
    return 0 if regex.indexOf("\n") > -1 # no newlines in a normal regex
    # Avoid conflicts with floor division operator.
    return 0 if regex is '//'
    @addLeafNodeToActiveBranch parseTreeLeafNode $.CS_REGEX, match
    match.length

  # Matches multiline extended regular expressions.
  csHeregex: ->
    return 0 unless match = HEREGEX.exec @chunk
    [heregex, body, flags] = match

    @addLeafNodeToActiveBranch parseTreeLeafNode $.CS_HEREGEX, heregex

    heregex.length

  # Matches JavaScript interpolated directly into the source via backticks.
  jsEscaped: ->
    return 0 unless @chunk.charAt(0) is '`' and match = JSTOKEN.exec @chunk
    script = match[0]

    @addLeafNodeToActiveBranch parseTreeLeafNode $.JS_ESC, script

    script.length

  cjsxStart: ->
    return 0 unless match = OPENING_TAG.exec @chunk
    [input, tagName, attributesText, selfClosing] = match

    return 0 unless selfClosing or @chunk.indexOf("</#{tagName}>", input.length) > -1

    @pushActiveBranchNode parseTreeBranchNode $.CJSX_EL, tagName
    @addLeafNodeToActiveBranch @cjsxAttributesParse attributesText

    if selfClosing
      @popActiveBranchNode() # close cjsx tag

    input.length

  cjsxEscape: ->
    return 0 unless @activeBranchNode().type is $.CJSX_EL and @chunk.charAt(0) is '{'

    @pushActiveBranchNode parseTreeBranchNode $.CJSX_ESC
    return 1

  cjsxUnescape: ->
    return 0 if @opts.contained
    return 0 unless @activeBranchNode().type is $.CJSX_ESC and @chunk.charAt(0) is '}'

    @popActiveBranchNode() # close cjsx escape
    return 1

  cjsxEnd: ->
    return 0 unless @activeBranchNode().type is $.CJSX_EL
    return 0 unless match = CLOSING_TAG.exec @chunk
    [input, tagName] = match

    unless tagName is @activeBranchNode().value
      throwSyntaxError \
        "opening CJSX tag #{@activeBranchNode().value} doesn't match closing CJSX tag #{tagName}",
        first_line: @chunkLine, first_column: @chunkColumn

    @popActiveBranchNode() # close cjsx tag

    input.length

  cjsxText: ->
    return 0 unless @activeBranchNode().type is $.CJSX_EL

    unless @newestNode().type is $.CJSX_TEXT
      @addLeafNodeToActiveBranch parseTreeLeafNode $.CJSX_TEXT, '' # init value as string

    # newestNode is (now) $.CJSX_TEXT
    @newestNode().value += @chunk.charAt 0

    return 1

  # fallthrough
  coffeescriptCode: ->
    # return 0 unless @activeBranchNode().type is $.ROOT or @activeBranchNode().type is $.CJSX_ESC
    
    unless @newestNode().type is $.CS
      @addLeafNodeToActiveBranch parseTreeLeafNode $.CS, '' # init value as string

    # newestNode is (now) $.CS
    @newestNode().value += @chunk.charAt 0
    
    return 1

  # parseTree helpers

  activeBranchNode: -> last(@activeStates)

  newestNode: -> last(@activeBranchNode().children) or @activeBranchNode()

  pushActiveBranchNode: (node) ->
    @activeBranchNode().children.push(node)
    @activeStates.push(node)

  popActiveBranchNode: -> @activeStates.pop()

  addLeafNodeToActiveBranch: (node) ->
    @activeBranchNode().children.push(node)

  cjsxEscAttrNodeRecursiveParse: (attrName, cjsxEscInput) ->
    parser = new Parser()

    # parse input fragment starting in 'CJSX_ESC' state 
    cjsxEscParseSubtree = parser.parse(cjsxEscInput, {
      root: $.CJSX_ESC
      recursive: true
      contained: cjsxEscInput.indexOf('{') is 0 and cjsxEscInput.indexOf('}') > -1
    })

    if parser.remainder.length
      # i know this seems pretty weird but just go with it
      remainderAttrTree = @cjsxAttributesParse(parser.remainder+'}')
      remainderAttrs = remainderAttrTree.children

    [
      parseTreeBranchNode($.CJSX_ATTR_PAIR, null, [
        parseTreeLeafNode($.CJSX_ATTR_KEY, "\"#{attrName}\"")
        cjsxEscParseSubtree
      ])
    ].concat (remainderAttrs or [])

  # this is probably the worst, most unfortunate part of this codebase
  # attributes should really be parsed as part of the main parse loop
  cjsxAttributesParse: (attributesText) ->
    self = @
    parseTreeBranchNode $.CJSX_ATTRIBUTES, null, do ->
      attrNodes = []
      tagAttrMatcher = tagAttrRegex()
      while attrMatches = tagAttrMatcher.exec attributesText
        [ attrNameValText, attrName, doubleQuotedVal,
          singleQuotedVal, cjsxEscVal, bareVal, whitespace ] = attrMatches
        nextAttrNodes = if attrName
          if doubleQuotedVal # "value"
            parseTreeBranchNode($.CJSX_ATTR_PAIR, null, [
              parseTreeLeafNode($.CJSX_ATTR_KEY, "\"#{attrName}\"")
              parseTreeLeafNode($.CJSX_ATTR_VAL, "\"#{doubleQuotedVal}\"")
            ])
          else if singleQuotedVal # 'value'
            parseTreeBranchNode($.CJSX_ATTR_PAIR, null, [
              parseTreeLeafNode($.CJSX_ATTR_KEY, "\"#{attrName}\"")
              parseTreeLeafNode($.CJSX_ATTR_VAL, "'#{singleQuotedVal}'")
            ])
          else if cjsxEscVal # {value}
            self.cjsxEscAttrNodeRecursiveParse(attrName, cjsxEscVal)
          else if bareVal # value
            parseTreeBranchNode($.CJSX_ATTR_PAIR, null, [
              parseTreeLeafNode($.CJSX_ATTR_KEY, "\"#{attrName}\"")
              parseTreeLeafNode($.CJSX_ATTR_VAL, bareVal)
            ])
          else
            parseTreeBranchNode($.CJSX_ATTR_PAIR, null, [
              parseTreeLeafNode($.CJSX_ATTR_KEY, "\"#{attrName}\"")
              parseTreeLeafNode($.CJSX_ATTR_VAL, 'true')
            ])
        else if whitespace
          parseTreeLeafNode($.CJSX_WHITESPACE, whitespace)
        else
          throwSyntaxError \
            "Invalid attribute #{attrNameValText} in #{attributesText}",
            first_line: @chunkLine, first_column: @chunkColumn
        attrNodes = attrNodes.concat nextAttrNodes
      attrNodes

  # helpers (from cs lexer)
  
  # Preprocess the code to remove leading and trailing whitespace, carriage
  # returns, etc.
  clean: (code) ->
    code = code.slice(1) if code.charCodeAt(0) is BOM
    # code = code.replace(/\r/g, '').replace TRAILING_SPACES, ''
    # if WHITESPACE.test code
    #   code = "\n#{code}"
    #   @chunkLine--
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

  # Matches a balanced group such as a single or double-quoted string. Pass in
  # a series of delimiters, all of which must be nested correctly within the
  # contents of the string. This method allows us to have strings within
  # interpolations within strings, ad infinitum.
  balancedString: (str, end) ->
    continueCount = 0
    stack = [end]
    for i in [1...str.length]
      if continueCount
        --continueCount
        continue
      switch letter = str.charAt i
        when '\\'
          ++continueCount
          continue
        when end
          stack.pop()
          unless stack.length
            return str[0..i]
          end = stack[stack.length - 1]
          continue
      if end is '}' and letter in ['"', "'"]
        stack.push end = letter
      else if end is '}' and letter is '/' and match = (HEREGEX.exec(str[i..]) or REGEX.exec(str[i..]))
        continueCount += match[0].length - 1
      else if end is '}' and letter is '{'
        stack.push end = '}'
      else if end is '"' and prev is '#' and letter is '{'
        stack.push end = '}'
      prev = letter
    @error "missing #{ stack.pop() }, starting"


# JSX tag matching regexes

# [1] tag name
# [2] attributes text
# [3] self closing?
OPENING_TAG = /^<([-A-Za-z0-9_]+)((?:\s+[\w-]+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|(?:{[\s\S]*?})|[^>\s]+))?)*?\s*)(\/?)>/

# [1] tag name
CLOSING_TAG = /^<\/([-A-Za-z0-9_]+)[^>]*>/

tagAttrRegex = ->
  # [0] attr=val
  # [1] attr
  # [2] "val" double quoted
  # [3] 'val' single quoted
  # [4] {val} {cs escaped}
  # [5] val bare
  # [6] whitespace
  TAG_ATTRIBUTES = /(?:([-A-Za-z0-9_]+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')|(?:{((?:\\.|[\s\S])*)})|([^>\s]+)))?)|([\s\n]+)/g

PRAGMA = /^\s*#\s*@cjsx\s+(\S*)/i

# from coffeescript lexer

# The character code of the nasty Microsoft madness otherwise known as the BOM.
BOM = 65279

WHITESPACE = /^[^\n\S]+/

COMMENT    = /^###([^#][\s\S]*?)(?:###[^\n\S]*|###$)|^(?:\s*#(?!##[^#]).*)+/

# Token cleaning regexes.
TRAILING_SPACES = /\s+$/

HEREDOC    = /// ^ ("""|''') ((?: \\[\s\S] | [^\\] )*?) (?:\n[^\n\S]*)? \1 ///

SIMPLESTR  = /^'[^\\']*(?:\\[\s\S][^\\']*)*'/

JSTOKEN    = /^`[^\\`]*(?:\\.[^\\`]*)*`/

# Regex-matching-regexes.
REGEX = /// ^
  (/ (?! [\s=] )   # disallow leading whitespace or equals signs
  [^ [ / \n \\ ]*  # every other thing
  (?:
    (?: \\[\s\S]   # anything escaped
      | \[         # character class
           [^ \] \n \\ ]*
           (?: \\[\s\S] [^ \] \n \\ ]* )*
         ]
    ) [^ [ / \n \\ ]*
  )*
  /) ([imgy]{0,4}) (?!\w)
///

HEREGEX      = /// ^ /{3} ((?:\\?[\s\S])+?) /{3} ([imgy]{0,4}) (?!\w) ///

