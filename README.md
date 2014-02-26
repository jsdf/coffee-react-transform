### CSX Rewriter

Adds simplistic JSX support for Coffeescript

```coffeescript
rewriter = require './index.coffee'

myJSXInCoffee = """
	<Car 
	doors=4 safety={getSafetyRating()*2} 
	crackedWindscreen = "yep" insurance={ 
	insurancehas() ? 'cool': 'ahh noooo'
	} \n data-yolo='swag\\' checked check=me_out />
	"""

rewriter(myJSXInCoffee)

=> Car({"doors": "4", "safety": (getSafetyRating()*2), "crackedWindscreen": "yep", "insurance": ( insurancehas() ? 'cool': 'ahh noooo' ), "data-yolo": 'swag\\', "checked": true, "check": "me_out"})

```


# Tests

`cake test` or `cake watch:test`