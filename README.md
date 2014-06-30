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
- [coffee-react](https://github.com/jsdf/coffee-react): a drop-in replacement for the `coffee` executable, for compiling CJSX.
- [node-cjsx](https://github.com/SimonDegraeve/node-cjsx): `require` CJSX files on the server (also possible with [coffee-react/register](https://github.com/jsdf/coffee-react)).
- [coffee-reactify](https://github.com/jsdf/coffee-reactify): bundle CJSX files via [browserify](https://github.com/substack/node-browserify), see also [cjsxify](https://github.com/SimonDegraeve/cjsxify).  
- [react-coffee-quickstart](https://github.com/SimonDegraeve/react-coffee-quickstart): equivalent to [react-quickstart](https://github.com/andreypopp/react-quickstart).
- [sprockets preprocessor](https://github.com/jsdf/sprockets-coffee-react): use CJSX with Rails/Sprockets
- [ruby coffee-react gem](https://github.com/jsdf/ruby-coffee-react) for general ruby integration
- [vim plugin](https://github.com/mtscout6/vim-cjsx) for syntax highlighting
- [sublime text package](https://github.com/reactjs/sublime-react/) for syntax highlighting
- [mimosa plugin](https://github.com/mtscout6/mimosa-cjsx) for the mimosa build tool
- [karma preprocessor](https://github.com/mtscout6/karma-cjsx-preprocessor) for karma test runner

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

### Load .cjsx files with [Karma](http://karma-runner.github.io/)
Add a preprocessor clause to the karma conf file, and it will automatically transorm the .cjsx files.

```
module.exports = function(config) {
  config.set({
    preprocessors: {
      '**/*.cjsx': [ 'cjsx' ]
    },

    // the rest of the config should be here
  })
}
```

#### Note about the .cjsx file extension
The custom file extension recently changed from `.csx` to `.cjsx` to avoid conflicting with an existing C# related file extension, so be sure to update your files accordingly (including changing the pragma to  `@cjsx`). You can also just use `.coffee` as the file extension. Backwards compatibility will be maintained until the next major version.
