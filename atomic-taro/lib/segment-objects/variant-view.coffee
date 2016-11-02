{Point, Range, TextBuffer} = require 'atom'
Variant = require './variant-model'
CommitLine = require './commit-line'
BranchMap = require './branch-map'

'''
variant view represents the visual appearance of a variant, and contains a
variant object.
'''
'''
  TODO
    - a way to archive variants
    - ditching the variant explorer?
    - Commit line, duplicating ticks?
    - deactivate
    - serialize UI state?
    - date appearing correctly
    - should output be shown locally?
'''
module.exports =
class VariantView


  constructor: (@sourceEditor, marker, variantTitle, @root, @undoAgent, @provenanceAgent) ->
    # the variant
    @model = new Variant(@, sourceEditor, marker, variantTitle, @undoAgent, @provenanceAgent)
    @initialize()


  '''
    Alternative constructor. Used in the senario where variant box has an unitialized
    nested variant box in a version that was not loaded at startup. Meaning, it wasn't
    showing annotations in the code, since it wasn't the current version at startup, so
    it's not built until later. Returns a new variant box given save data and the current
    parent variant box view @.
  '''
  makeNewFromJson: (json) ->
    variantView = new VariantView(@sourceEditor, null, "", @root, @undoAgent)
    variantView.getModel().deserialize(json)
    variantView


  '''
    Shared by both constructors, sets up global div variables but does not build all
    components until later when the save data is loaded.
  '''
  initialize:  ->
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

    @commitLine = null
    @branchMap = null

    @focused = false

    # wrapper div to browse other versions
    @explorerGroupElement = null #TODO not used


  '''
    TODO used?
  '''
  deactivate: ->
    @model.getMarker().destroy()


  '''
    Dissolves the variant box, returning whatever is currently in the box down to plain
    code sitting flat in the file. Removes all variant box divs.
  '''
  dissolve: () => # re-add when you can safely undo!
    @headerMarkDecoration.destroy()
    @footerMarkDecoration.destroy()
    @model.dissolve()
    #@explorerGroupElement.dissolve() TODO
    for n in @model.getNested()
      n.dissolve()

    @undoAgent.pushChange({data: {undoSkip: true}, callback: @reinstate})


  '''
    Reverse of @dissolve. A way to undo a dissolve action on this variant box.
  '''
  reinstate: =>
    @model.reinstate()
    #@explorerGroupElement.reinstate()
    for n in @model.getNested()
      n.reinstate()


  '''
    TODO. Removes the currenty active version of this variant box from the header bar.
    This means that version still exists in the commit tree but cannot be interacted with.
  '''
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


  '''
    Used ???
  '''
  sortVariants: ->
    @model.sortVariants()


  '''
    Saves the state of the variant box into a json format so that it can be reactivated
    when the tool is closed and opened again later.
  '''
  serialize: ->
    #TODO add ui
    @model.serialize()

  '''
    Takes JSON formatted save data and updates the variant box to reflect that saved state
  '''
  deserialize: (state) ->
    @model.deserialize(state)
    '''$(@versionBookmarkBar).empty()
    @addNameBookmarkBar(@versionBookmarkBar)
    $(@dateHeader).text(@model.getDate())'''


  #???
  # variantSerialize: ->
  #   @model.variantSerialize()


  '''
    Get the model associated with this view; the data associated with the divs of this
    variant box.
  '''
  getModel: ->
    @model


  '''
    Returns the text editor marker that marks the range in the editor controlled by
    this variant box.
  '''
  getMarker: ->
    @model.getMarker()


  '''
    Returns the title of the currently viewed version of this variant box.
  '''
  getTitle: ->
    @model.getTitle()


  '''
    Returns the div element for the footer
  '''
  getFooter: ->
    @footerWrapper #TODO is the wrapper needed?


  # ???
  # getOutputsDiv: ->
  #   @outputDiv

  '''
    Returns the div element that displays the header of this variant box
  '''
  getHeader: ->
    @headerWrapper


  '''
    TODO ???
  '''
  getExplorerElement: ->
    @explorerGroupElement


  '''
    Gets the IDs of all versions actively selected in this variant box.
    ??? Presumably for linked editing.
  '''
  getActiveVersionIDs: ->
    @model.getActiveVersionIDs()


  '''
    Begins the process of traveling to a specific commit in this variant box.
    Changes the appearance of the header and footer to give some visual indication
    that we care time traveling. Then starts the model in the actual text manipulation
    needed for traveling.
  '''
  travelToCommit: (commitId) ->
    $(@headerBar).addClass('historical')
    @commitLine.addClass('historical')
    @branchMap.addClass('historical')
    $(@footerBar).addClass('historical')
    @hover()
    commit = @model.travelToCommit(commitId)


  '''
    Changes the appearance of the header to reflect returning to the most contemporary
    commit. Starts the model actually returning back to this commit.
  '''
  backToTheFuture: ->
    $(@headerBar).removeClass('historical')
    @commitLine.removeClass('historical')
    @branchMap.removeClass('historical')
    $(@footerBar).removeClass('historical')
    @model.backToTheFuture()


  '''
    From the GUI the user can change the title of this version. Sends the new title
    back to the model to change this in the data. Also updates the display.
  '''
  setTitle: (title, version) ->
    @model.setTitle(title, version)
    $(@versionBookmarkBar).empty()
    @addNameBookmarkBar()
    #@explorerGroupElement.updateTitle()


  '''
    Sets the text editor marker associated with the header div. Needed for
    initialization and for re-adding variant boxes.
  '''
  setHeaderMarker: (hm) ->
    @model.setHeaderMarker(hm)


  '''
    Returns the text editor marker associated with the header div.
  '''
  getHeaderMarker: ->
    @model.getHeaderMarker()


  '''
    A Decoration is an Atom object that attatches a particular text editor
    display to a given marker. We store the decoration here that decorates the
    text in the variant box range with the variant header div.
  '''
  setHeaderMarkerDecoration: (decoration) ->
    @headerMarkDecoration = decoration


  '''
    Remove the decoration from the code. Used for removing and adding variant boxes.
    Removes the div of the header.
  '''
  destroyHeaderMarkerDecoration: ->
    @headerMarkDecoration.destroy()


  '''
    A Decoration is an Atom object that attatches a particular text editor
    display to a given marker. We store the decoration here that decorates the
    text in the variant box range with the variant footer div.
  '''
  setFooterMarkerDecoration: (decoration) ->
    @footerMarkDecoration = decoration


  '''
    Remove the decoration from the code. Used for removing and adding variant boxes.
    Removes the div of the footer.
  '''
  destroyFooterMarkerDecoration: ->
    @footerMarkDecoration.destroy()


  '''
    The user has placed their cursor in the range of this variant box, so update the
    display to highlight the UI as active.
  '''
  focus: () ->
    @focused = true
    @hover()


  '''
    The user has removed their cursor from the range of this variant box, so update the
    display to not-highlight the UI.
  '''
  unFocus: ->
    @focused = false
    for n in @model.getNested()
      n.unFocus()
    @unHover()
    @model.clearHighlights()
    $('.icon-primitive-square').removeClass('highlighted')
    $('.atomic-taro_editor-header_version-title').removeClass('highlighted')


  '''
    Returns if the UI state is focused, meaning the cursor is in the range of this box.
  '''
  isFocused: ->
    @focused


  '''
    Set UI to highlighted active.
  '''
  hover: ->
    $(@headerBar).addClass('active')
    $(@dateHeader).addClass('active')
    $(@currentVersionName).addClass('focused')
    $(@footerBar).addClass('active')
    $(@variantsButton).addClass('active')
    $(@activeButton).show()
    $(@historyButton).show()
    $(@branchButton).show()


  '''
    Set UI to not-highlighted inactive.
  '''
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


  '''
    When the user's code is run, associate the output with a commit of this variant box.
  '''
  registerOutput: (data) ->
    @model.registerOutput(data)


  '''
    Handle resize of the width.
  '''
  updateVariantWidth: (width) ->
    $(@headerWrapper).width(width)
    if @nestLabelContainer?
      $(@headerBar).width(width - $(@nestLabelContainer).width() - 20 - $(@collapseIcon).width())
    else
      $(@headerBar).width(width - $(@collapseIcon).width() - 5)
    @branchMap.updateWidth(width)
    @commitLine.updateWidth(width)
    for n in @model.getNested()
      n.updateVariantWidth(width)


  '''
    Attatches a new nested variant to this parent variant box.
  '''
  addedNestedVariant: (v, version) ->
    @model.addNested(v)
    v.getModel().setNestedParent([version, @])


  '''
    Adds a new version to this variant box.
  '''
  newVersion: ->
    v = @model.newVersion()
    $(@versionBookmarkBar).empty()
    @addNameBookmarkBar()
    $(@dateHeader).text(@model.getDate())
    @addVersiontoExplorer(v)


  '''
    Toggles the code as commented or uncommented.
  '''
  toggleActive: (v) ->
    @model.toggleActive(v)



  '''
    Switch between versions. ???
  '''
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


  '''
    Update the highlighting in the header to reflect the change in active version.
  '''
  switchHeaderToVersion: (v) ->
    $(@versionBookmarkBar).empty()
    $(@activeButton).data("version", v)
    @addNameBookmarkBar()
    $(@dateHeader).text(@model.getDate())
    @switchExplorerToVersion(v)


  '''
    Update the highlighting to show that a version is no longer an active one.
  '''
  makeNonCurrentVariant: ->
    $(@headerBar).removeClass('activeVariant')
    $(@headerBar).addClass('inactiveVariant')
    $(@pinButton).remove()
    $(@variantsButton).remove()


  # ???
  setExplorerGroup: (elem) ->
    @explorerGroupElement = elem


  # ???
  addVersiontoExplorer: (v) ->
    #@explorerGroupElement.addVersion(v)


  # ???
  switchExplorerToVersion: (v) ->
    #@explorerGroupElement.findSwitchVersion(v)


  '''
    TODO for selecting multiple versions.
  '''
  highlightMultipleVersions: (v) ->
    console.log "highlight!"
    @model.compareToVersion(v)
    $(@versionBookmarkBar).empty()
    $(@activeButton).data("version", v)
    @addNameBookmarkBar()
    $(@dateHeader).text(@model.getDate())
    @switchExplorerToVersion(v)


  '''
    On initialization, once all saved data in loaded into the model, finally build the
    UI for this variant box.
  '''
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
    # commit line
    @commitLine = new CommitLine(@, @model)
    @headerWrapper.appendChild(@commitLine.getElement())
    # branch map
    @branchMap = new BranchMap(@, @model)
    @headerWrapper.appendChild(@branchMap.getElement())
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


  '''
    The header wrapper contains the collapseIcon and also labels to indicate if a
    variant box is nested within another one.
  '''
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
    @addNameBookmarkBar()
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



  addNameBookmarkBar: ->
    current = @model.getCurrentVersion()
    root = @model.getRootVersion()
    singleton = !@model.hasVersions()
    @visibleVersions = [] # reset
    @addVersionBookmark(root, current, singleton)
    if @visibleVersions.length > 1
      $(@buttonArchive).show()
    else
      $(@buttonArchive).hide()


  addVersionBookmark: (v, current, singleton) ->
    if v.getActive() == true # don't show a version that is archived
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
      $(title).text(v.getTitle())
      title.classList.add('version-title')
      title.classList.add('native-key-bindings')
      $(title).data("variant", @)
      $(title).data("version", v)
      versionTitle.appendChild(title)
      xIcon = document.createElement("span")
      xIcon.classList.add('icon-x')
      xIcon.classList.add('atomic-taro_editor-header_x')
      $(xIcon).data("variant", @)
      versionTitle.appendChild(xIcon)
      $(xIcon).hide()
      @versionBookmarkBar.appendChild(versionTitle)

      if(v.getID() == current?.id)
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
      @addVersionBookmark(branch, current, false)




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
    $(@historyButton).data("commitLine", @commitLine)
    $(@historyButton).hide()
    headerContainer.appendChild(@historyButton)

  addBranchButton: (headerContainer) ->
    @branchButton = document.createElement("span")
    @branchButton.classList.add('atomic-taro_commit-branch-button')
    @branchButton.classList.add('icon-git-branch')
    $(@branchButton).data("branchMap", @branchMap)
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
