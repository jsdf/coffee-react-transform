# Coffeescript React JSX Transformer

Provides support for an equivalent of JSX syntax in Coffeescript (called CJSX) so you can write your Facebook React components with the full awesomeness of Coffeescript.

#### Example

car-component.coffee

```html
# @cjsx React.DOM
Car = React.createClass
  render: ->
    <Vehicle doors={4} locked={isLocked()}  data-colour="red" on>
      <Parts.FrontSeat />
      <Parts.BackSeat />
      <p>Which seat can I take? {@props?.seat or 'none'}</p>
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
    Vehicle({"doors": (4), "locked": (isLocked()), "data-colour": "red", "on": true}, 
      Parts.FrontSeat(null), 
      Parts.BackSeat(null), 
      React.DOM.p(null, "Which seat can I take? ", (@props?.seat or 'none'))
    )
```

### Getting Started
`coffee-react-transform` simply handles preprocessing Coffeescript with JSX-style markup into valid Coffeescript. Instead of using it directly, you may want to make use of one of these more high-level tools:   
- For a drop in replacement for the `coffee` executable check out [coffee-react](https://github.com/jsdf/coffee-react).  
- If you want to be able to `require()` CJSX files on the server use [node-cjsx](https://github.com/SimonDegraeve/node-cjsx) or [coffee-react](https://github.com/jsdf/coffee-react).  
- If you want to bundle CJSX files via browserify, take a look at [coffee-reactify](https://github.com/jsdf/coffee-reactify) or [cjsxify](https://github.com/SimonDegraeve/cjsxify).  
- For an equivalent to [react-quickstart](https://github.com/andreypopp/react-quickstart) see [react-coffee-quickstart](https://github.com/SimonDegraeve/react-coffee-quickstart).  

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

transformed = transform('...some CJSX code...')
```

### Tests

`cake test` or `cake watch:test`


#### Note about the .cjsx file extension
The custom file extension recently changed from `.csx` to `.cjsx` to avoid conflicting with an existing C# related file extension, so be sure to update your files accordingly (including changing the pragma to  `@cjsx`). You can also just use `.coffee` as the file extension. Backwards compatibility will be maintained until the next major version.

