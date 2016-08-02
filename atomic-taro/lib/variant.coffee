{Point, Range, TextBuffer} = require 'atom'

'''
Represents a single variant of exploratory code.
'''
module.exports =
class Variant

  constructor: (@sourceEditor, @marker, @title, @elder = null, @children = []) ->
    @copied = false

  serialize: ->
    title: @title

  variantSerialize: ->#todo capture elders
    title : @title
    #text : @buffer.getText()
    #elder: if @elder then @fullySerialize(@elder) else null
    children: if (@children.length > 0) then (child.variantSerialize() for child in @children) else null

  fullySerialize: (variant) ->
    title : variant.getTitle()
    text : variant.getBuffer().getText()

  getMarker: ->
    @marker

  getTitle: ->
    @title

  setTitle: (title) ->
    @title = title

  setElder: (parent) ->
    @elder = parent

  addChild: (child) ->
    console.log @title+" am getting a new child"
    @children.push child

  getCopied: ->
    @copied

  getChildren: ->
    console.log @title+" have N children "+@children.length
    @children

  setCopied: (bool) ->
    @copied = bool

  collapse: ->
    console.log "collaping variant"
    @sourceEditor.setSelectedBufferRange(@marker.getBufferRange())
    @sourceEditor.foldSelectedLines()
