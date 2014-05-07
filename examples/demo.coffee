
{Parser, serialise, transform} = require '../lib/transformer'

coffeeCompile = require('coffee-script').compile

fs = require 'fs'

start = new Date()

parseTree = new Parser().parse(fs.readFileSync('./car.coffee', 'utf8'))

console.log 'Parse tree:'
console.log JSON.stringify(parseTree, null, 4)
console.log 'Transformed to coffee:'
coffeescriptCode = serialise parseTree
console.log coffeescriptCode
console.log 'Compiled to JS:'
console.log(coffeeCompile(coffeescriptCode))

end = new Date()

console.log "done in #{end - start}ms"

