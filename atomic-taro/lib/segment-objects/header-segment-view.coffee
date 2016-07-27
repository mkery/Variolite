{Point, Range, TextBuffer} = require 'atom'
Segment = require './segment'
SegmentView = require './segment-view'

'''
A header segment view is named after the non-interactive block of code-partition
that goes at the top of a file, for things like import statements.

A header segment is simply a segment without all the interaction in that top bar,
so it can be used for multiple things.
'''
module.exports =
class HeaderSegmentView extends SegmentView

  addSegmentDiv: () ->
    @segmentDiv = document.createElement('div')
    #new_box.classList.add('atomic-taro_header-box')
    model_editor = @segment.getEditor()
    te = model_editor.getElement()
    @segmentDiv.appendChild(te)
