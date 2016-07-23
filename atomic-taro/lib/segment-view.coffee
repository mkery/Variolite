{Point, Range, TextBuffer} = require 'atom'
Segment = require './segment'

'''
Segment view represents the visual appearance of a Segment, and contains a
Segment object.
'''
module.exports =
class SegmentView
  segment : null
  segmentDiv : null

  constructor: (editor, marker, segmentTitle) ->
    @segment = new Segment(editor, marker, segmentTitle)
    @addSegmentDiv()

  getDiv: ->
    @segmentDiv

  getModel: ->
    @segment

  addSegmentDiv: () ->
    #container for entire block
    @segmentDiv = document.createElement('div')
    @segmentDiv.classList.add('atomic-taro_editor-segment')
    #----------header-------------
    #container for header information like title, meta-data
    headerContainer = document.createElement('div')
    headerContainer.classList.add('atomic-taro_editor-header-box')
    @addHeaderDiv(headerContainer)
    @segmentDiv.appendChild(headerContainer)
    #----------editor-------------
    editorContainer = @addEditorDiv(@segment.getEditor(), @segmentDiv)
    @segmentDiv.appendChild(editorContainer)
    #----------finish
    $(headerContainer).click ->
       $(editorContainer).slideToggle('slow')

  addEditorDiv: (model_editor, blockDiv) ->
    #container for code editor
    editorContainer = document.createElement('div')
    editorContainer.classList.add('atomic-taro_editor-textEditor-box')
    # create an editor element
    #model_editor = atom.workspace.buildTextEditor(buffer: new SegmentedBuffer(text: codeText), grammar: atom.grammars.selectGrammar("file.py"))#filePath: @plainCodeEditor.getPath()))
    model_editor = @segment.getEditor()
    te = model_editor.getElement()
    editorContainer.appendChild(te)
    editorContainer

  addHeaderDiv: (headerContainer) ->
    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')
    boxHeader = document.createElement("div")
    boxHeader.classList.add('atomic-taro_editor-header-name')
    $(boxHeader).text(@segment.getTitle())
    nameContainer.appendChild(boxHeader)
    #add placeholder for data
    dateHeader = document.createElement("div")
    $(dateHeader).text("7/16/19 7:04pm")
    dateHeader.classList.add('atomic-taro_editor-header-date')
    nameContainer.appendChild(dateHeader)
    headerContainer.appendChild(nameContainer)
    #add placeholders for versions and output
    outputBox = document.createElement("div")
    outputBox.classList.add('atomic-taro_editor-header-buttons')
    $(outputBox).text("in/output")
    headerContainer.appendChild(outputBox)
    variantsBox = document.createElement("div")
    variantsBox.classList.add('atomic-taro_editor-header-buttons')
    $(variantsBox).text("variants")
    headerContainer.appendChild(variantsBox)
    pin = document.createElement("span")
    pin.classList.add('icon-pin', 'pinButton')
    headerContainer.appendChild(pin)
