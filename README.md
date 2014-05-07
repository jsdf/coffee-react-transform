# Coffeescript React Transformer

Provides support for an equivalent of JSX syntax in Coffeescript (called CJSX) so you can write your Facebook React components with the full awesomeness of Coffeescript.

#### Example

car-component.coffee

```html
# @cjsx React.DOM 
Car = React.createClass
  render: ->
    <Vehicle doors=4 stars={getSafetyRating()*5}  data-top-down="yep" checked>
      <FrontSeat />
      <BackSeat />
      <p>Which seat can I take? {@props.seat}</p>
    </Vehicle>

React.renderComponent(<Car seat="front, obvs" />, document.getElementById('container'))
```

transform

```bash
cjsx-transform car-component.coffee
```

output

```coffeescript
# @cjsx React.DOM 
Car = React.createClass
  render: ->
    Vehicle({"doors": "4", "stars": (getSafetyRating()*5), "data-top-down": "yep", "checked": true}, FrontSeat(null), BackSeat(null), React.DOM.p(null, """Which seat can I take?""", (@props.seat)))

React.renderComponent(Car({"seat": "front, obvs"}), document.getElementById('container'))
```

### Note about the .cjsx file extension
The custom file extension recently changed from `.csx` to `.cjsx` to avoid conflicting with an existing C# related file extension, so be sure to update your files accordingly (including changing the pragma to  `@cjsx`). You can also just use `.coffee` as the file extension. Backwards compatibility will be maintained until the next major version.

### Installation
```bash
npm install -g coffee-react-transform
```

### CLI

```bash
cjsx-transform [input file]
```
Outputs Coffeescript code to stdout. Redirect it to a file or straight to the Coffeescript compiler, eg.
```bash
cjsx-transform examples/car.coffee | coffee -cs > car.js
```

### API
```coffeescript
transform = require 'coffee-react-transform'

transformed = transform('...some cjsx code...')
```

### Tests

`cake test` or `cake watch:test`


### Known issues/caveats
- At this stage regex literals are not properly 'escaped' so any html tags inside a regex literal will be transformed as well. This will be fixed.

