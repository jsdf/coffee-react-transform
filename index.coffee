Parser = require './csx'

ast = new Parser().parse '<Person name={window.isLoggedIn ? window.name : \'\'} yolo="si" />'
console.log JSON.stringify(ast, null, 4)


ast = new Parser().parse """
app = <Nav color="blue"><Profile>click</Profile></Nav>

<Person name={window.isLoggedIn ? window.name : \'\'} yolo="si" />


"""
console.log JSON.stringify(ast, null, 4)