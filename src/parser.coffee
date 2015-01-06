
# Import the helpers we need.
{count, starts, compact, last, repeat, throwSyntaxError} = require './helpers'

$ = require './symbols'

# parse tree node factories
ParseTreeLeafNode = (type, value = null) -> {type, value}
ParseTreeBranchNode = (type, value = null, children = []) -> {type, value, children}

module.exports = class Parser
  parse: (code, @opts = {}) ->
    @parseTree = ParseTreeBranchNode @opts.root or $.ROOT # concrete syntax tree (initialised with root node)
    @activeStates = [@parseTree] # stack tracking current parse tree position (starting with root)
    @chunkLine = 0 # The start line for the current @chunk.
    @chunkColumn =  0 # The start column of the current @chunk.
    @cjsxPragmaChecked = false
    code = @clean code # The stripped, cleaned original source code.

    i = 0
    while (@chunk = code[i..])
      break if @activeStates.length is 0
      consumed = \
        (
          if @currentState() not in [$.CJSX_EL, $.CJSX_ATTRIBUTES]
            @csComment() or
            @csHeredoc() or
            @csString() or
            @csRegex() or
            @jsEscaped()
        ) or
        @cjsxStart() or
        @cjsxAttribute() or
        @cjsxEscape() or
        @cjsxUnescape() or
        @cjsxEnd() or
        @cjsxText() or
        @coffeescriptCode()

      # Update position
      [@chunkLine, @chunkColumn] = @getLineAndColumnFromChunk consumed

      i += consumed

    if @activeBranchNode()? and @activeBranchNode() isnt @parseTree
      message = "Unexpected end of input: unclosed #{@currentState()}"
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
        @addLeafNodeToActiveBranch ParseTreeLeafNode $.CJSX_PRAGMA, prefix
        return comment.length

    @addLeafNodeToActiveBranch ParseTreeLeafNode $.CS_COMMENT, comment
    comment.length

  # Matches heredocs
  csHeredoc: ->
    return 0 unless match = HEREDOC.exec @chunk
    heredoc = match[0]

    @addLeafNodeToActiveBranch ParseTreeLeafNode $.CS_HEREDOC, heredoc

    heredoc.length

  # Matches strings, including multi-line strings. Ensures that quotation marks
  # are balanced within the string's contents, and within nested interpolations.
  csString: ->
    switch quote = @chunk.charAt 0
      when "'" then [string] = SIMPLESTR.exec @chunk
      when '"' then string = @balancedString @chunk, '"'
    return 0 unless string

    @addLeafNodeToActiveBranch ParseTreeLeafNode $.CS_STRING, string

    string.length

  csRegex: ->
    return 0 if @chunk.charAt(0) isnt '/'
    return length if length = @csHeregex()

    # clever js regex heuristics should go here...
    # except as we haven't actually parsed most of the code,
    # we can't look at tokens to figure out if this is actually division.
    # maybe this will be doable if we parse the code sections for
    # symbols and whitespace at least

    return 0 unless match = REGEX.exec @chunk
    [match, regex, flags] = match
    return 0 if regex.indexOf("\n") > -1 # no newlines in a normal regex
    # Avoid conflicts with floor division operator.
    return 0 if regex is '//'
    @addLeafNodeToActiveBranch ParseTreeLeafNode $.CS_REGEX, match
    match.length

  # Matches multiline extended regular expressions.
  csHeregex: ->
    return 0 unless match = HEREGEX.exec @chunk
    [heregex, body, flags] = match

    @addLeafNodeToActiveBranch ParseTreeLeafNode $.CS_HEREGEX, heregex

    heregex.length

  # Matches JavaScript interpolated directly into the source via backticks.
  jsEscaped: ->
    return 0 unless @chunk.charAt(0) is '`' and match = JSTOKEN.exec @chunk
    script = match[0]

    @addLeafNodeToActiveBranch ParseTreeLeafNode $.JS_ESC, script

    script.length

  cjsxStart: ->
    return 0 unless match = OPENING_TAG.exec @chunk
    [input, tagName, attributesText, selfClosing] = match

    return 0 unless selfClosing or @chunk.indexOf("</#{tagName}>", input.length) > -1

    @pushActiveBranchNode ParseTreeBranchNode $.CJSX_EL, tagName
    @pushActiveBranchNode ParseTreeBranchNode $.CJSX_ATTRIBUTES

    1+tagName.length

  cjsxAttribute: ->
    return 0 unless @currentState() is $.CJSX_ATTRIBUTES

    if @chunk.charAt(0) is '/'
      if @chunk.charAt(1) is '>'
        @popActiveBranchNode() # end attributes
        @popActiveBranchNode() # end cjsx
        return 2
      else
        throwSyntaxError \
          "/ without immediately following > in CJSX tag #{@peekActiveState(2).value}",
          first_line: @chunkLine, first_column: @chunkColumn

    if @chunk.charAt(0) is '>'
      @popActiveBranchNode() # end attributes
      return 1

    return 0 unless match = TAG_ATTRIBUTES.exec @chunk
    [ input, attrName, doubleQuotedVal,
      singleQuotedVal, cjsxEscVal, bareVal, 
      spreadAttr, whitespace ] = match

    if attrName
      if doubleQuotedVal? # "value"
        @addLeafNodeToActiveBranch ParseTreeBranchNode($.CJSX_ATTR_PAIR, null, [
          ParseTreeLeafNode($.CJSX_ATTR_KEY, "\"#{attrName}\"")
          ParseTreeLeafNode($.CJSX_ATTR_VAL, "\"#{doubleQuotedVal}\"")
        ])
        return input.length
      else if singleQuotedVal? # 'value'
        @addLeafNodeToActiveBranch ParseTreeBranchNode($.CJSX_ATTR_PAIR, null, [
          ParseTreeLeafNode($.CJSX_ATTR_KEY, "\"#{attrName}\"")
          ParseTreeLeafNode($.CJSX_ATTR_VAL, "'#{singleQuotedVal}'")
        ])
        return input.length
      else if cjsxEscVal # {value}
        @pushActiveBranchNode ParseTreeBranchNode $.CJSX_ATTR_PAIR
        @addLeafNodeToActiveBranch ParseTreeLeafNode($.CJSX_ATTR_KEY, "\"#{attrName}\"")
        # on next iteration of parse loop, '{' will trigger CJSX_ESC state
        return input.indexOf('{') # consume up to start of cjsx escape
      else if bareVal # value
        @addLeafNodeToActiveBranch ParseTreeBranchNode($.CJSX_ATTR_PAIR, null, [
          ParseTreeLeafNode($.CJSX_ATTR_KEY, "\"#{attrName}\"")
          ParseTreeLeafNode($.CJSX_ATTR_VAL, bareVal)
        ])
        return input.length
      else # valueless attr
        @addLeafNodeToActiveBranch ParseTreeBranchNode($.CJSX_ATTR_PAIR, null, [
          ParseTreeLeafNode($.CJSX_ATTR_KEY, "\"#{attrName}\"")
          ParseTreeLeafNode($.CJSX_ATTR_VAL, 'true')
        ])
        return input.length
    else if spreadAttr # {...x}
      @addLeafNodeToActiveBranch ParseTreeLeafNode($.CJSX_ATTR_SPREAD, spreadAttr)
      return input.length
    else if whitespace?
      @addLeafNodeToActiveBranch ParseTreeLeafNode($.CJSX_WHITESPACE, whitespace)
      return input.length
    else
      throwSyntaxError \
        "Invalid attribute #{input} in CJSX tag #{@peekActiveState(2).value}",
        first_line: @chunkLine, first_column: @chunkColumn

  cjsxEscape: ->
    return 0 unless @chunk.charAt(0) is '{' and
    @currentState() in [$.CJSX_EL, $.CJSX_ATTR_PAIR]

    @pushActiveBranchNode ParseTreeBranchNode $.CJSX_ESC
    @activeBranchNode().stack = 1 # keep track of opening and closing braces
    return 1

  cjsxUnescape: ->
    return 0 unless @currentState() is $.CJSX_ESC and @chunk.charAt(0) is '}'

    if @activeBranchNode().stack is 0
      @popActiveBranchNode() # close cjsx escape
      if @currentState() in [$.CJSX_ATTR_PAIR]
        @popActiveBranchNode() # close cjsx escape attr pair
      return 1
    else
      return 0

  cjsxEnd: ->
    return 0 unless @currentState() is $.CJSX_EL
    return 0 unless match = CLOSING_TAG.exec @chunk
    [input, tagName] = match

    unless tagName is @activeBranchNode().value
      throwSyntaxError \
        "opening CJSX tag #{@activeBranchNode().value} doesn't match closing CJSX tag #{tagName}",
        first_line: @chunkLine, first_column: @chunkColumn

    @popActiveBranchNode() # close cjsx tag

    input.length

  cjsxText: ->
    return 0 unless @currentState() is $.CJSX_EL

    unless @newestNode().type is $.CJSX_TEXT
      @addLeafNodeToActiveBranch ParseTreeLeafNode $.CJSX_TEXT, '' # init value as string

    # newestNode is (now) $.CJSX_TEXT
    @newestNode().value += @chunk.charAt 0

    return 1

  # fallthrough
  coffeescriptCode: ->
    # return 0 unless @currentState() is $.ROOT or @currentState() is $.CJSX_ESC
    
    if @currentState() is $.CJSX_ESC
      if @chunk.charAt(0) is '{'
        @activeBranchNode().stack++
      else if @chunk.charAt(0) is '}'
        @activeBranchNode().stack--
        if @activeBranchNode().stack is 0
          return 0
    
    unless @newestNode().type is $.CS
      @addLeafNodeToActiveBranch ParseTreeLeafNode $.CS, '' # init value as string

    # newestNode is (now) $.CS
    @newestNode().value += @chunk.charAt 0
    
    return 1

  # parseTree helpers

  activeBranchNode: -> last(@activeStates)

  peekActiveState: (depth = 1) -> @activeStates[-depth..][0]

  currentState: -> @activeBranchNode().type

  newestNode: -> last(@activeBranchNode().children) or @activeBranchNode()

  pushActiveBranchNode: (node) ->
    @activeBranchNode().children.push(node)
    @activeStates.push(node)

  popActiveBranchNode: -> @activeStates.pop()

  addLeafNodeToActiveBranch: (node) ->
    @activeBranchNode().children.push(node)

  # helpers (from cs lexer)
  
  # Preprocess the code to remove leading and trailing whitespace, carriage
  # returns, etc.
  clean: (code) ->
    code = code.slice(1) if code.charCodeAt(0) is BOM
    code = code.replace(/\r/g, '') # strip carriage return chars
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
OPENING_TAG = /// ^
  <
    (@?[-A-Za-z0-9_\.]+) # tag name (captured)
    (
      (?:
        (?:
            (?:\s+[\w-]+ # attr name
              (?:\s*=\s* # equals and whitespace
                (?:
                    (?:"[^"]*") # double quoted value
                  | (?:'[^']*') # single quoted value
                  | (?:{[\s\S]*?}) # cjsx escaped expression
                  | [^>\s]+ # bare value
                ) 
              )
            )
          | \s+[\w-]+  # bare attribute 
          | \s+\{\.\.\.\s*?[^\s{}]+?\s*?\}  # spread attribute
        )?
      )*?
      \s* # whitespace after attr pair
    ) # attributes text (captured)
    (\/?) # self closing? (captured)
  >
///

# [1] tag name
CLOSING_TAG = /^<\/(@?[-A-Za-z0-9_\.]+)[^>]*>/

# [0] attr=val
# [1] attr
# [2] "val" double quoted
# [3] 'val' single quoted
# [4] {val} {cs escaped}
# [5] val bare
# [6] whitespace
TAG_ATTRIBUTES = ///
  (?:
    ([-A-Za-z0-9_]+) # attr name (captured)
    (?:
      \s*=\s* # equals and whitespace
      (?:
          (?: " ( (?: \\. | [^"] )* ) " ) # double quoted value (captured)
        | (?: ' ( (?: \\. | [^'] )* ) ' ) # single quoted value (captured)
        | (?: { ( (?: \\. | [\s\S] )* ) } ) # cjsx escaped expression (captured)
        | ( [^>\s]+ ) # bare value (captured)
      )
    )?
  )
  | (?: \{\.\.\.(\s*?[^\s{}]+?\s*?)\} ) # spread attributes (captured)
  | ( [\s\n]+ ) # whitespace (captured)
///

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

