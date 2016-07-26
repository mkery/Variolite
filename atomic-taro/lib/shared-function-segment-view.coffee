{Point, Range, TextBuffer} = require 'atom'
Segment = require './segment'
SegmentView = require './segment-view'

'''
A segment type for shared functions. Shared functions are displayed
without some of the UI in normal exploratory blocks.
'''
module.exports =
class SharedFunctionSegmentView extends SegmentView

  addSegmentDiv: () ->
    #container for entire block
    @segmentDiv = document.createElement('div')
    @segmentDiv.classList.add('atomic-taro_editor-segment')
    #----------header-------------
    #container for header information like title, meta-data
    @headerBar = document.createElement('div')
    @headerBar.classList.add('atomic-taro_editor-header-box')
    @addHeaderDiv(@headerBar)
    # add pinButton
    @addPinButton(@headerBar)
    @segmentDiv.appendChild(@headerBar)
    #----------editor-------------
    editorContainer = @addEditorDiv(@segment.getEditor(), @segmentDiv)
    @segmentDiv.appendChild(editorContainer)
    #----------finish
    $(@headerBar).click ->
       $(editorContainer).slideToggle('slow')

  addHeaderDiv: (headerContainer) ->
    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')
    boxHeader = document.createElement("div")
    boxHeader.classList.add('atomic-taro_editor-shared-function-name')
    $(boxHeader).text(@segment.getTitle())
    nameContainer.appendChild(boxHeader)
    headerContainer.appendChild(nameContainer)
