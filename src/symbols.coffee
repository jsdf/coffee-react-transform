
module.exports =
  # branch (state) node types
  ROOT: 'ROOT'
  CJSX_EL: 'CJSX_EL'
  CJSX_ESC: 'CJSX_ESC'
  CJSX_ATTRIBUTES: 'CJSX_ATTRIBUTES'
  CJSX_ATTR_PAIR: 'CJSX_ATTR_PAIR'

  # leaf (value) node types
  CS: 'CS'
  CS_COMMENT: 'CS_COMMENT'
  CS_HEREDOC: 'CS_HEREDOC'
  CS_STRING: 'CS_STRING'
  CS_REGEX: 'CS_REGEX'
  CS_HEREGEX: 'CS_HEREGEX'
  JS_ESC: 'JS_ESC'
  CJSX_WHITESPACE: 'CJSX_WHITESPACE'
  CJSX_TEXT: 'CJSX_TEXT'
  CJSX_ATTR_KEY: 'CJSX_ATTR_KEY'
  CJSX_ATTR_VAL: 'CJSX_ATTR_VAL'
  CJSX_ATTR_SPREAD: 'CJSX_ATTR_SPREAD'

  # tokens
  # these aren't really used as there aren't distinct lex/parse steps
  # they're just names for use in debugging
  CJSX_START: 'CJSX_START'
  CJSX_END: 'CJSX_END'
  CJSX_ESC_START: 'CJSX_ESC_START'
  CJSX_ESC_END: 'CJSX_ESC_END'
  CJSX_PRAGMA: 'CJSX_PRAGMA'
