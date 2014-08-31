
{last, find} = require './helpers'

$ = require './symbols'

HTML_ELEMENTS = require('./htmlelements')

stringEscape = require './stringescape'

entityDecode = require './entitydecode'

module.exports = exports = serialise = (parseTree) ->
  new Serialiser().serialise(parseTree)

class Serialiser
  serialise: (parseTree) ->
    if parseTree.children and
    parseTree.children.length and
    parseTree.children[0].type is $.CJSX_PRAGMA
      @domObject = parseTree.children[0].value
    else
      @domObject = 'React.DOM'

    @serialiseNode(parseTree)

  serialiseNode: (node) ->
    unless nodeSerialisers[node.type]?
      throw new Error("unknown parseTree node type #{node.type}")

    serialised = nodeSerialisers[node.type].call(this, node)

    unless typeof serialised is 'string' or serialised is null
      throw new Error("serialiser #{node.type} didn\'t return a string")

    serialised

  serialiseSpreadAndPairAttributes: (children) ->
    assigns = []
    pairAttrsBuffer = []

    flushPairs = =>
      if pairAttrsBuffer.length
        serialisedChild = @serialiseAttributePairs(pairAttrsBuffer)
        assigns.push(serialisedChild+', ') if serialisedChild # skip null
        pairAttrsBuffer = [] # reset buffer

    if children[0]?.type is $.CJSX_ATTR_SPREAD
      assigns.push('{}, ')

    for child, childIndex in children
      if child.type is $.CJSX_ATTR_SPREAD
        flushPairs()
        assigns.push(@serialiseNode(child))
      else
        pairAttrsBuffer.push(child)

      flushPairs()

    'Object.assign('+stripLastComma(assigns.join(''))+')'

  serialiseAttributePairs: (children) ->
    # whitespace (particularly newlines) must be maintained
    # to ensure line number parity
    if children.length and not (children.length is 1 and children[0].type is $.CJSX_WHITESPACE) 
      serialisedChildren = for child, childIndex in children
        serialisedChild = @serialiseNode child
        if child.type is $.CJSX_WHITESPACE
          innerLeadingWhitespace serialisedChild
        else
          appendTrailingWhitespace child, (
            if childIndex < children.length - 1
              if containsNewlines(serialisedChild)
                # escaping newlines within attr object helps avoid 
                # parse errors in tags which span multiple lines
                escapeNewlines serialisedChild
              else
                serialisedChild
            else # last child
              stripLastComma serialisedChild
          )
        
      '{'+serialisedChildren.join('')+'}'
    else
      null

genericBranchSerialiser = (node) ->
  node.children
    .map((child) => @serialiseNode child)
    .join('')

genericLeafSerialiser = (node) -> node.value

nodeSerialisers =
  ROOT: genericBranchSerialiser

  CJSX_PRAGMA: -> null

  CJSX_EL: (node) ->
    serialisedChildren = []
    accumulatedWhitespace = ''

    for child in node.children
      serialisedChild = @serialiseNode child
      if child? # filter empty text nodes
        if WHITESPACE_ONLY.test serialisedChild
          accumulatedWhitespace += serialisedChild
        else
          serialisedChildren.push(accumulatedWhitespace + serialisedChild)
          accumulatedWhitespace = ''

    if serialisedChildren.length
      serialisedChildren[serialisedChildren.length-1] += accumulatedWhitespace
      accumulatedWhitespace = ''

    prefix = if HTML_ELEMENTS[node.value]? then @domObject+'.' else ''
    prefix+node.value+'('+serialisedChildren.join(', ')+')'

  CJSX_ESC: (node) ->
    childrenSerialised = node.children
      .map((child) => @serialiseNode child)
      .join('')
    '('+childrenSerialised+')'

  CJSX_ATTRIBUTES: (node) ->
    if node.children.some((child) -> child.type is $.CJSX_ATTR_SPREAD)
      @serialiseSpreadAndPairAttributes(node.children)
    else
      @serialiseAttributePairs(node.children) or 'null'

  CJSX_ATTR_PAIR: (node) ->
    node.children
      .map((child) => @serialiseNode child)
      .join(': ')+', '

  CJSX_ATTR_SPREAD: (node) ->
    node.value+', '

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
        # this is not very efficient
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
        # decode html entities to chars
        # escape string special chars except newlines
        # output to multiline string literal for line parity
        escapedText = stringEscape(entityDecode(trimmedText), preserveNewlines:  true)
        '"""'+escapedText+'"""'

    else
      if text == ''
        null # this text node will be omitted
      else
        # decode html entities to chars
        # escape string special chars
        '"'+stringEscape(entityDecode(text))+'"'

  CJSX_ATTR_KEY: genericLeafSerialiser
  CJSX_ATTR_VAL: genericLeafSerialiser

containsNewlines = (text) -> text.indexOf('\n') > -1

appendTrailingWhitespace = (node, serialised) ->
  if node.trailingWhitespace and containsNewlines(node.trailingWhitespace)
    serialised + node.trailingWhitespace
  else
    serialised

innerLeadingWhitespace = (text) ->
  if containsNewlines(text)
    escapeNewlines(text)
  else
    null

stripLastComma = (text) -> text.replace(/\s*,\s*$/,'')

escapeNewlines = (text) -> text.replace("\n"," \\\n")

SPACES_ONLY = /^\s+$/

WHITESPACE_ONLY = /^[\n\s]+$/

# leading and trailing whitespace which contains a newline
TEXT_LEADING_WHITESPACE = /^\s*?\n\s*/
TEXT_TRAILING_WHITESPACE = /\s*?\n\s*?$/

exports.Serialiser = Serialiser
exports.nodeSerialisers = nodeSerialisers
