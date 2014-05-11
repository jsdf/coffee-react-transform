
{last} = require './helpers'

$ = require './symbols'

HTML_ELEMENTS = require('./htmlelements')

stringEscape = require './stringescape'

module.exports = serialise = (parseTree) ->
  env = {serialiseNode}
  if parseTree.children and
  parseTree.children.length and
  parseTree.children[0].type is $.CJSX_PRAGMA
    env.domObject = parseTree.children[0].value
  else
    env.domObject = 'React.DOM'

  env.serialiseNode(parseTree)

serialiseNode = (node) ->
  unless serialisers[node.type]?
    throw new Error('unknown parseTree node type')

  serialisers[node.type](node, this)

genericBranchSerialiser = (node, env) ->
  node.children
    .map((child) -> env.serialiseNode child)
    .join('')

genericLeafSerialiser = (node, env) -> node.value

serialise.serialisers = serialisers =
  ROOT: genericBranchSerialiser

  CJSX_PRAGMA: -> null

  CJSX_EL: (node, env) ->
    childrenSerialised = node.children
      .map((child) -> env.serialiseNode child)
      .filter((child) -> child?) # filter empty text nodes
      .join(', ')

    prefix = if HTML_ELEMENTS[node.value]? then env.domObject+'.' else ''
    prefix+node.value+'('+childrenSerialised+')'

  CJSX_ESC: (node, env) ->
    childrenSerialised = node.children
      .map((child) -> env.serialiseNode child)
      .join('')

    '('+childrenSerialised+')'

  CJSX_ATTRIBUTES: (node, env) ->
    # whitespace (particularly newlines) must be maintained for attrs
    # to ensure line number parity
    nonWhitespaceChildren = node.children.filter (child) ->
      child.type isnt $.CJSX_WHITESPACE
    
    lastNonWhitespaceChild = last(nonWhitespaceChildren)

    if nonWhitespaceChildren.length
      childrenSerialised = node.children
        .map (child) ->
          serialised = env.serialiseNode child
          if child.type is $.CJSX_WHITESPACE
            if serialised.indexOf('\n') > -1
              serialised
            else
              null # whitespace without newlines is not significant
          else if child is lastNonWhitespaceChild
            serialised
          else
            serialised+', '
        .join('')
        
      '{'+childrenSerialised+'}'
    else
      'null'

  CJSX_ATTR_PAIR: (node, env) ->
    node.children
      .map((child) -> env.serialiseNode child)
      .join(': ')

  # leaf nodes
  CS: genericLeafSerialiser
  CS_COMMENT: genericLeafSerialiser
  CS_HEREDOC: genericLeafSerialiser
  CS_STRING: genericLeafSerialiser
  JS_ESC: genericLeafSerialiser
  CJSX_WHITESPACE: genericLeafSerialiser

  CJSX_TEXT: (node, env) ->
    # maintain line number parity
    # whitespace-only lines become empty strings
    lines = node.value.split('\n')
    firstLine = lines[0]
    lastLine = last(lines)

    emptyString = ''
    emptyLine = "''"

    trimmedLines = lines.map (line) ->
      if lines is null or line is emptyString or (
        lines.length > 1 and 
        (line is firstLine or line is lastLine) and 
        SPACES_ONLY.test line
      )
        emptyLine
      else
        '"'+stringEscape(line)+'"'

    if lines.length > 1
      trimmedText = trimmedLines.join('+\n')
      # if trimmedLines.filter((line) -> line isnt emptyLine).length
      #   trimmedText = trimmedLines.join('+\n')
      # else
      #   trimmedText = Array(trimmedLines.length).join('\n')
    else
      trimmedText = trimmedLines[0]


    if trimmedText is emptyString or trimmedText is emptyLine
      null # this text node will be omitted
    else
      trimmedText

  CJSX_ATTR_KEY: genericLeafSerialiser
  CJSX_ATTR_VAL: genericLeafSerialiser

SPACES_ONLY = /^\s+$/

