# Coffeescript React Transformer

Provides support for an equivalent of JSX syntax in Coffeescript (called CJSX) so you can write your Facebook React components with the full awesomeness of Coffeescript.

#### Example

car-component.coffee

```html
# @cjsx React.DOM
Car = React.createClass
  render: ->
    <Vehicle doors=4 locked={isLocked()}  data-colour="red" on>
      <FrontSeat />
      <BackSeat />
      <p>Which seat can I take? {@props.seat}</p>
    </Vehicle>
```

transform

```bash
cjsx-transform car-component.coffee
```

output

```coffeescript

Car = React.createClass
  render: ->
    Vehicle({"doors": 4, "locked": (isLocked()), "data-colour": "red", "on": true},
      FrontSeat(null),
      BackSeat(null),
      React.DOM.p(null, "Which seat can I take? ", (@props.seat))
    )
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
 Tags nested within other tags' attributes may not be rewritten properly, eg.
```html
  <Component1>
  	<Component2 attr2={<Component3 attr3={ 1 + 1 } />} />
  </Component1>
	```
  Instead you should write:
  ```html
  component3 = <Component3 attr3={ 1 + 1 } />

  <Component1>
    <Component2 attr2={component3} />
  </Component1>
  ```
  which is probably more readable anyway.
