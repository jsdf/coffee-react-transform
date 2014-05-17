require('coffee-script').register()
fs = require 'fs'
{exec} = require 'child_process'
coffeeEval = require('coffee-script').eval
{transform} = require '../src/transformer'

coffeeEvalOpts =
  sandbox:
    React: require './react' # mock react for tests  
    # stub methods
    sink: ->
    call: (cb) -> cb()
    test: -> true
    testNot: -> false
    getNum: -> 2
    getText: -> "hi"
    getRange: -> [2..11]


run = ->
  runTestcases 'output', "#{__dirname}/output-testcases.txt"
  runTestcases 'eval', "#{__dirname}/eval-testcases.txt"

testTypes =
  # simple testing of string equality of 
  # expected output vs actual output
  'output':
    params: ['desc','input','expected']
    runner: (testcase) ->
      transformed = transform testcase.input

      console.assert transformed == testcase.expected,
      """

      #{testcase.desc}

      --- Expected output ---
      #{testcase.expected}

      --- Actual output ---
      #{transformed}

      """

  # coffee eval transformed output to test output syntax correctness
  'eval': 
    params: ['desc','input']
    runner: (testcase) ->
      transformed = transform testcase.input

      try
        coffeeEval transformed, coffeeEvalOpts
      catch e
        e.message = """

        #{testcase.desc}

        --- transform output ---
        #{transformed}

        --- error ---
        #{e.message}
        """
        throw new Error(e.message + '\n' + e.stack )

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


