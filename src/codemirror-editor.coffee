# @cjsx

React = require 'react'
CodeMirror = require 'code-mirror/mode/coffeescript'

CodeMirrorEditor = React.createClass
  getDefaultProps: ->
    codeText: ""
    
  componentDidMount: ->
    @editor = CodeMirror.fromTextArea @refs.editor.getDOMNode(),
      theme: require('code-mirror/theme/tomorrow-night-eighties')
      mode: 'coffeescript'
      lineNumbers: true
      lineWrapping: true
      # smartIndent: false  # javascript mode does bad things with jsx indents
      matchBrackets: true
      indentUnit: 2
      tabSize: 2
      # theme: 'solarized-light',
      readOnly: @props.readOnly

    @editor.on('change', @handleChange)

  componentDidUpdate: ->
    if @props.readOnly
      @editor.setValue(@props.codeText)

  handleChange: ->
    unless @props.readOnly
      @props.onChange and @props.onChange(@editor.getValue())

  render: ->
    # wrap in a div to fully contain CodeMirror

    editor = <textarea ref="editor" defaultValue={@props.codeText} rows="50" />

    <div style={@props.style} className={@props.className}>
      {editor}
    </div>

module.exports = CodeMirrorEditor