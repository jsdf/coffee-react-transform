
{last} = require './helpers'
{inspect} = require 'util'

$ = require './symbols'

HTML_ELEMENTS = require('./htmlelements')

stringEscape = require './stringescape'

occurrences = require './occurrences'

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
    throw new Error("unknown parseTree node type #{node.type}")

  serialised = serialisers[node.type](node, this)

  unless typeof serialised is 'string' or serialised is null
    throw new Error("serialiser #{node.type} didn\'t return a string for node #{inspect(node)}, instead returned #{serialised}")

  serialised


genericBranchSerialiser = (node, env) ->
  node.children
    .map((child) -> env.serialiseNode child)
    .join('')

genericLeafSerialiser = (node, env) -> node.value

serialise.serialisers = serialisers =
  ROOT: genericBranchSerialiser

  CJSX_PRAGMA: -> null

  CJSX_EL: (node, env) ->
    serialisedChildren = []
    accumulatedWhitespace = ''

    for child in node.children
      serialisedChild = env.serialiseNode child
      if child? # filter empty text nodes
        if WHITESPACE_ONLY.test serialisedChild
          accumulatedWhitespace += serialisedChild
        else
          serialisedChildren.push(accumulatedWhitespace + serialisedChild)
          accumulatedWhitespace = ''

    if serialisedChildren.length
      serialisedChildren[serialisedChildren.length-1] += accumulatedWhitespace
      accumulatedWhitespace = ''

    prefix = if HTML_ELEMENTS[node.value]? then env.domObject+'.' else ''
    prefix+node.value+'('+serialisedChildren.join(', ')+')'

  CJSX_ESC: (node, env) ->
    childrenSerialised = node.children
      .map((child) -> env.serialiseNode child)
      .join('')
    '('+childrenSerialised+')'

  CJSX_ATTRIBUTES: (node, env) ->
    # whitespace (particularly newlines) must be maintained
    # to ensure line number parity
    
    # sort children into whitespace and semantic (non whitespace) groups
    # this seems wrong :\
    [whitespaceChildren, semanticChildren] = node.children.reduce((partitionedChildren, child) ->
      if child.type is $.CJSX_WHITESPACE
        partitionedChildren[0].push child
      else
        partitionedChildren[1].push child
      partitionedChildren
    , [[],[]])

    indexOfLastSemanticChild = node.children.lastIndexOf(last(semanticChildren))

    isBeforeLastSemanticChild = (childIndex) ->
      childIndex < indexOfLastSemanticChild

    if semanticChildren.length
      serialisedChildren = for child, childIndex in node.children
        serialisedChild = env.serialiseNode child
        if child.type is $.CJSX_WHITESPACE
          if containsNewlines(serialisedChild)
            if isBeforeLastSemanticChild(childIndex)
              # escaping newlines within attr object helps avoid 
              # parse errors in tags which span multiple lines
              serialisedChild.replace('\n',' \\\n')
            else
              # but escaped newline at end of attr object is not allowed
              serialisedChild
          else
            null # whitespace without newlines is not significant
        else if isBeforeLastSemanticChild(childIndex)
          serialisedChild+', '
        else
          serialisedChild
        
      '{'+serialisedChildren.join('')+'}'
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
  CS_REGEX: genericLeafSerialiser
  CS_HEREGEX: genericLeafSerialiser
  JS_ESC: genericLeafSerialiser
  CJSX_WHITESPACE: genericLeafSerialiser

  CJSX_TEXT: (node) ->
    # trim whitespace only if it includes a newline
    text = node.value
    if containsNewlines(text)
      if WHITESPACE_ONLY.test text
        text
      else
        leftSpace = text.match TEXT_LEADING_WHITESPACE
        rightSpace = text.match TEXT_TRAILING_WHITESPACE

        if leftSpace 
          leftTrim = text.indexOf('\n')
        else 
          leftTrim = 0

        if rightSpace
          rightTrim = text.lastIndexOf('\n')+1
        else
          rightTrim = text.length

        trimmedText = text.substring(leftTrim, rightTrim)
        '"""'+trimmedText+'"""'
        # '"""'+text+'"""'

    else
      if text == ''
        null # this text node will be omitted
      else
        '"'+text+'"'

  CJSX_ATTR_KEY: genericLeafSerialiser
  CJSX_ATTR_VAL: genericLeafSerialiser


containsNewlines = (text) -> text.indexOf('\n') > -1

SPACES_ONLY = /^\s+$/

WHITESPACE_ONLY = /^[\n\s]+$/

# leading and trailing whitespace which contains a newline
TEXT_LEADING_WHITESPACE = /^\s*?\n\s*/
TEXT_TRAILING_WHITESPACE = /\s*?\n\s*?$/

