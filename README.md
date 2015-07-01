# Coffeescript React JSX Transformer

Provides support for an equivalent of JSX syntax in Coffeescript (called CJSX) so you can write your Facebook React components with the full awesomeness of Coffeescript. [Try it out](https://jsdf.github.io/coffee-react-transform/).

#### Example

car-component.coffee

```coffee
Car = React.createClass
  render: ->
    <Vehicle doors={4} locked={isLocked()} data-colour="red" on>
      <Parts.FrontSeat />
      <Parts.BackSeat />
      <p className="seat">Which seat can I take? {@props?.seat or 'none'}</p>
      {# also, this is a comment }
    </Vehicle>
```

transform

```bash
cjsx-transform car-component.coffee
```

output

```coffee
Car = React.createClass
  render: ->
    React.createElement(Vehicle, {"doors": (4), "locked": (isLocked()), "data-colour": "red", "on": true},
      React.createElement(Parts.FrontSeat, null),
      React.createElement(Parts.BackSeat, null),
      React.createElement("p", {"className": "seat"}, "Which seat can I take? ", (@props?.seat or 'none'))
    )
```

### Getting Started
`coffee-react-transform` simply handles preprocessing Coffeescript with JSX-style markup into valid Coffeescript. Instead of using it directly, you may want to make use of one of these more high-level tools:
- [coffee-react](https://github.com/jsdf/coffee-react): a drop-in replacement for the `coffee` executable, for compiling CJSX.
- [node-cjsx](https://github.com/SimonDegraeve/node-cjsx): `require` CJSX files on the server (also possible with [coffee-react/register](https://github.com/jsdf/coffee-react)).
- [coffee-reactify](https://github.com/jsdf/coffee-reactify): bundle CJSX files via [browserify](https://github.com/substack/node-browserify), see also [cjsxify](https://github.com/SimonDegraeve/cjsxify).
- [cjsx-loader](https://github.com/KyleAMathews/cjsx-loader): loader module for Webpack.
- [react-coffee-quickstart](https://github.com/SimonDegraeve/react-coffee-quickstart): equivalent to [react-quickstart](https://github.com/andreypopp/react-quickstart).
- [coffee-react-quickstart](https://github.com/KyleAMathews/coffee-react-quickstart): Quickstart for building React single page apps using Coffeescript, Gulp, Webpack, and React-Router
- [sprockets preprocessor](https://github.com/jsdf/sprockets-coffee-react): use CJSX with Rails/Sprockets
- [ruby coffee-react gem](https://github.com/jsdf/ruby-coffee-react) for general ruby integration
- [vim plugin](https://github.com/mtscout6/vim-cjsx) for syntax highlighting
- [sublime text package](https://github.com/Guidebook/sublime-cjsx) for syntax highlighting
- [mimosa plugin](https://github.com/mtscout6/mimosa-cjsx) for the mimosa build tool
- [karma preprocessor](https://github.com/mtscout6/karma-cjsx-preprocessor) for karma test runner
- [broccoli plugin](https://github.com/ghempton/broccoli-cjsx) for the broccoli build tool

### CLI

```bash
cjsx-transform [input file]
```
Outputs Coffeescript code to stdout. Redirect it to a file or straight to the Coffeescript compiler, eg.
```bash
cjsx-transform examples/car.coffee | coffee -cs > car.js
```

### API
```coffee
transform = require 'coffee-react-transform'

transformed = transform('...some CJSX code...')
```

### Installation
From [npm](https://www.npmjs.org/):
```bash
npm install -g coffee-react-transform
```

#### Version compatibility
- 3.x - React 0.13.x
- 2.1.x - React 0.12.1
- 2.x - React 0.12
- 1.x - React 0.11.2
- 0.x - React 0.11 and below

#### UMD bundle for the browser
If you want to use coffee-react-transform in the browser or under ExecJS or some other environment that doesn't support CommonJS modules, you can use this build provided by [BrowserifyCDN](wzrd.in), which will work as an AMD module or just a plain old script tag:

[http://wzrd.in/standalone/coffee-react-transform](http://wzrd.in/standalone/coffee-react-transform)

```html
<script src="http://wzrd.in/standalone/coffee-react-transform"></script>
<script>
  coffeeReactTransform('-> <a />');
  // returns '-> React.createElement("a", null)'
</script>
```

### Spread attributes
A semi-recent addition to JSX (and CJSX) is 'spread attributes' which allow merging an object of props into a component, eg:
```coffee
extraProps = color: 'red', speed: 'fast'
<div color="blue" {... extraProps} />
```
which is transformed to:
```coffee
extraProps = color: 'red', speed: 'fast'
React.createElement("div", React.__spread({"color": "blue"},  extraProps)
```

### Tests

`npm test` or `cake test` or `cake watch:test`

### Changelog

#### 3.1.0
- Fix literate CoffeeScript/CJSX with single apostrophes in Markdown ([benjie](https://github.com/benjie))

#### 3.0.1
- Fixed some bugs relating to self-closing tags with spread attributes

#### 3.0.0
- Added CJSX single line comment syntax: `{# comment goes here}` ([ConradIrwin](https://github.com/ConradIrwin))
- All lower case tags now output component names as strings (eg. DOM or custom elements), and custom element names must contain a hyphen ([AsaAyers](https://github.com/AsaAyers))

#### 2.4.1
- Made spread attribute output not create unnecessary objects
- Output legacy JSX pragma when legacy CJSX pragma used

#### 2.2.0
- Use `React.__spread` instead of `Object.assign`

### Breaking Changes in 1.0

React 0.12 will introduce changes to the way component descriptors are constructed, where the return value of `React.createClass` is not a descriptor factory but simply the component class itself, and descriptors must be created manually using `React.createElement` or by wrapping the component class with `React.createDescriptor`. In preparation for this, coffee-react-transform now outputs calls to `React.createElement` to construct element descriptors from component classes for you, so you won't need to [wrap your classes using `React.createFactory`](https://gist.github.com/sebmarkbage/ae327f2eda03bf165261). However, for this to work you will need to be using at least React 0.11.2, which adds `React.createElement`.

If you want the older style JSX output (which just desugars into function calls) then you need to use the 0.x branch, eg. 0.5.1.
