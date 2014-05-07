# @cjsx React.DOM 

React = require('react')

Car = React.createClass
  render: ->
    <Car doors=4 safety={getSafetyRating()*2}  data-top-down="yep" checked>
      <FrontSeat />
      <BackSeat />
      <p>Which seat can I take? {@props.seat}</p>
    </Car>

React.renderComponent <Car seat="front, obvs" />,
  document.getElementById 'container'