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

# simple testing of string equality of 
# expected output vs actual output
testTransformOutput = (description, input, expectedOutput) ->
  transformed = transform input

  console.assert transformed == expectedOutput,
  """

  #{description}

  --- Expected output ---
  #{expectedOutput}

  --- Actual output ---
  #{transformed}

  """

testEval = (description, input) ->
  transformed = transform input

  try
    coffeeEval transformed, coffeeEvalOpts
  catch e
    e.message = """

    #{description}

    --- transform output ---
    #{transformed}

    --- error ---
    #{e.message}
    """
    throw new Error(e.message + '\n' + e.stack )

# start tests
console.time('output tests passed')

testTransformOutput 'self closing tag',
"""<Person />""",
"""Person(null)"""

testTransformOutput 'ambigious tag-like expression',
"""x = a <b > c""",
"""x = a <b > c"""

testTransformOutput 'ambigious tag',
"""x = a <b > c </b>""",
"""x = a React.DOM.b(null, \" c \")"""

testTransformOutput 'escaped coffeescript attribute',
"""<Person name={ if test() then 'yes' else 'no'} />""",
"""Person({"name": ( if test() then 'yes' else 'no')})"""

testTransformOutput 'escaped coffeescript attribute over multiple lines' ,
"""
<Person name={
  if test() 
    'yes'
  else
    'no'
} />
""",
"""
Person({"name": (
  if test() 
    'yes'
  else
    'no'
)})
"""

testTransformOutput 'multiple line escaped coffeescript with nested cjsx',
"""
<Person name={
  if test()
    'yes'
  else
    'no'
}>
{

  for n in a
    <div> a
      asf
      <li xy={"as"}>{ n+1 }<a /> <a /> </li>
    </div>
}

</Person>
""",
"""
Person({"name": (
  if test()
    'yes'
  else
    'no'
)}, 
(

  for n in a
    React.DOM.div(null, \"\"\" a
      asf
\"\"\", React.DOM.li({"xy": ("as")}, ( n+1 ), React.DOM.a(null), \" \", React.DOM.a(null), \" \")
    )
)

)
"""

testTransformOutput 'multiline tag attributes with escaped coffeescript',
"""
<Person name={window.isLoggedIn ? window.name : ''}
loltags='on new line' />
""",
"""
Person({"name": (window.isLoggedIn ? window.name : ''),  \\
"loltags": 'on new line'})
"""

testTransformOutput 'example react class with cjsx, text and escaped coffeescript',
"""
HelloWorld = React.createClass({
  render: () ->
    return (
      <p>
        Hello, <input type="text" placeholder="Your name here" />!
        It is {this.props.date.toTimeString()}
      </p>
    );
});
""",
"""
HelloWorld = React.createClass({
  render: () ->
    return (
      React.DOM.p(null, \"\"\"
        Hello, \"\"\", React.DOM.input({"type": "text", "placeholder": "Your name here"}), \"\"\"!
        It is \"\"\", (this.props.date.toTimeString())
      )
    );
});
"""

testTransformOutput 'more complex output',
"""
setInterval(() ->
  React.renderComponent(
    <HelloWorld date="{new Date()}" />,
    document.getElementById('example')
  );
, 500);

React.createClass
  render: ->
    return <Nav color="blue">
      {<Profile>click{Math.random(),<Selfclosing coolattr />}</Profile> for i in [start...finish]}
    </Nav>
""",
"""
setInterval(() ->
  React.renderComponent(
    HelloWorld({"date": "{new Date()}"}),
    document.getElementById('example')
  );
, 500);

React.createClass
  render: ->
    return Nav({"color": "blue"}, 
      (Profile(null, \"click\", (Math.random(),Selfclosing({"coolattr": true}))) for i in [start...finish])
    )
"""

testTransformOutput 'lots of attributes',
"""
<Person eyes=2 friends={getFriends()} popular = "yes"
active={ if isActive() then 'active' else 'inactive' } data-attr='works' checked check=me_out
/>
""",
"""
Person({"eyes": 2, "friends": (getFriends()), "popular": "yes",  \\
"active": ( if isActive() then 'active' else 'inactive' ), "data-attr": 'works', "checked": true, "check": me_out
})
"""

testTransformOutput 'pragma with alternate dom implementation',
"""
# @cjsx awesome.fun
<div> a
  asf
  <li xy={"as"}>{ n+1 }<a /> <a /> </li>
</div>
""",
"""

awesome.fun.div(null, \"\"\" a
  asf
\"\"\", awesome.fun.li({"xy": ("as")}, ( n+1 ), awesome.fun.a(null), \" \", awesome.fun.a(null), \" \")
)
"""

testTransformOutput 'pragma is case insensitive',
"""
# @cJSX cool
<div> a </div>
""",
"""

cool.div(null, \" a \")
"""

testTransformOutput 'comment',
"""# <Person />""",
"""# <Person />"""

testTransformOutput 'herecomment',
"""
###
<Person />
###
""",
"""
###
<Person />
###
"""

# failing
# TODO: support regex containing html which should not be transformed

# testTransformOutput 'regex',
# """/<Person \/>/""",
# """/<Person \/>/"""

testTransformOutput 'js escaped',
"""`<Person />`""",
"""`<Person />`"""

testTransformOutput 'string single quote',
"""'<Person />'""",
"""'<Person />'"""

testTransformOutput 'string double quote',
'''"<Person />"''',
'''"<Person />"'''

testTransformOutput 'string triple single quote',
"""'''<Person />'''""",
"""'''<Person />'''"""

testTransformOutput 'string triple double quote',
'''"""<Person />"""''',
'''"""<Person />"""'''

testTransformOutput 'escaped js cannot be written within cjsx',
"""<Person> `i am not js` </Person>""",
"""Person(null, \" `i am not js` \")"""

testTransformOutput 'comment cannot be written within cjsx',
"""<Person>
# i am not a comment
</Person>""",
"""Person(null, \"\"\"
# i am not a comment
\"\"\")"""

testTransformOutput 'string cannot be written within cjsx',
"""<Person> "i am not a string" 'nor am i' </Person>""",
"""Person(null, \" "i am not a string" 'nor am i' \")"""

# end tests
console.timeEnd('output tests passed')


console.time('eval tests passed')
testEval 'complex whitespace',
"""
<article name={
  if test()
    'yes'
  else
    'no'
}>
{

  for n in getRange()
    <div> a
      some cool text
      <li class={"as"+1}>{ n+1 }<a /> <a /> </li>
    </div>
}

</article>
"""

testEval 'more complex output',
"""
call(() ->
  React.renderComponent(
    <span date="{new Date()}" />,
    sink('example')
  )
, 500)

React.createClass({
  render: ->
    return <div color="blue">
      {<li>click{  <img coolattr /> } </li> for i in getRange()} 
    </div>
})
"""

testEval 'multiline elements',
"""
  <div>
  <div>
  <div>
  <div>
    <article name={ new Date() } number = 203
     range={getRange()}
    >
    </article>
  </div>
  </div>
  </div>
  </div>
"""
console.timeEnd('eval tests passed')

