
{last, find} = require './helpers'

$ = require './symbols'

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

    domObjectParts = @domObject.split('.')
    if domObjectParts.length > 0 and domObjectParts[0] isnt ''
      @reactObject = domObjectParts[0]
    else
      @reactObject = 'React'

    @serialiseNode(parseTree)

  serialiseNode: (node) ->
    unless nodeSerialisers[node.type]?
      throw new Error("unknown parseTree node type #{node.type}")

    serialised = nodeSerialisers[node.type].call(this, node)

    unless typeof serialised is 'string' or serialised is null
      throw new Error("serialiser #{node.type} didn\'t return a string")

    serialised

  serialiseSpreadAndPairAttributes: (children) ->
    assigns = [] # nodes
    pairAttrsBuffer = [] # nodes

    flushPairs = =>
      if pairAttrsBuffer.length
        serialisedChild = @serialiseAttributePairs(pairAttrsBuffer)
        if serialisedChild
          assigns.push(type: $.CS, value: serialisedChild)
        else
          serialisedPairs = pairAttrsBuffer
            .map((p) => @serialiseNode(p))
            .join('')
            # escaping newlines might create a syntax error if the newline is
            # after the last arg in a list, so we'll fix it below
            .replace('\n', '\\\n')
          assigns.push(type: $.CJSX_WHITESPACE, value: serialisedPairs)
        pairAttrsBuffer = [] # reset buffer

    # okay this is pretty gross. once source maps are up and running all of the
    # whitespace related bs can be nuked as there will no longer be a need to 
    # torture the CS syntax to maintain whitespace and output the same number 
    # of lines while also transforming syntax. however in the mean time, this is 
    # what we're doing.

    # this code rewrites attr pair, spread, etc nodes into CS (code fragment) 
    # and whitespace nodes. then they are serialised and joined with whitespace 
    # maintained, and newlines escaped (except at the end of an args list)
    
    # initial object assign arg
    if firstNonWhitespaceChild(children)?.type is $.CJSX_ATTR_SPREAD
      assigns.push(type: $.CS, value: '{}')

    # group sets of attr pairs between spreads
    for child, childIndex in children
      if child.type is $.CJSX_ATTR_SPREAD
        flushPairs()
        assigns.push(type: $.CS, value: child.value)
      else
        pairAttrsBuffer.push(child)

    # finally group any remaining pairs
    flushPairs()

    # serialising the rewritten nodes with whitespace maintained
    accumulatedWhitespace = ''
    assignsWithWhitespace = [] # serialised nodes texts
    for assignItem, assignIndex in assigns
      if assignItem?
        if assignItem.type is $.CJSX_WHITESPACE
          accumulatedWhitespace += @serialiseNode(assignItem)
        else
          assignsWithWhitespace.push(accumulatedWhitespace + @serialiseNode(assignItem))
          accumulatedWhitespace = ''

    if assignsWithWhitespace.length
      lastAssignWithWhitespace = assignsWithWhitespace.pop()
      # hack to fix potential syntax error when newlines are escaped after last arg
      # TODO: kill this with fire once sourcemaps are available
      trailingWhiteplace = accumulatedWhitespace.replace('\\\n', '\n')
      assignsWithWhitespace.push(lastAssignWithWhitespace + trailingWhiteplace)

    joinedAssigns = joinList(assignsWithWhitespace)

    "Object.assign(#{joinList(assignsWithWhitespace)})"

  serialiseAttributePairs: (children) ->
    # whitespace (particularly newlines) must be maintained
    # to ensure line number parity

    # sort children into whitespace and semantic (non whitespace) groups
    [whitespaceChildren, semanticChildren] = children.reduce((partitionedChildren, child) ->
      if child.type is $.CJSX_WHITESPACE
        partitionedChildren[0].push child
      else
        partitionedChildren[1].push child
      partitionedChildren
    , [[],[]])

    indexOfLastSemanticChild = children.lastIndexOf(last(semanticChildren))

    isBeforeLastSemanticChild = (childIndex) ->
      childIndex < indexOfLastSemanticChild

    if semanticChildren.length
      serialisedChildren = for child, childIndex in children
        serialisedChild = @serialiseNode child
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
      null

genericBranchSerialiser = (node) ->
  node.children
    .map((child) => @serialiseNode child)
    .join('')

genericLeafSerialiser = (node) -> node.value

componentClassTagConvention = /(^[A-Z@]|\.)/

nodeSerialisers =
  ROOT: genericBranchSerialiser

  CJSX_PRAGMA: -> "`/** @jsx #{@domObject} */`"

  CJSX_EL: (node) ->
    serialisedChildren = []
    accumulatedWhitespace = ''

    for child in node.children
      serialisedChild = @serialiseNode child
      if child? # filter empty text nodes
        if serialisedChild.length is 0 or WHITESPACE_ONLY.test serialisedChild
          accumulatedWhitespace += serialisedChild
        else
          serialisedChildren.push(accumulatedWhitespace + serialisedChild)
          accumulatedWhitespace = ''

    if serialisedChildren.length
      serialisedChildren[serialisedChildren.length-1] += accumulatedWhitespace
      accumulatedWhitespace = ''

    # Identifiers which start with an upper case letter, @, or contain a dot 
    # (property access) are component classes. Everything else is treated as a 
    # DOM/custom element, and output as a name string.
    if componentClassTagConvention.test(node.value)
      element = node.value
    else
      element = '"'+node.value+'"'
    "#{@reactObject}.createElement(#{element}, #{joinList(serialisedChildren)})"

  CJSX_COMMENT: (node) ->
    ''

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
      .join(': ')

  CJSX_ATTR_SPREAD: (node) ->
    node.value

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

firstNonWhitespaceChild = (children) ->
  find.call children, (child) ->
    child.type isnt $.CJSX_WHITESPACE

containsNewlines = (text) -> text.indexOf('\n') > -1

joinList = (items) ->
  output = items[items.length-1]
  i = items.length-2

  while i >= 0
    if output.charAt(0) is '\n'
      output = items[i]+','+output
    else
      output = items[i]+', '+output
    i--
  output


SPACES_ONLY = /^\s+$/

WHITESPACE_ONLY = /^[\n\s]+$/

# leading and trailing whitespace which contains a newline
TEXT_LEADING_WHITESPACE = /^\s*?\n\s*/
TEXT_TRAILING_WHITESPACE = /\s*?\n\s*?$/

exports.Serialiser = Serialiser
exports.nodeSerialisers = nodeSerialisers
