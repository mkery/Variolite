{Point, Range, TextBuffer} = require 'atom'
SegmentView = require './segment-view'

'''
Represents a single segment of exploratory code *including* variants of that
code. Thus, this segment contains multiple segments, one for each variant
'''
module.exports =
class ExploratorySegment
  view : null
  currentVariant : null

  constructor: (view, editor, original_buffer, marker, segmentTitle) ->
    @view = view
    first = new SegmentView(view, editor, marker, segmentTitle)
    first.getModel().addChangeListeners(original_buffer)
    @currentVariant = first

  getCurrentVariant: ->
    @currentVariant

  getVariants: ->
    @variants

  newVariant: ->
    currentModel = @currentVariant.getModel()
    text = currentModel.getBuffer().getText()
    marker = currentModel.getMarker()
    title = currentModel.getTitle()+": \"unnamed variant\""
    model_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: text), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
    newVariant = new SegmentView(@view, model_editor, marker, title)
    currentModel.setParent(newVariant)
    newVariant.getModel().setChild(currentModel)
    @currentVariant = newVariant
    newVariant
