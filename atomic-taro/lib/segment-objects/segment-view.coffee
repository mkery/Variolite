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
  # div that contains variant display
  variantBox_forward : null
  variantBox_back: null
  # div that contains the text editor
  editorDiv : null
  # pinned
  pinned : false # in general is the pin button active
  pinnedToTop : false
  pinnedToBottom : false

  constructor: (editor, marker, segmentTitle) ->
    @segment = new Segment(editor, marker, segmentTitle)
    @addSegmentDiv()

  getModel: ->
    @segment

  getDiv: ->
    @segmentDiv

  getEditorDiv: ->
    @editorDiv

  getVariantsDiv_Forward: ->
    @variantBox_forward

  getVariantsDiv_Back: ->
    @variantBox_back

  getOutputsDiv: ->
    @outputDiv

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

  makeIntoInactiveVariant: ->
    @close()
    $(@headerBar).addClass('variants-header-box')



  addSegmentDiv: () ->
    #container for entire block
    @segmentDiv = document.createElement('div')
    @segmentDiv.classList.add('atomic-taro_editor-segment')
    #---------variants upper region
    @addVariantsDiv()
    @segmentDiv.appendChild(@variantBox_forward)
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
    #---------variants lower div
    @segmentDiv.appendChild(@variantBox_back)
    #----------finish
    $(@headerBar).click =>
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

  addVariantHeaderDiv: (headerContainer) ->
    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')
    boxHeader = document.createElement("div")
    boxHeader.classList.add('atomic-taro_editor-header-name')
    $(boxHeader).text(@segment.getTitle()+": \"varaint 1\"")
    nameContainer.appendChild(boxHeader)
    #add placeholder for data
    dateHeader = document.createElement("div")
    $(dateHeader).text("created 7/14/19 5:04pm")
    dateHeader.classList.add('atomic-taro_editor-header-date.variant')
    nameContainer.appendChild(dateHeader)
    headerContainer.appendChild(nameContainer)

  # add a way to pin headers to maintain visibility
  addPinButton: (headerContainer) ->
    pin = document.createElement("span")
    pin.classList.add('icon-pin', 'pinButton')
    $(pin).data("segment", @)
    headerContainer.appendChild(pin)

  addVariantButtons: (headerContainer) ->
    variantsBox = document.createElement("div")
    variantsBox.classList.add('atomic-taro_editor-header-buttons')
    variantsBox.classList.add('variants-button')
    $(variantsBox).text("variants")
    headerContainer.appendChild(variantsBox)
    variantsMenu = document.createElement("div")
    variantsMenu.classList.add('variants-hoverMenu')
    $(variantsMenu).hide()
    buttonSnapshot = document.createElement("div")
    buttonSnapshot.classList.add('variants-hoverMenu-buttons')
    $(buttonSnapshot).html("<span class='icon icon-repo-create'></span><span class='icon icon-device-camera'></span>")
    variantsMenu.appendChild(buttonSnapshot)
    variantsBox.appendChild(variantsMenu)
    buttonShow = document.createElement("div")
    buttonShow.classList.add('variants-hoverMenu-buttons')
    buttonShow.classList.add('showVariantsButton')
    $(buttonShow).text("show")
    $(buttonShow).data("segment", @)
    variantsMenu.appendChild(buttonShow)
    buttonAdd = document.createElement("div")
    buttonAdd.classList.add('variants-hoverMenu-buttons')
    buttonAdd.classList.add('createVariantButton')
    $(buttonAdd).html("<span class='icon icon-repo-create'>create new variant</span>")
    $(buttonAdd).click =>
       @makeIntoInactiveVariant()
    variantsMenu.appendChild(buttonAdd)

  addOutputButton: (headerContainer) ->
    outputBox = document.createElement("div")
    outputBox.classList.add('atomic-taro_editor-header-buttons')
    outputBox.classList.add('output-button')
    $(outputBox).text("in/output")
    $(outputBox).data("segment", @)
    headerContainer.appendChild(outputBox)

  addOutputDiv: ->
    @outputDiv = document.createElement("div")
    @outputDiv.classList.add('output-container')
    $(@outputDiv).text("output information")
    $(@outputDiv).hide()

  addVariantsDiv: ->
    @addVariantsDiv_Back()
    @addVariantsDiv_Forward()

  addVariantsDiv_Forward: ->
    @variantBox_forward = document.createElement("div")
    @variantBox_forward.classList.add('variants-container-forward')
    $(@variantBox_forward).hide()

  addVariantsDiv_Back: ->
    @variantBox_back = document.createElement("div")
    @variantBox_back.classList.add('variants-container-back')

    varHeader = document.createElement("div")
    varHeader.classList.add('variants-header-box')
    @addVariantHeaderDiv(varHeader)
    @addOutputButton(varHeader)
    @variantBox_back.appendChild(varHeader)

    varHeader1 = document.createElement("div")
    varHeader1.classList.add('variants-header-box', 'inactive')
    @addVariantHeaderDiv(varHeader1)
    @addOutputButton(varHeader1)
    @variantBox_back.appendChild(varHeader1)

    varHeader2 = document.createElement("div")
    varHeader2.classList.add('variants-header-box')
    @addVariantHeaderDiv(varHeader2)
    @addOutputButton(varHeader2)
    @variantBox_back.appendChild(varHeader2)
    $(@variantBox_back).hide()
