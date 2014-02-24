
# ALL_TAGS = /<\/?\w+((\s+\w+(\s*=\s*(?:".*?"|'.*?'|[^'">\s]+))?)+\s*|\s*)\/?>/

# [0] tag name
# [1] attributes text
# [2] self closing?
OPENING_TAG = /<([-A-Za-z0-9_]+)((?:\s+\w+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>/

# [0] tag name
CLOSING_TAG = /<\/([-A-Za-z0-9_]+)[^>]*>/

# exec (call until null)
# [0] attr=val
# [1] attr
# [2] val if quoted
# [3] 
# [4] val if not quoted
TAG_ATTRIBUTES = /([-A-Za-z0-9_]+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')|([^>\s]+)))?/g

nextTag = (remainingText) ->
  remainingText.match OPENING_TAG
  remainingText.match CLOSING_TAG

getAttributes = (attributesText) ->
  attributesValues = {}
  TAG_ATTRIBUTES.lastIndex = 0
  while attrMatches = TAG_ATTRIBUTES.exec attributesText
    attributesValues[attrMatches[1]] = attrMatches[2] || attrMatches[4] || true
  attributesValues

transformTag = (tagName,attributesText,selfClosing) ->
  transformedTokens = []
  attributes = getAttributes(attributesText)
  unless selfClosing
    nextTag()





