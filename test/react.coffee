# react mock for tests

elements = require '../src/htmlelements'

makeEl = (name) ->
	(children) -> type: name, children: children, render: ->

module.exports =
	createClass: (cl) ->
		(props) -> type: cl, props: props

	renderComponent: (cls) ->
		component = Object.create cls
		component.props = cls.props
		component.render()

	DOM: do ->
		dom = {}
		for name, val of elements
			dom[name] = makeEl name
		dom
