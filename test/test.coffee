require('coffee-script').register()
fs = require 'fs'
{exec} = require 'child_process'
coffeeCompile = require('coffee-script').compile

require 'colors'
jsdiff = require 'diff'

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

    #{input}

    #{e.stack}

    """
    throw new Error(e.message)

  compiled

run = ->
  runTestcases 'output', "#{__dirname}/output-testcases.txt"

testTypes =
  'output':
    params: ['desc','input','expected']
    runner: (testcase) ->
      transformed = tryTransform testcase.input, testcase.desc

      compiled = tryCompile transformed, testcase.desc

      # simple assertion of string equality of expected output and actual output
      pass = transformed is testcase.expected

      diff = unless pass
        jsdiff.diffChars(testcase.expected, transformed).map((part) ->
          color = (if part.added then "green" else (if part.removed then "red" else "grey"))
          text = part.value
            .replace(/[ ]/g, '█')
            .replace(/\n/g, '␤\n')
          text[color]
        ).join('')

      console.assert pass,
      """

      #{testcase.desc}

      --- input ---
      #{testcase.input}

      --- Expected output ---
      #{testcase.expected}

      --- Actual output ---
      #{transformed}

      --- Diff ---
      #{diff}

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


