# @cjsx
React = require 'react'
CoffeeReact = require 'coffee-react'
url = require 'url'

CodeMirrorEditor = require './codemirror-editor'

EXAMPLE_CODE = """
# @cjsx React.DOM

Car = React.createClass
  render: ->
    <Vehicle locked={isLocked()}  data-colour="red" on>
      <Parts.FrontSeat />
      <Parts.BackSeat />
      <p>Which seat can I take? {@props?.seat or 'none'}</p>
    </Vehicle>
"""

TryCR = React.createClass
  getInitialState: ->
    urlParsed = url.parse(window.location.href, true)
    codeText = urlParsed.query.code? and try atob(urlParsed.query.code)
    codeText ||= EXAMPLE_CODE
    {codeText}

  handleChange: (codeText) ->
    @setState {codeText}

  renderEditorOrError: (code, transform) ->
    try
      transformed = transform(code)
    catch err
      return <pre className="error">{err.toString()}</pre>

    <CodeMirrorEditor codeText={transformed} readOnly />

  renderShareLink: ->
    urlParsed = url.parse(window.location.href, true)
    urlParsed.search = null
    urlParsed.query.code = btoa(@state.codeText)

    <div className="share-link">
      <div className="share-link-desc">shareable link: </div>
      <textarea 
        className="share-link-content"
        value={url.format(urlParsed)}
        onFocus={(e) -> e.target.select()}
        readOnly
      />
    </div>

  render: ->
    {codeText} = @state
    transform = (code) ->
      CoffeeReact.transform(code)
    <div>
      <CodeMirrorEditor codeText={codeText} onChange={@handleChange} />
      {@renderEditorOrError(codeText, transform)}
      {@renderShareLink()}
    </div>

React.renderComponent(<TryCR />, document.getElementById('try-cr'))
