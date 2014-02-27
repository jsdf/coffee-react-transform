
# tests
# mainly for regressions, edge cases

rewrite = require('./csx').rewrite

# simple testing of string equality of expected output 
# vs actual output for various csx input
# should catch any regressions in output
testRewriterOutput = (description, input, expectedOutput) ->
  rewritten = rewrite input
  console.assert rewritten == expectedOutput,
  """

  #{description}

  --- Expected output ---
  #{expectedOutput}

  --- Actual output ---
  #{rewritten}

  """

# start tests
console.time('all tests passed')

testRewriterOutput 'self closing tag',
"""<Person />""",
"""Person(null)"""

testRewriterOutput 'ambigious tag-like expression',
"""x = a <b > c""",
"""x = a <b > c"""

testRewriterOutput 'ambigious tag',
"""x = a <b > c </b>""",
"""x = a React.DOM.b(null, \"\"\"c\"\"\")"""

testRewriterOutput 'escaped coffeescript attribute',
"""<Person name={window.isLoggedIn ? window.name : ''} />""",
"""Person({"name": (window.isLoggedIn ? window.name : '')})"""

testRewriterOutput 'escaped coffeescript attribute over multiple lines' ,
"""
<Person name={window.isLoggedIn 
? window.name 
: ''} />
""",
"""
Person({"name": (window.isLoggedIn 
? window.name 
: '')})
"""

testRewriterOutput 'multiple line escaped coffeescript with nested csx',
"""
<Person name={window.isLoggedIn 
? window.name 
: ''}> 
{

  for n in a
    <div>
      asf
      <li xy={"as"}>{ n+1 }<a /> <a /> </li>
    </div>
}

</Person>
""",
"""
Person({"name": (window.isLoggedIn 
? window.name 
: '')}, (

  for n in a
    React.DOM.div(null, \"\"\"asf\"\"\", React.DOM.li({"xy": ("as")}, ( n+1 ), React.DOM.a(null), React.DOM.a(null)))
))
"""

testRewriterOutput 'multiline tag attributes with escaped coffeescript',
"""
<Person name={window.isLoggedIn ? window.name : ''} 
loltags='on new line' />
""",
"""
Person({"name": (window.isLoggedIn ? window.name : ''), "loltags": 'on new line'})
"""

testRewriterOutput 'example react class with csx, text and escaped coffeescript',
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
      React.DOM.p(null, \"\"\"Hello,\"\"\", React.DOM.input({"type": "text", "placeholder": "Your name here"}), \"\"\"!
        It is\"\"\", (this.props.date.toTimeString()))
    );
});
"""

testRewriterOutput 'more complex output',
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
    return Nav({"color": "blue"}, (Profile(null, \"\"\"click\"\"\", (Math.random(),Selfclosing({"coolattr": true}))) for i in [start...finish]))
"""

testRewriterOutput 'lots of attributes',
"""
<Car doors=4 safety={getSafetyRating()*2} crackedWindscreen = "yep" 
insurance={ insurancehas() ? 'cool': 'ahh noooo'} data-yolo='swag\\' checked check=me_out />
""",
"""
Car({"doors": "4", "safety": (getSafetyRating()*2), "crackedWindscreen": "yep", "insurance": ( insurancehas() ? 'cool': 'ahh noooo'), "data-yolo": 'swag\\', "checked": true, "check": "me_out"})
"""

testRewriterOutput 'comment',
"""# <Person />""",
"""# <Person />"""

testRewriterOutput 'herecomment',
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
# TODO: support regex containing html
# testRewriterOutput 'regex',
# """/<Person \/>/""",
# """/<Person \/>/"""

testRewriterOutput 'js escaped',
"""`<Person />`""",
"""`<Person />`"""

testRewriterOutput 'string single quote',
"""'<Person />'""",
"""'<Person />'"""

testRewriterOutput 'string double quote',
'''"<Person />"''',
'''"<Person />"'''

testRewriterOutput 'string triple single quote',
"""'''<Person />'''""",
"""'''<Person />'''"""

testRewriterOutput 'string triple double quote',
'''"""<Person />"""''',
'''"""<Person />"""'''

testRewriterOutput 'js cannot be escaped within csx',
"""<Person> `i am not js` </Person>""",
"""Person(null, \"\"\"`i am not js`\"\"\")"""

testRewriterOutput 'comment cannot be written within csx',
"""<Person>
# i am not a comment
</Person>""",
"""Person(null, \"\"\"# i am not a comment\"\"\")"""

testRewriterOutput 'string cannot be written within csx',
"""<Person> "i am not js" 'nor am i' </Person>""",
"""Person(null, \"\"\""i am not js" 'nor am i'\"\"\")"""

# end tests
console.timeEnd('all tests passed')
