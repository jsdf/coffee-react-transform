# Change Log

## [4.0.0]
- Replace `React.__spread` with `Object.assign` ([DawidJanczak](https://github.com/DawidJanczak))
- Allow spaces in spread attributes ([rechtar](https://github.com/rechtar))

## [3.1.0]
- Fix literate CoffeeScript/CJSX with single apostrophes in Markdown ([benjie](https://github.com/benjie))

## [3.0.1]
- Fixed some bugs relating to self-closing tags with spread attributes

## [3.0.0]
- Added CJSX single line comment syntax: `{# comment goes here}` ([ConradIrwin](https://github.com/ConradIrwin))
- All lower case tags now output component names as strings (eg. DOM or custom elements), and custom element names must contain a hyphen ([AsaAyers](https://github.com/AsaAyers))

## [2.4.1]
- Made spread attribute output not create unnecessary objects
- Output legacy JSX pragma when legacy CJSX pragma used

## [2.2.0]
- Use `React.__spread` instead of `Object.assign`

## Breaking Changes in 1.0

React 0.12 will introduce changes to the way component descriptors are constructed, where the return value of `React.createClass` is not a descriptor factory but simply the component class itself, and descriptors must be created manually using `React.createElement` or by wrapping the component class with `React.createDescriptor`. In preparation for this, coffee-react-transform now outputs calls to `React.createElement` to construct element descriptors from component classes for you, so you won't need to [wrap your classes using `React.createFactory`](https://gist.github.com/sebmarkbage/ae327f2eda03bf165261). However, for this to work you will need to be using at least React 0.11.2, which adds `React.createElement`.

If you want the older style JSX output (which just desugars into function calls) then you need to use the 0.x branch, eg. 0.5.1.
