{Parser,compileToCS} = require './csx'

console.log 'pathological case of CSX escape inside CSX tag'
ast = new Parser().parse '<Person name={window.isLoggedIn ? window.name : \'\'} />'
console.log JSON.stringify(ast, null, 4)


ast = new Parser().parse """
# @jsx React.DOM 

HelloWorld = React.createClass({
  render: () ->
    return (
      <p>
        Hello, <input type="text" placeholder="Your name here" />!
        It is {this.props.date.toTimeString()}
      </p>
    );
});

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


"""
console.log 'AST:'
console.log JSON.stringify(ast, null, 4)
console.log 'Transformed CSX:'
console.log compileToCS ast