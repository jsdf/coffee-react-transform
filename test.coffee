
# tests
# mainly for regressions, edge cases

rewrite = require('./csx').rewrite

testRewriteOutput = (description, input, expectedOutput) ->
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

testRewriteOutput 'self closing tag',
"""<Person />""",
"""Person(null)"""

testRewriteOutput 'escaped coffeescript attribute',
"""<Person name={window.isLoggedIn ? window.name : ''} />""",
"""Person({"name": (window.isLoggedIn ? window.name : '')})"""

testRewriteOutput 'escaped coffeescript attribute over multiple lines' ,
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

testRewriteOutput 'multiple line escaped coffeescript with nested csx',
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
    div(null, '''asf''', li({"xy": ("as")}, ( n+1 ), a(null), a(null)))
))
"""

testRewriteOutput 'multiline tag attributes with escaped coffeescript',
"""
<Person name={window.isLoggedIn ? window.name : ''} 
loltags='on new line' />
""",
"""
Person({"name": (window.isLoggedIn ? window.name : ''), "loltags": 'on new line'})
"""

testRewriteOutput 'example react class with csx, text and escaped coffeescript',
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
      p(null, '''Hello,''', input({"type": "text", "placeholder": "Your name here"}), '''!
        It is''', (this.props.date.toTimeString()))
    );
});
"""

testRewriteOutput 'more complex output',
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
    return Nav({"color": "blue"}, (Profile(null, '''click''', (Math.random(),Selfclosing({"coolattr": true}))) for i in [start...finish]))
"""

testRewriteOutput 'lots of attributes',
"""
<Car doors=4 safety={getSafetyRating()*2} crackedWindscreen = "yep" 
insurance={ insurancehas() ? 'cool': 'ahh noooo'} data-yolo='swag\\' checked check=me_out />
""",
"""
Car({"doors": "4", "safety": (getSafetyRating()*2), "crackedWindscreen": "yep", "insurance": ( insurancehas() ? 'cool': 'ahh noooo'), "data-yolo": 'swag\\', "checked": true, "check": "me_out"})
"""

# end tests
console.timeEnd('all tests passed')
