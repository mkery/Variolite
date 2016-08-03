{Point, Range, TextBuffer} = require 'atom'
Variant = require './variant'
VersionExplorerView = require './version-explorer-view'

'''
variant view represents the visual appearance of a variant, and contains a
variant object.
'''
module.exports =
class VariantView

  constructor: (sourceEditor, marker, variantTitle, @divWidth) ->
    # header bar that holds interactive components above text editor
    @headerBar = null
    @footerBar = null
    @versionBookmarkBar = null
    @currentVersionName = null
    @dateHeader = null

    # extra buttons on the header bar
    @pinButton = null
    @outputButton = null
    @variantsButton = null
    @variants_showing = false

    @focused = true

    # the variant
    @model = new Variant(sourceEditor, marker, variantTitle)
    @buildVariantDiv()
    # wrapper div to browse other versions
    @versionExplorer = new VersionExplorerView(@)

  deactivate: ->
    @model.getMarker().destroy()

  serialize: ->
    #todo add ui
    @model.serialize()

  deserialize: (state) ->
    @model.deserialize(state)
    $(@versionBookmarkBar).empty()
    @addNameBookmarkBar(@versionBookmarkBar)
    $(@dateHeader).text(@model.getDate())

  variantSerialize: ->
    @model.variantSerialize()

  getModel: ->
    @model

  getMarker: ->
    @model.getMarker()

  getFooter: ->
    @footerBar


  getWrappedFooter: ->
    @versionExplorer.getFooter()

  getOutputsDiv: ->
    @outputDiv

  getHeader: ->
    @headerBar

  getWrappedHeader: ->
    @versionExplorer.getHeader()

  setTitle: (t) ->
    $(@versionBookmarkBar).text(t)
    @model.setTitle(t)

  focus: ->
    @focused = true
    $(@headerBar).addClass('active')
    $(@dateHeader).addClass('active')
    $(@currentVersionName).addClass('focused')

  unFocus: ->
    @focused = false
    $(@headerBar).removeClass('active')
    $(@dateHeader).removeClass('active')
    $(@currentVersionName).removeClass('focused')

  setVariantsShowing: (bool) ->
    @variants_showing = bool

  newVersion: ->
    @model.newVersion()
    $(@versionBookmarkBar).empty()
    @addNameBookmarkBar(@versionBookmarkBar)
    $(@dateHeader).text(@model.getDate())

  switchToVersion: (v) ->
    @model.switchToVersion(v)
    $(@versionBookmarkBar).empty()
    @addNameBookmarkBar(@versionBookmarkBar)
    $(@dateHeader).text(@model.getDate())

  makeNonCurrentVariant: ->
    $(@headerBar).removeClass('activeVariant')
    $(@headerBar).addClass('inactiveVariant')
    $(@pinButton).remove()
    $(@variantsButton).remove()


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
    nameContainer.appendChild(@dateHeader)
    headerContainer.appendChild(nameContainer)
    '''varIcons = document.createElement("span")
    varIcons.classList.add('atomic-taro_editor-header-varIcon')
    $(varIcons).html("<span class='icon-primitive-square'></span><span class='icon-primitive-square active'></span>")
    headerContainer.appendChild(varIcons)'''

  addNameBookmarkBar: (versionBookmarkBar) ->
    current = @model.getCurrentVersion()
    for v in @model.getVersions()
      versionTitle = document.createElement("span")
      versionTitle.classList.add('atomic-taro_editor-header_version-title')
      squareIcon = document.createElement("span")
      $(squareIcon).data("version", v)
      $(squareIcon).data("variant", @)
      squareIcon.classList.add('icon-primitive-square')
      title = document.createElement("span")
      $(title).text(v.title)
      title.classList.add('version-title')
      versionTitle.appendChild(squareIcon)
      versionTitle.appendChild(title)
      versionBookmarkBar.appendChild(versionTitle)

      if(v == current)
        if @focused
          versionTitle.classList.add('focused')
        squareIcon.classList.add('active')
        versionTitle.classList.add('active')
        @currentVersionName = versionTitle




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
        @versionExplorer.closeVariantsDiv()
        @variants_showing = false
      else
        @versionExplorer.openVariantsDiv()
        @variants_showing = true
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
