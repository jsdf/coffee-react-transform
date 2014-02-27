
# tests
# mainly for regressions, edge cases

transform = require('./csx-transformer').transform

# simple testing of string equality of expected output 
# vs actual output for various csx input
# should catch any regressions in output
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

# start tests
console.time('all tests passed')

testTransformOutput 'self closing tag',
"""<Person />""",
"""Person(null)"""

testTransformOutput 'ambigious tag-like expression',
"""x = a <b > c""",
"""x = a <b > c"""

testTransformOutput 'ambigious tag',
"""x = a <b > c </b>""",
"""x = a React.DOM.b(null, \"\"\"c\"\"\")"""

testTransformOutput 'escaped coffeescript attribute',
"""<Person name={window.isLoggedIn ? window.name : ''} />""",
"""Person({"name": (window.isLoggedIn ? window.name : '')})"""

testTransformOutput 'escaped coffeescript attribute over multiple lines' ,
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

testTransformOutput 'multiple line escaped coffeescript with nested csx',
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

testTransformOutput 'multiline tag attributes with escaped coffeescript',
"""
<Person name={window.isLoggedIn ? window.name : ''} 
loltags='on new line' />
""",
"""
Person({"name": (window.isLoggedIn ? window.name : ''), "loltags": 'on new line'})
"""

testTransformOutput 'example react class with csx, text and escaped coffeescript',
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
    return Nav({"color": "blue"}, (Profile(null, \"\"\"click\"\"\", (Math.random(),Selfclosing({"coolattr": true}))) for i in [start...finish]))
"""

testTransformOutput 'lots of attributes',
"""
<Car doors=4 safety={getSafetyRating()*2} crackedWindscreen = "yep" 
insurance={ insurancehas() ? 'cool': 'ahh noooo'} data-yolo='swag\\' checked check=me_out />
""",
"""
Car({"doors": "4", "safety": (getSafetyRating()*2), "crackedWindscreen": "yep", "insurance": ( insurancehas() ? 'cool': 'ahh noooo'), "data-yolo": 'swag\\', "checked": true, "check": "me_out"})
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
# TODO: support regex containing html
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

testTransformOutput 'escaped js cannot be written within csx',
"""<Person> `i am not js` </Person>""",
"""Person(null, \"\"\"`i am not js`\"\"\")"""

testTransformOutput 'comment cannot be written within csx',
"""<Person>
# i am not a comment
</Person>""",
"""Person(null, \"\"\"# i am not a comment\"\"\")"""

testTransformOutput 'string cannot be written within csx',
"""<Person> "i am not a string" 'nor am i' </Person>""",
"""Person(null, \"\"\""i am not a string" 'nor am i'\"\"\")"""

# end tests
console.timeEnd('all tests passed')
