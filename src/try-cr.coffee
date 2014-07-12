# @cjsx
React = require 'react'
CoffeeReact = require 'coffee-react'

CodeMirrorEditor = require './codemirror-editor'

TryCR = React.createClass
  componentDidMount: ->
    @forceUpdate()
  getInitialState: ->
    codeText: """
    # @cjsx React.DOM

    Car = React.createClass
      render: ->
        <Vehicle locked={isLocked()}  data-colour="red" on>
          <Parts.FrontSeat />
          <Parts.BackSeat />
          <p>Which seat can I take? {@props?.seat or 'none'}</p>
        </Vehicle>
    """

  renderEditorOrError: (code, transform) ->
    try
      transformed = transform(code)
    catch err
      return <pre className="error">{err.toString()}</pre>

    <CodeMirrorEditor codeText={transformed} readOnly />
    
  handleChange: (codeText) ->
    @setState {codeText}

  render: ->
    {codeText} = @state
    transform = (code) ->
      CoffeeReact.transform(code)
    <div>
      <CodeMirrorEditor codeText={codeText} onChange={@handleChange} />
      {@renderEditorOrError(codeText, transform)}
    </div>

React.renderComponent(<TryCR />, document.getElementById('try-cr'))
