# Coffeescript JSX Transformer

Provides support for JSX-in-Coffeescript (CSX) so you can write your React components in Coffeescript, with no escaping.

car-component.csx:

```html
# @jsx React.DOM 
Car = React.createClass
  render: ->
    <Car doors=4 safety={getSafetyRating()*2}  data-top-down="yep" checked>
      <FrontSeat />
      <BackSeat />
      Which seat can I take? {@props.seat}
    </Car>

React.renderComponent \
  <Car seat="front, obvs" />,
  document.getElementById 'container'
```

build.coffee:

```coffeescript
fs = require 'fs'
transform = require 'csx-transformer'

componentInCSX = fs.readFileSync('./car-component.csx', 'utf8')

console.log transform(componentInCSX)
```

output:

```coffeescript
# @jsx React.DOM 
Car = React.createClass
  render: ->
    Car({"doors": "4", "safety": (getSafetyRating()*2), "data-top-down": "yep", "checked": true}, FrontSeat(null), BackSeat(null), """Which seat can I take?""", (@props.seat))

React.renderComponent \
  Car({"seat": "front, obvs"}),
  document.getElementById 'container'
```

### Building

```bash
npm install -g coffee-script
cake build
```

### Tests

`cake test` or `cake watch:test`

