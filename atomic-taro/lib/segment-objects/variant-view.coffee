{Point, Range, TextBuffer} = require 'atom'
Variant = require './variant'

'''
variant view represents the visual appearance of a variant, and contains a
variant object.
'''
module.exports =
class VariantView


  constructor: (@sourceEditor, marker, variantTitle, @root, @undoAgent) ->
    # the variant
    @model = new Variant(@, sourceEditor, marker, variantTitle, @undoAgent)
    @initialize()


  makeNewFromJson: (json) ->
    variantView = new VariantView(@sourceEditor, null, "", @root, @undoAgent)
    variantView.getModel().deserialize(json)
    variantView


  initialize:  ->
    @undoAgent = null

    # header bar that holds interactive components above text editor
    @headerWrapper = document.createElement('div')
    @headerWrapper.classList.add('atomic-taro_editor-header-wrapper')
    @headerBar = document.createElement('div')
    @headerBar.classList.add('atomic-taro_editor-header-box')
    @nestLabelContainer = null

    #footer bar that simply marks the end
    @footerBar = document.createElement('div')
    @footerBar.classList.add('atomic-taro_editor-footer-box')

    #must be built later
    @versionBookmarkBar = null
    @currentVersionName = null
    @dateHeader = null

    # extra buttons on the header bar
    @pinButton = null
    @activeButton = null
    @outputButton = null
    @variantsButton = null

    @focused = false

    # wrapper div to browse other versions
    #@versionExplorer = new VersionExplorerView(@)
    @explorerDiv = null


  deactivate: ->
    @model.getMarker().destroy()

  serialize: ->
    #todo add ui
    @model.serialize()

  deserialize: (state) ->
    @model.deserialize(state)
    '''$(@versionBookmarkBar).empty()
    @addNameBookmarkBar(@versionBookmarkBar)
    $(@dateHeader).text(@model.getDate())'''


  variantSerialize: ->
    @model.variantSerialize()


  getModel: ->
    @model


  getMarker: ->
    @model.getMarker()


  getTitle: ->
    @model.getTitle()


  getFooter: ->
    @footerBar


  #getWrappedFooter: ->
  #  @versionExplorer.getFooter()

  getOutputsDiv: ->
    @outputDiv

  getHeader: ->
    @headerWrapper

  #getWrappedHeader: ->
  #  @versionExplorer.getHeader()

  setTitle: (title, version) ->
    @model.setTitle(title, version)
    $(@versionBookmarkBar).empty()
    @addNameBookmarkBar(@versionBookmarkBar)


  setHeaderMarker: (hm) ->
    @model.setHeaderMarker(hm)


  getHeaderMarker: ->
    @model.getHeaderMarker()


  setHeaderMarkerDecoration: (decoration) ->
    @headerMarkDecoration = decoration


  destroyHeaderMarkerDecoration: ->
    @headerMarkDecoration.destroy()


  setFooterMarkerDecoration: (decoration) ->
    @footerMarkDecoration = decoration


  destroyFooterMarkerDecoration: ->
    @footerMarkDecoration.destroy()


  focus: (cursorPosition) ->
    @focused = true
    @hover()


  unFocus: ->
    @focused = false
    for n in @model.getNested()
      n.unFocus()
    @unHover()
    @model.clearHighlights()
    $('.icon-primitive-square').removeClass('highlighted')
    $('.atomic-taro_editor-header_version-title').removeClass('highlighted')


  isFocused: ->
    @focused


  hover: ->
    $(@headerBar).addClass('active')
    $(@dateHeader).addClass('active')
    $(@currentVersionName).addClass('focused')
    $(@footerBar).addClass('active')
    $(@variantsButton).addClass('active')


  unHover: ->
    if @focused
      return
    $(@headerBar).removeClass('active')
    $(@dateHeader).removeClass('active')
    $(@currentVersionName).removeClass('focused')
    $(@footerBar).removeClass('active')
    $(@variantsButton).removeClass('active')


  updateVariantWidth: (width) ->
    $(@headerWrapper).width(width)
    if @nestLabelContainer?
      $(@headerBar).width(width - $(@nestLabelContainer).width() - 20)
    else
      $(@headerBar).width(width)
    for n in @model.getNested()
      n.updateVariantWidth(width)

  addedNestedVariant: (v, version) ->
    @model.addNested(v)
    v.getModel().setNestedParent([version, @])

  newVersion: ->
    @model.newVersion()
    $(@versionBookmarkBar).empty()
    @addNameBookmarkBar(@versionBookmarkBar)
    $(@dateHeader).text(@model.getDate())

  toggleActive: (v) ->
    @model.toggleActive(v)

  switchToVersion: (v) ->
    @model.switchToVersion(v)
    $(@versionBookmarkBar).empty()
    $(@activeButton).data("version", v)
    @addNameBookmarkBar(@versionBookmarkBar)
    $(@dateHeader).text(@model.getDate())
    @switchExplorerToVersion(v)


  makeNonCurrentVariant: ->
    $(@headerBar).removeClass('activeVariant')
    $(@headerBar).addClass('inactiveVariant')
    $(@pinButton).remove()
    $(@variantsButton).remove()


  setExplorerGroup: (div) ->
    @explorerDiv = div


  switchExplorerToVersion: (v) ->
    $(@explorerDiv).find('.atomic-taro_explore_version-label').removeClass('focused')
    $('.'+v.title).addClass('focused')


  highlightMultipleVersions: (v) ->
    console.log "highlight!"
    @model.compareToVersion(v)
    $(@versionBookmarkBar).empty()
    $(@activeButton).data("version", v)
    @addNameBookmarkBar(@versionBookmarkBar)
    $(@dateHeader).text(@model.getDate())
    @switchExplorerToVersion(v)


  buildVariantDiv: () ->
    #----------header-------------
    width = @root.getWidth()
    $(@headerWrapper).width(width)
    $(@headerBar).data('view', @)
    width = @addHeaderWrapperLabel(@headerWrapper)
    $(@headerBar).width(width)
    @addHeaderDiv(@headerBar)
    @headerWrapper.appendChild(@headerBar)
    #add placeholders for versions and output
    @addVariantButtons(@headerBar)
    #@addOutputButton(@headerBar)
    # add pinButton
    @addActiveButton(@headerBar)
    #---------output region
    #@addOutputDiv()
    #@headerBar.appendChild(@outputDiv)

    # wrapper div to browse other versions
    #@versionExplorer.addVariantsDiv()

    if @model.getNested().length > 0
      for n in @model.getNested()
        if n.rootVersion? == false
          n.buildVariantDiv()


  addHeaderWrapperLabel: (headerContainer) ->
    width = @root.getWidth()
    nestLabel = @model.generateNestLabel()
    if nestLabel?
      @nestLabelContainer =  document.createElement("span")
      $(@nestLabelContainer).text(nestLabel)
      headerContainer.appendChild(@nestLabelContainer)
      width = width - $(@nestLabelContainer).width() - 20
    width


  addHeaderDiv: (headerContainer) ->
    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')

    @versionBookmarkBar = document.createElement("div")
    @versionBookmarkBar.classList.add('atomic-taro_editor-header-name')
    $(@versionBookmarkBar).data("variant", @model)
    @addNameBookmarkBar(@versionBookmarkBar)
    nameContainer.appendChild(@versionBookmarkBar)
    #add placeholder for data
    @dateHeader = document.createElement("div")
    downIcon = document.createElement("span")
    downIcon.classList.add('icon-chevron-down')
    $(downIcon).click =>
      @model.collapse()
    @dateHeader.classList.add('atomic-taro_editor-header-date')
    @dateHeader.appendChild(downIcon)
    $(@dateHeader).text(@model.getDate())
    headerContainer.appendChild(@dateHeader)
    headerContainer.appendChild(nameContainer)
    #@addActiveButton(headerContainer)
    '''varIcons = document.createElement("span")
    varIcons.classList.add('atomic-taro_editor-header-varIcon')
    $(varIcons).html("<span class='icon-primitive-square'></span><span class='icon-primitive-square active'></span>")
    headerContainer.appendChild(varIcons)'''

  addNameBookmarkBar: (versionBookmarkBar) ->
    current = @model.getCurrentVersion()
    root = @model.getRootVersion()
    singleton = !@model.hasVersions()
    @addVersionBookmark(root, current, versionBookmarkBar, singleton)


  addVersionBookmark: (v, current, versionBookmarkBar, singleton) ->
    versionTitle = document.createElement("span")
    versionTitle.classList.add('atomic-taro_editor-header_version-title')
    squareIcon = document.createElement("span")
    #console.log "singleton? "+singleton
    if !singleton
      $(squareIcon).data("version", v)
      $(squareIcon).data("variant", @)
      squareIcon.classList.add('icon-primitive-square')
      versionTitle.appendChild(squareIcon)
    title = document.createElement("span")
    $(title).text(v.title)
    title.classList.add('version-title')
    title.classList.add('native-key-bindings')
    $(title).data("variant", @)
    $(title).data("version", v)
    versionTitle.appendChild(title)
    versionBookmarkBar.appendChild(versionTitle)

    if(v.title == current.title)
      if @focused
        versionTitle.classList.add('focused')
      squareIcon.classList.add('active')
      versionTitle.classList.add('active')
      @currentVersionName = versionTitle

    if(@model.isHighlighted(v))
      if @focused
        versionTitle.classList.add('focused')
      squareIcon.classList.add('highlighted')
      versionTitle.classList.add('highlighted')

    for child in v.children
      @addVersionBookmark(child, current, versionBookmarkBar, false)




  # add a way to pin headers to maintain visibility
  addPinButton: (headerContainer) ->
    @pinButton = document.createElement("span")
    @pinButton.classList.add('icon-pin', 'pinButton')
    $(@pinButton).data("variant", @)
    headerContainer.appendChild(@pinButton)

  addActiveButton: (headerContainer) ->
    @activeButton = document.createElement("span")
    @activeButton.classList.add('atomic-taro_editor-active-button')
    $(@activeButton).html("<span>#</span>")
    $(@activeButton).data("variant", @)

    #@activeButton = document.createElement("div")
    #@activeButton.classList.add('atomic-taro_editor-active-button')
    headerContainer.appendChild(@activeButton)

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
      @root.toggleExplorerView()
      $(variantsMenu).hide()

    variantsMenu.appendChild(buttonShow)
    buttonAdd = document.createElement("div")
    buttonAdd.classList.add('variants-hoverMenu-buttons')
    buttonAdd.classList.add('createVariantButton')
    $(buttonAdd).html("<span class='icon icon-repo-create'>create new variant</span>")
    $(buttonAdd).click =>
      @newVersion()
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
