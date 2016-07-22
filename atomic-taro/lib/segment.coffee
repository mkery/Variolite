


module.exports =
class Segment
  editor: null
  buffer: null
  marker : null
  title : null

  constructor: (mini_editor, marker, title) ->
    @editor = mini_editor
    @buffer = mini_editor.getBuffer()
    @marker = marker
    @title = title

  getEditor: ->
    @editor

  getBuffer: ->
    @buffer

  getMarker: ->
    @marker

  getTitle: ->
    @title
