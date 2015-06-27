# @cjsx
React = require 'react'
CoffeeReact = require 'coffee-react'
url = require 'url'

CodeMirrorEditor = require './codemirror-editor'

EXAMPLE_CODE = """
Car = React.createClass
  render: ->
    <Vehicle locked={isLocked()}  data-colour="red" on>
      <Parts.FrontSeat />
      <Parts.BackSeat />
      <p>Which seat can I take? {@props.seat or 'none'}</p>
    </Vehicle>
"""

TryCR = React.createClass
  getInitialState: ->
    urlParsed = url.parse(window.location.href, true)
    codeText = urlParsed.query.code? and try atob(urlParsed.query.code)
    codeText ||= EXAMPLE_CODE

    {
      codeText,
      compile: false,
    }

  handleChange: (codeText) ->
    @setState {codeText}

  handleCompileToggleChange: (e) ->
    @setState compile: e.target.name is 'compile'

  renderEditorOrError: (code) ->
    try
      transformed = 
        if @state.compile
          CoffeeReact.compile(code)
        else
          CoffeeReact.transform(code)
    catch err
      return <pre className="error">{err.toString()}</pre>

    <CodeMirrorEditor codeText={transformed} readOnly />

  renderCompileToggle: ->
    <form className="compile-toggle">
      <h4>mode</h4>
      <label>
        transform
        <input
          type="radio"
          name="transform"
          checked={!@state.compile}
          onChange={@handleCompileToggleChange}
        />
      </label>
      <label>
        compile
        <input
          type="radio"
          name="compile"
          checked={@state.compile}
          onChange={@handleCompileToggleChange}
        />
      </label>
    </form>

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

    <div>
      <CodeMirrorEditor codeText={codeText} onChange={@handleChange} />
      {@renderEditorOrError(codeText)}
      {@renderShareLink()}
      {@renderCompileToggle()}
    </div>

React.render(<TryCR />, document.getElementById('try-cr'))
