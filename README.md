# Coffeescript React Transformer

Provides support for an equivalent of JSX syntax in Coffeescript (called CSX) so you can write your Facebook React components with the full awesomeness of Coffeescript.

car-component.csx:

```html
# @csx React.DOM 
Car = React.createClass
  render: ->
    <Car doors=4 stars={getSafetyRating()*5}  data-top-down="yep" checked>
      <FrontSeat />
      <BackSeat />
      <p>Which seat can I take? {@props.seat}</p>
    </Car>

React.renderComponent <Car seat="front, obvs" />,
  document.getElementById 'container'
```

Transform it to Coffeescript:

```bash
csx-transformer car-component.csx
```

Output:

```coffeescript
# @csx React.DOM 
Car = React.createClass
  render: ->
    Car({"doors": "4", "stars": (getSafetyRating()*5), "data-top-down": "yep", "checked": true}, FrontSeat(null), BackSeat(null), React.DOM.p(null, """Which seat can I take?""", (@props.seat)))

React.renderComponent Car({"seat": "front, obvs"}),
  document.getElementById 'container'
```

### Usage

```bash
csx-transformer [input file]
```
Outputs Coffeescript code to stdout. Redirect it to a file or straight to the Coffeescript compiler, eg.
```bash
csx-transform examples/car.csx | coffee -cs > car.js
```

### Tests

`cake test` or `cake watch:test`


### Known issues/caveats
- At this stage regex literals are not properly 'escaped' so any html tags inside a regex literal will be transformed as well. This will be fixed.
- The `@csx React.DOM` pragma is ignored, and it's assumed that you want all known html tags to be transformed to React.DOM elements. This will be fixed to match the behaviour of the JSX transformer.


