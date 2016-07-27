{Point, Range, TextBuffer} = require 'atom'
Segment = require './segment'

'''
Segment view represents the visual appearance of a Segment, and contains a
Segment object.
'''
module.exports =
class SegmentView
  # the class that manages all variants of this segment
  variantParent : null
  # the segment
  segment : null
  segmentDiv : null
  # header bar that holds interactive components above text editor
  headerBar : null
  pinButton : null
  outputButton : null
  variantsButton : null
  # div that contains the text editor
  editorDiv : null
  # pinned
  pinned : false # in general is the pin button active
  pinnedToTop : false
  pinnedToBottom : false

  constructor: (variantParent, editor, marker, segmentTitle) ->
    @variantParent = variantParent
    @segment = new Segment(editor, marker, segmentTitle)
    @addSegmentDiv()

  getModel: ->
    @segment

  getDiv: ->
    @segmentDiv

  getEditorDiv: ->
    @editorDiv

  getOutputsDiv: ->
    @outputDiv

  getHeader: ->
    @headerBar

  makeNonCurrentVariant: ->
    $(@headerBar).removeClass('activeVariant')
    $(@headerBar).addClass('inactiveVariant')
    $(@editorDiv).addClass('inactiveVariant')
    $(@pinButton).remove()
    $(@variantsButton).remove()

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

  pinToTop: (scrollTopDiv, scrollPos) ->
    header = $(@headerBar)
    header.data("scrollPos", scrollPos)
    scrollTopDiv.appendChild(@headerBar)
    @pinnedToTop = true
    @pinned = true

  pinToBottom: (scrollBotDiv, scrollPos) ->
    header = $(@headerBar)
    header.data("scrollPos", scrollPos)
    scrollBotDiv.appendChild(@headerBar)
    @pinnedToBottom = true
    @pinned = true

  isPinnedToTop: ->
    @pinnedToTop

  isPinnedToBottom: ->
    @pinnedToBottom

  unPinFromTop: (scrollTopDiv) ->
    $(scrollTopDiv).removeChild(@headerBar)
    @pinnedToTop = false

  unPinFromBottom: (scrollBotDiv) ->
    $(scrollBotDiv).removeChild(@headerBar)
    @pinnedToBottom = false

  close: ->
    $(@editorDiv).slideUp('slow')


  addSegmentDiv: () ->
    #container for entire block
    @segmentDiv = document.createElement('div')
    @segmentDiv.classList.add('atomic-taro_editor-segment')
    #----------header-------------
    #container for header information like title, meta-data
    @headerBar = document.createElement('div')
    @headerBar.classList.add('atomic-taro_editor-header-box')
    @addHeaderDiv(@headerBar)
    #add placeholders for versions and output
    @addVariantButtons(@headerBar)
    @addOutputButton(@headerBar)
    # add pinButton
    @addPinButton(@headerBar)
    @segmentDiv.appendChild(@headerBar)
    #---------output region
    @addOutputDiv()
    @segmentDiv.appendChild(@outputDiv)
    #----------editor-------------
    @addEditorDiv(@segment.getEditor(), @segmentDiv)
    $(@editorDiv).hide()
    @segmentDiv.appendChild(@editorDiv)
    #----------finish
    $(document).on 'click', @headerBar, =>
       $(@editorDiv).slideToggle('slow')

  addEditorDiv: (model_editor, blockDiv) ->
    #container for code editor
    @editorDiv = document.createElement('div')
    @editorDiv.classList.add('atomic-taro_editor-textEditor-box')
    # create an editor element
    #model_editor = atom.workspace.buildTextEditor(buffer: new SegmentedBuffer(text: codeText), grammar: atom.grammars.selectGrammar("file.py"))#filePath: @plainCodeEditor.getPath()))
    model_editor = @segment.getEditor()
    te = model_editor.getElement()
    @editorDiv.appendChild(te)

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

  # add a way to pin headers to maintain visibility
  addPinButton: (headerContainer) ->
    @pinButton = document.createElement("span")
    @pinButton.classList.add('icon-pin', 'pinButton')
    $(@pinButton).data("segment", @)
    headerContainer.appendChild(@pinButton)

  addVariantButtons: (headerContainer) ->
    @variantsButton = document.createElement("div")
    @variantsButton.classList.add('atomic-taro_editor-header-buttons')
    @variantsButton.classList.add('variants-button')
    $(@variantsButton).text("variants")
    headerContainer.appendChild(@variantsButton)
    variantsMenu = document.createElement("div")
    variantsMenu.classList.add('variants-hoverMenu')
    $(variantsMenu).hide()
    buttonSnapshot = document.createElement("div")
    buttonSnapshot.classList.add('variants-hoverMenu-buttons')
    $(buttonSnapshot).html("<span class='icon icon-repo-create'></span><span class='icon icon-device-camera'></span>")
    variantsMenu.appendChild(buttonSnapshot)
    @variantsButton.appendChild(variantsMenu)
    buttonShow = document.createElement("div")
    buttonShow.classList.add('variants-hoverMenu-buttons')
    buttonShow.classList.add('showVariantsButton')
    $(buttonShow).text("show")
    $(buttonShow).data("segment", @)
    $(buttonShow).click (ev) =>
      ev.stopPropagation()
      $(@segmentDiv).toggleClass('variant')
      $(@headerBar).toggleClass('activeVariant')
      #$(@editorDiv).toggleClass('activeVariant')
      @variantParent.openVariantsDiv()
    variantsMenu.appendChild(buttonShow)
    buttonAdd = document.createElement("div")
    buttonAdd.classList.add('variants-hoverMenu-buttons')
    buttonAdd.classList.add('createVariantButton')
    $(buttonAdd).html("<span class='icon icon-repo-create'>create new variant</span>")
    $(buttonAdd).click =>
      @variantParent.newVariant()
    variantsMenu.appendChild(buttonAdd)

  addOutputButton: (headerContainer) ->
    @outputButton = document.createElement("div")
    @outputButton.classList.add('atomic-taro_editor-header-buttons')
    @outputButton.classList.add('output-button')
    $(@outputButton).text("in/output")
    $(@outputButton).data("segment", @)
    headerContainer.appendChild(@outputButton)

  addOutputDiv: ->
    @outputDiv = document.createElement("div")
    @outputDiv.classList.add('output-container')
    $(@outputDiv).text("output information")
    $(@outputDiv).hide()
