{Point, Range, TextBuffer} = require 'atom'
Segment = require './segment'

'''
Segment view represents the visual appearance of a Segment, and contains a
Segment object.
'''
module.exports =
class SegmentView

  constructor: (@variantParent, editor, marker, segmentTitle) ->
    @segmentDiv = null
    # header bar that holds interactive components above text editor
    @headerBar = null
    @nameHeader = null
    @rootNameHeader = null
    @pinButton = null
    @outputButton = null
    @variantsButton = null
    @variants_showing = false
    # div that contains the text editor
    @editorDiv = null
    # pinned
    @pinned = false # in general is the pin button active
    @pinnedToTop = false
    @pinnedToBottom = false

    # the segment
    @segment = new Segment(editor, marker, segmentTitle)
    @addSegmentDiv()

  serialize: ->
    #todo add ui
    @segment.serialize()

  deserialize: (state) ->
    console.log "SEGMENTS"

  variantSerialize: ->
    @segment.variantSerialize()

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

  setTitle: (t) ->
    $(@nameHeader).text(t)
    @segment.setTitle(t)

  setVariantsShowing: (bool) ->
    @variants_showing = bool

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
    @segmentDiv.appendChild(@editorDiv)

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
    '''if @variantParent
      @rootNameHeader = document.createElement("div")
      @rootNameHeader.classList.add('atomic-taro_editor-header-name')
      $(@rootNameHeader).data("segment", @segment)
      $(@rootNameHeader).text(@variantParent.getRootTitle())'''
    @nameHeader = document.createElement("div")
    @nameHeader.classList.add('atomic-taro_editor-header-name')
    $(@nameHeader).data("segment", @segment)
    $(@nameHeader).text(@segment.getTitle())
    nameContainer.appendChild(@nameHeader)
    #add placeholder for data
    dateHeader = document.createElement("div")
    downIcon = document.createElement("span")
    downIcon.classList.add('icon-chevron-down')
    $(downIcon).click =>
      $(@editorDiv).slideToggle('slow')
    dateHeader.classList.add('atomic-taro_editor-header-date')
    dateHeader.appendChild(downIcon)
    date = document.createElement("span")
    $(date).text($.datepicker.formatDate('yy/mm/dd', new Date()))
    dateHeader.appendChild(date)
    nameContainer.appendChild(dateHeader)
    headerContainer.appendChild(nameContainer)
    varIcons = document.createElement("span")
    varIcons.classList.add('atomic-taro_editor-header-varIcon')
    $(varIcons).html("<span class='icon-primitive-square'></span><span class='icon-primitive-square active'></span>")
    headerContainer.appendChild(varIcons)

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
      if @variants_showing
        @variantParent.closeVariantsDiv()
        @variants_showing = false
      else
        @variantParent.openVariantsDiv()
        @variants_showing = true
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
