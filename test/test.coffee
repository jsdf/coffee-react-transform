require('coffee-script').register()
fs = require 'fs'
{exec} = require 'child_process'
coffeeCompile = require('coffee-script').compile

if process.env.DEBUG
  Parser = require '../src/parser'
  serialise = require '../src/serialiser'
  transform = (code, opts) ->
    parseTree = new Parser().parse(code, opts)
    console.log(JSON.stringify(parseTree, null, 2))
    serialise(parseTree)
else
  transform = require '../'

tryTransform = (input, desc) ->
  try
    transformed = transform input
  catch e
    e.message = """
    transform error in testcase: #{desc}

    #{e.stack}

    """
    throw new Error(e.message)

  transformed

tryCompile = (input, desc) ->
  try
    compiled = coffeeCompile input
  catch e
    e.message = """
    compile error in testcase: #{desc}

    #{e.stack}

    """
    throw new Error(e.message)

  compiled

run = ->
  runTestcases 'output', "#{__dirname}/output-testcases.txt"

testTypes =
  # simple testing of string equality of 
  # expected output vs actual output
  'output':
    params: ['desc','input','expected']
    runner: (testcase) ->
      transformed = tryTransform testcase.input, testcase.desc

      compiled = tryCompile transformed, testcase.desc

      console.assert transformed == testcase.expected,
      """

      #{testcase.desc}

      --- input ---
      #{testcase.input}

      --- Expected output ---
      #{testcase.expected}

      --- Actual output ---
      #{transformed}

      """

generateTestcasesParser = (params) ->
  testcaseMatcher = do ->
    paramMatchers = for param in params
      "###{param}[ ]*?\\n([\\s\\S]*?)?\\n"

    ///
    #{paramMatchers.join('')}
    \#\#end
    ///gm

  (input) ->
    while testcase = testcaseMatcher.exec(input)
      output = {}
      for paramContents, index in testcase[1..]
        output[params[index]] = paramContents

      output

runTestcases = (type, filepath) ->
  parseTestcases = generateTestcasesParser(testTypes[type].params)
  testcases = parseTestcases(fs.readFileSync(filepath))

  console.time("#{type} tests passed")

  for testcase in testcases
    # console.log "#{type} #{testcase.desc}"
    testTypes[type].runner(testcase)

  console.timeEnd("#{type} tests passed")

run() # begin


