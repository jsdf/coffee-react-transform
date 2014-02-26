# CSX Rewriter

Adds simplistic JSX support for Coffeescript so you can write a React component in Coffeescript, with no escaping.

car-component.csx:
```html
<Car doors=4 safety={getSafetyRating()*2}  data-top-down="yep" checked>
	<FrontSeat />
	<BackSeat />
	Which one will I take?
</Car>
```

buildscript.coffee:
```coffeescript
fs = require 'fs'
rewriter = require './index.coffee'

componentInCSX = fs.readFileSync('./car-component.csx', 'utf8')

console.log rewriter(componentInCSX)
```

output:
```coffeescript
Car({"doors": "4", "safety": (getSafetyRating()*2), "data-top-down": "yep", "checked": true}, FrontSeat(null), BackSeat(null), '''Which one will I take?''')
```

### Tests

`cake test` or `cake watch:test`