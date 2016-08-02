{Point, Range, TextBuffer} = require 'atom'
Variant = require './variant'

'''
variant view represents the visual appearance of a variant, and contains a
variant object.
'''
module.exports =
class VariantView

  constructor: (@variantParent, sourceEditor, marker, variantTitle, @divWidth) ->
    # header bar that holds interactive components above text editor
    @headerBar = null
    @footerBar = null
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

    # the variant
    @variant = new Variant(sourceEditor, marker, variantTitle)
    @buildVariantDiv()

  serialize: ->
    #todo add ui
    @variant.serialize()

  deserialize: (state) ->
    console.log "variantS"

  variantSerialize: ->
    @variant.variantSerialize()

  getModel: ->
    @variant

  getFooter: ->
    @footerBar

  getEditorDiv: ->
    @editorDiv

  getOutputsDiv: ->
    @outputDiv

  getHeader: ->
    @headerBar

  setTitle: (t) ->
    $(@nameHeader).text(t)
    @variant.setTitle(t)

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


  buildVariantDiv: () ->
    #----------header-------------
    #container for header information like title, meta-data
    @headerBar = document.createElement('div')
    @headerBar.classList.add('atomic-taro_editor-header-box')
    $(@headerBar).width(@divWidth)
    @addHeaderDiv(@headerBar)
    #add placeholders for versions and output
    @addVariantButtons(@headerBar)
    #@addOutputButton(@headerBar)
    # add pinButton
    #@addPinButton(@headerBar)
    #---------output region
    #@addOutputDiv()
    #@headerBar.appendChild(@outputDiv)

    @footerBar = document.createElement('div')
    @footerBar.classList.add('atomic-taro_editor-footer-box')


  addHeaderDiv: (headerContainer) ->
    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')
    '''if @variantParent
      @rootNameHeader = document.createElement("div")
      @rootNameHeader.classList.add('atomic-taro_editor-header-name')
      $(@rootNameHeader).data("variant", @variant)
      $(@rootNameHeader).text(@variantParent.getRootTitle())'''
    @nameHeader = document.createElement("div")
    @nameHeader.classList.add('atomic-taro_editor-header-name')
    $(@nameHeader).data("variant", @variant)
    $(@nameHeader).text(@variant.getTitle())
    nameContainer.appendChild(@nameHeader)
    #add placeholder for data
    dateHeader = document.createElement("div")
    downIcon = document.createElement("span")
    downIcon.classList.add('icon-chevron-down')
    $(downIcon).click =>
      @variant.collapse()
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
    $(@pinButton).data("variant", @)
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
    $(buttonShow).data("variant", @)
    $(buttonShow).click (ev) =>
      ev.stopPropagation()
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
    $(@outputButton).data("variant", @)
    headerContainer.appendChild(@outputButton)

  addOutputDiv: ->
    @outputDiv = document.createElement("div")
    @outputDiv.classList.add('output-container')
    $(@outputDiv).text("output information")
    $(@outputDiv).hide()
