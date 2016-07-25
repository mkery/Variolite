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
  # header bar that holds interactive components above text editor
  headerBar : null
  # pinned
  pinned : false # in general is the pin button active
  pinnedToTop : false
  pinnedToBottom : false
  repinTop : false
  repinBottom : false

  constructor: (editor, marker, segmentTitle) ->
    @segment = new Segment(editor, marker, segmentTitle)
    @addSegmentDiv()

  getModel: ->
    @segment

  getDiv: ->
    @segmentDiv

  getHeader: ->
    @headerBar


  pin: ->
    @pinned = true

  isPinned: ->
    @pinned

  unPin: ->
    console.log "unpinned!!"
    @pinned = false
    if @pinnedToTop
      @unPinFromTop()
    else
      @unPinFromBottom()

  pinToTop: (offset_top, scrollPos) ->
    header = $(@headerBar)
    header.data("scrollPos", scrollPos)
    header.addClass('pinned')
    header.css({ top: offset_top+"px", width: header.parent().width()+"px"})
    @pinnedToTop = true
    @repinTop = false
    @pinned = true

  pinToBottom: (offset_bottom, scrollPos) ->
    console.log "bottom is " + offset_bottom + " and scroll " + scrollPos
    header = $(@headerBar)
    header.data("scrollPos", scrollPos)
    header.addClass('pinned')
    header.css({top: offset_bottom+"px", width: header.parent().width()+"px"})
    @pinnedToBottom = true
    @repinBottom = false
    @pinned = true

  isPinnedToTop: ->
    @pinnedToTop

  isPinnedToBottom: ->
    @pinnedToBottom

  resetPinning: ->
    if @pinnedToTop
      @repinTop = true
    else
      @repinBottom = true

  isResetPinTop: ->
    @repinTop

  resetPinTop: (offset_top, scrollPos) ->
    header = $(@headerBar)
    header.css({ top: offset_top+"px", width: header.parent().width()+"px"})
    @repinTop = false

  isResetPinBottom: ->
    @repinBottom

  resetPinBottom: (offset_bottom, scrollPos) ->
    header = $(@headerBar)
    header.css({top: offset_bottom+"px", width: header.parent().width()+"px"})
    @repinBottom = false

  unPinFromTop: ->
    header = $(@headerBar)
    header.removeClass('pinned')
    header.css({top: "auto;"})
    @pinnedToTop = false
    @repinTop = false

  unPinFromBottom: ->
    header = $(@headerBar)
    header.removeClass('pinned')
    header.css({top: "auto;"})
    @pinnedToBottom = false
    @repinBottom = false


  addSegmentDiv: () ->
    #container for entire block
    @segmentDiv = document.createElement('div')
    @segmentDiv.classList.add('atomic-taro_editor-segment')
    #----------header-------------
    #container for header information like title, meta-data
    @headerBar = document.createElement('div')
    @headerBar.classList.add('atomic-taro_editor-header-box')
    @addHeaderDiv(@headerBar)
    @segmentDiv.appendChild(@headerBar)
    #----------editor-------------
    editorContainer = @addEditorDiv(@segment.getEditor(), @segmentDiv)
    @segmentDiv.appendChild(editorContainer)
    #----------finish
    $(@headerBar).click ->
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
    $(pin).data("segment", @)
    headerContainer.appendChild(pin)
