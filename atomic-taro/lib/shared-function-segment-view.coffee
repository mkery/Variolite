{Point, Range, TextBuffer} = require 'atom'
Segment = require './segment'
SegmentView = require './segment-view'

'''
A segment type for shared functions. Shared functions are displayed
without some of the UI in normal exploratory blocks.
'''
module.exports =
class SharedFunctionSegmentView extends SegmentView

  addHeaderDiv: (headerContainer) ->
    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')
    boxHeader = document.createElement("div")
    boxHeader.classList.add('atomic-taro_editor-shared-function-name')
    $(boxHeader).text(@segment.getTitle())
    nameContainer.appendChild(boxHeader)
    headerContainer.appendChild(nameContainer)
