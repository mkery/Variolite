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
    #@undoAgent = null

    # header bar that holds interactive components above text editor
    @headerWrapper = document.createElement('div')
    @headerWrapper.classList.add('atomic-taro_editor-header-wrapper')
    @headerBar = document.createElement('div')
    @headerBar.classList.add('atomic-taro_editor-header-box')
    @nestLabelContainer = null
    @collapseIcon = null
    @visibleVersions = []
    @buttonArchive = null

    #footer bar that simply marks the end
    @footerWrapper = document.createElement('div')
    @footerWrapper.classList.add('atomic-taro_editor-footer-wrapper')
    @footerBar = document.createElement('div')
    @footerBar.classList.add('atomic-taro_editor-footer-box')
    @footerWrapper.appendChild(@footerBar)

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
    @explorerGroupElement = null



  deactivate: ->
    @model.getMarker().destroy()



  dissolve: () => # re-add when you can safely undo!
    @headerMarkDecoration.destroy()
    @footerMarkDecoration.destroy()
    @model.dissolve()
    #@explorerGroupElement.dissolve()
    for n in @model.getNested()
      n.dissolve()

    @undoAgent.pushChange({data: {undoSkip: true}, callback: @reinstate})



  reinstate: =>
    @model.reinstate()
    #@explorerGroupElement.reinstate()
    for n in @model.getNested()
      n.reinstate()



  archive: ->
    # No versions showing to archive
    # If just 1 don't bother switching to a another verison
    if @visibleVersions.length < 2
      return

    # make the current version inactive so it's not
    # re-drawn on the version bookmark bar
    c = @model.getCurrentVersion()
    @model.archiveCurrentVerion()

    # Switch to an adjacent version in the version bookmark bar
    for v, index in @visibleVersions
      if v.id == c.id
        if index > 0
          v = @visibleVersions[index - 1]
        else
          v = @visibleVersions[index + 1]
    @switchToVersion(v)

    if @visibleVersions.length < 2
      $(@buttonArchive).hide()


  sortVariants: ->
    @model.sortVariants()


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
    @footerWrapper


  #getWrappedFooter: ->
  #  @versionExplorer.getFooter()

  getOutputsDiv: ->
    @outputDiv

  getHeader: ->
    @headerWrapper


  getExplorerElement: ->
    @explorerGroupElement


  getActiveVersionIDs: ->
    @model.getActiveVersionIDs()


  travelToCommit: (commitId) ->
    $(@headerBar).addClass('historical')
    $(@commitTraveler).addClass('historical')
    $(@footerBar).addClass('historical')
    @hover()
    commit = @model.travelToCommit(commitId)

  backToTheFuture: ->
    $(@headerBar).removeClass('historical')
    $(@commitTraveler).removeClass('historical')
    $(@footerBar).removeClass('historical')
    @model.backToTheFuture()

  #getWrappedHeader: ->
  #  @versionExplorer.getHeader()

  setTitle: (title, version) ->
    @model.setTitle(title, version)
    $(@versionBookmarkBar).empty()
    @addNameBookmarkBar(@versionBookmarkBar)
    #@explorerGroupElement.updateTitle()


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
    $(@activeButton).show()
    $(@historyButton).show()
    $(@branchButton).show()


  unHover: ->
    if @focused
      return
    $(@headerBar).removeClass('active')
    $(@dateHeader).removeClass('active')
    $(@currentVersionName).removeClass('focused')
    $(@footerBar).removeClass('active')
    $(@variantsButton).removeClass('active')
    $(@activeButton).hide()
    $(@historyButton).hide()
    $(@branchButton).hide()


  registerOutput: (data) ->
    @model.registerOutput(data)



  updateVariantWidth: (width) ->
    $(@headerWrapper).width(width)
    if @nestLabelContainer?
      $(@headerBar).width(width - $(@nestLabelContainer).width() - 20 - $(@collapseIcon).width())
    else
      $(@headerBar).width(width - $(@collapseIcon).width() - 5)
    for n in @model.getNested()
      n.updateVariantWidth(width)


  addedNestedVariant: (v, version) ->
    @model.addNested(v)
    v.getModel().setNestedParent([version, @])


  newVersion: ->
    v = @model.newVersion()
    $(@versionBookmarkBar).empty()
    @addNameBookmarkBar(@versionBookmarkBar)
    $(@dateHeader).text(@model.getDate())
    @addVersiontoExplorer(v)


  toggleActive: (v) ->
    @model.toggleActive(v)


  toggleCommitTimeline: () ->
    if $(@commitTraveler).is(":visible")
      $(@commitTraveler).hide()
    else
      commitNum = @model.getCurrentVersion().commits.length
      if commitNum > 0
        $(@commitTraveler).removeClass("textOnly")
        $(@commitSlider).html("")
        $(@commitSlider).slider({
          max: commitNum,
          min: 0,
          value: commitNum,
          slide: (event, ui) =>
            if ui.value == ui.max
              @backToTheFuture()
            else
              @travelToCommit({commitID: ui.value, verID: @model.getCurrentVersion().id})
        })
      else
        $(@commitTraveler).addClass("textOnly")
        $(@commitSlider).html("No commits to show yet!")
      $(@commitTraveler).show()


  switchToVersion: (v, same) ->
    #if same? then same else same = true
    same = @model.isCurrent(v) #and same
    console.log "same: "+same

    np = @model.getNestedParent()
    # switch the highest level first
    if np?
      [p_version, p_variant] = np
      console.log "look up parent "
      console.log p_variant
      p_variant.switchToVersion(p_version, same)
    if same == true
      return # don't switch, this version is current
    console.log "switching version! "+v.title

    @model.switchToVersion(v)
    @switchHeaderToVersion(v)


  switchHeaderToVersion: (v) ->
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


  setExplorerGroup: (elem) ->
    @explorerGroupElement = elem


  addVersiontoExplorer: (v) ->
    #@explorerGroupElement.addVersion(v)


  switchExplorerToVersion: (v) ->
    #@explorerGroupElement.findSwitchVersion(v)


  highlightMultipleVersions: (v) ->
    console.log "highlight!"
    @model.compareToVersion(v)
    $(@versionBookmarkBar).empty()
    $(@activeButton).data("version", v)
    @addNameBookmarkBar(@versionBookmarkBar)
    $(@dateHeader).text(@model.getDate())
    @switchExplorerToVersion(v)


  buildVariantDiv: () ->
    #console.log "Building variant "+@model.getCurrentVersion().title
    #----------header-------------
    width = @root.getWidth()
    $(@headerWrapper).width(width)
    $(@headerWrapper).data('view', @)
    width = @addHeaderWrapperLabel(@headerWrapper)
    $(@headerBar).width(width)
    @addHeaderDiv(@headerBar)
    @headerWrapper.appendChild(@headerBar)
    @headerWrapper.appendChild(@addCommitLine())
    #add placeholders for versions and output
    @addVariantButtons(@headerBar)
    #@addOutputButton(@headerBar)
    # add pinButton
    @addActiveButton(@headerBar)
    @addHistoryButton(@headerBar)
    @addBranchButton(@headerBar)
    #---------output region
    #@addOutputDiv()
    #@headerBar.appendChild(@outputDiv)

    # wrapper div to browse other versions
    #@versionExplorer.addVariantsDiv()
    $(@footerBar).css('margin-left', $(@nestLabelContainer).width() + 20)

    if @model.getNested().length > 0
      for n in @model.getNested()
        if n.rootVersion? == false
          n.buildVariantDiv()


  addHeaderWrapperLabel: (headerContainer) ->
    @collapseIcon = document.createElement("span")
    @collapseIcon.classList.add("icon-chevron-down")
    @collapseIcon.classList.add("taro-collapse-button")
    $(@collapseIcon).click =>
      @model.collapse()
    headerContainer.appendChild(@collapseIcon)

    width = @root.getWidth() - $(@collapseIcon).width()
    nestLabel = @model.generateNestLabel()
    if nestLabel?
      @nestLabelContainer =  document.createElement("span")
      $(@nestLabelContainer).text(nestLabel)
      headerContainer.appendChild(@nestLabelContainer)
      width = width - $(@nestLabelContainer).width() - 20
    else
      width -= 20
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
    @dateHeader.classList.add('atomic-taro_editor-header-date')
    $(@dateHeader).text(@model.getDate())
    headerContainer.appendChild(@dateHeader)
    headerContainer.appendChild(nameContainer)
    #@addActiveButton(headerContainer)
    '''varIcons = document.createElement("span")
    varIcons.classList.add('atomic-taro_editor-header-varIcon')
    $(varIcons).html("<span class='icon-primitive-square'></span><span class='icon-primitive-square active'></span>")
    headerContainer.appendChild(varIcons)'''


  addCommitLine: ->
    @commitTraveler = document.createElement('div')
    @commitTraveler.classList.add('atomic-taro_commit-traveler')
    @commitSlider = document.createElement('div')
    @commitSlider.classList.add('commit-slider')
    @commitTraveler.appendChild(@commitSlider)
    $(@commitTraveler).hide()
    @commitTraveler


  addNameBookmarkBar: (versionBookmarkBar) ->
    current = @model.getCurrentVersion()
    root = @model.getRootVersion()
    singleton = !@model.hasVersions()
    @visibleVersions = [] # reset
    @addVersionBookmark(root, current, versionBookmarkBar, singleton)
    if @visibleVersions.length > 1
      $(@buttonArchive).show()
    else
      $(@buttonArchive).hide()


  addVersionBookmark: (v, current, versionBookmarkBar, singleton) ->
    if v.active == true # don't show a version that is archived
      @visibleVersions.push v
      versionTitle = document.createElement("span")
      versionTitle.classList.add('atomic-taro_editor-header_version-title')
      $(versionTitle).data("version", v)
      $(versionTitle).data("variant", @)

      squareIcon = document.createElement("span")
      #console.log "singleton? "+singleton
      if !singleton
        #$(squareIcon).data("version", v)
        #$(squareIcon).data("variant", @)
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

      if(v.id == current.id)
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

    #regarless if this verison is active, check branches
    for branch in v.branches
      @addVersionBookmark(branch, current, versionBookmarkBar, false)




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
    $(@activeButton).hide()

    #@activeButton = document.createElement("div")
    #@activeButton.classList.add('atomic-taro_editor-active-button')
    headerContainer.appendChild(@activeButton)

  addHistoryButton: (headerContainer) ->
    @historyButton = document.createElement("span")
    @historyButton.classList.add('atomic-taro_commit-history-button')
    @historyButton.classList.add('icon-history')
    $(@historyButton).data("variant", @)
    $(@historyButton).hide()
    headerContainer.appendChild(@historyButton)

  addBranchButton: (headerContainer) ->
    @branchButton = document.createElement("span")
    @branchButton.classList.add('atomic-taro_commit-history-button')
    @branchButton.classList.add('icon-git-branch')
    $(@branchButton).data("variant", @)
    $(@branchButton).hide()
    headerContainer.appendChild(@branchButton)

  addVariantButtons: (headerContainer) ->
    @variantsButton = document.createElement("div")
    @variantsButton.classList.add('atomic-taro_editor-header-buttons')
    @variantsButton.classList.add('variants-button')
    $(@variantsButton).text("variants")
    headerContainer.appendChild(@variantsButton)
    variantsMenu = document.createElement("div")
    variantsMenu.classList.add('variants-hoverMenu')
    $(variantsMenu).hide()
    '''buttonSnapshot = document.createElement("div")
    buttonSnapshot.classList.add('variants-hoverMenu-buttons')
    $(buttonSnapshot).html("<span class='icon icon-repo-create'></span><span class='icon icon-device-camera'></span>")
    variantsMenu.appendChild(buttonSnapshot)'''
    @variantsButton.appendChild(variantsMenu)

    buttonShow = document.createElement("div")
    buttonShow.classList.add('variants-hoverMenu-buttons')
    buttonShow.classList.add('showVariantsButton')
    $(buttonShow).text("show variant panel")
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
    $(buttonAdd).html("<span class='icon icon-repo-create'>new branch</span>")
    $(buttonAdd).click =>
      @newVersion()
      $(variantsMenu).hide()
    variantsMenu.appendChild(buttonAdd)

    @buttonArchive = document.createElement("div")
    @buttonArchive.classList.add('variants-hoverMenu-buttons')
    @buttonArchive.classList.add('archiveVariantButton')
    $(@buttonArchive).html("<span class='icon icon-dash'>archive brach</span>")
    $(@buttonArchive).click =>
      @archive()
      $(variantsMenu).hide()
    variantsMenu.appendChild(@buttonArchive)

    buttonDissolve = document.createElement("div")
    buttonDissolve.classList.add('variants-hoverMenu-buttons')
    buttonDissolve.classList.add('dissolveVariantButton')
    $(buttonDissolve).html("<span class='icon icon-dash'>dissolve variant</span>")
    $(buttonDissolve).click =>
      @dissolve()
      $(variantsMenu).hide()
    variantsMenu.appendChild(buttonDissolve)


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
