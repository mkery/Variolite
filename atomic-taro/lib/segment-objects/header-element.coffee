{Point, Range, TextBuffer} = require 'atom'
Variant = require './variant-model'



module.exports =
class HeaderElement


  constructor: () ->
    # header bar that holds interactive components above text editor
    @verticalWrapper = document.createElement('div')
    @headerWrapper = document.createElement('div')
    @headerBar = document.createElement('div')
    @nestLabelContainer = null
    @collapseIcon = null
    @visibleVersions = []
    @buttonArchive = null
    @editorID = null

    #must be built later
    @versionBookmarkBar = null
    @currentVersionName = null

    # extra buttons on the header bar
    @activeButton = null
    @variantsButton = null

    @focused = false


  setModel: (model) ->
    @model = model


  setView: (view) ->
    @view = view


  setEditorID: (id) ->
    @editorID = id
    #@getElement().classList.add(id)


  buildHeader: (width) ->
    console.log "building header"
    # build wrapper
    @verticalWrapper.classList.add('atomic-taro_editor-vertical-wrapper')
    @headerWrapper.classList.add('atomic-taro_editor-header-wrapper')
    $(@headerWrapper).width(width)
    $(@headerWrapper).data('view', @view)
    #width = @buildWrapperLabel(@headerWrapper, width)

    # build main header bar
    @headerBar.classList.add('atomic-taro_editor-header-box')
    $(@headerBar).width(width)
    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')

    # add version tabs
    @versionBookmarkBar = document.createElement("div")
    @versionBookmarkBar.classList.add('atomic-taro_editor-header-name')
    $(@versionBookmarkBar).data("variant", @model)
    @addNameBookmarkBar()
    nameContainer.appendChild(@versionBookmarkBar)
    @headerBar.appendChild(nameContainer)
    @headerWrapper.appendChild(@headerBar)
    @verticalWrapper.appendChild(@headerWrapper)
    #$(@headerBar).hide()

  '''
    The header wrapper contains the collapseIcon and also labels to indicate if a
    variant box is nested within another one.
  '''
  buildWrapperLabel: (headerContainer) ->
    # @collapseIcon = document.createElement("span")
    # @collapseIcon.classList.add("icon-chevron-down")
    # @collapseIcon.classList.add("taro-collapse-button")
    # $(@collapseIcon).click =>
    #   @model.collapse()
    # headerContainer.appendChild(@collapseIcon)

    # width = width - $(@collapseIcon).width()
    nestLabel = @model.generateNestLabel()
    if nestLabel?
      @nestLabelContainer =  document.createElement("span")
      $(@nestLabelContainer).text(nestLabel)
      headerContainer.appendChild(@nestLabelContainer)
      #width = width - $(@nestLabelContainer).width() - 20
    # else
    #   width -= 20
    # width



  buildButtons: ->
    @addVariantButtons(@headerBar)
    @addActiveButton(@headerBar)
    @addHistoryButton(@headerBar)
    @addBranchButton(@headerBar)


  getElement: ->
    @verticalWrapper


  appendDiv: (elem) ->
    @getElement().appendChild(elem)


  addClass: (klass) ->
    $(@headerBar).addClass(klass)


  travelStyle: (commit) ->
    @addClass('historical')


  removeClass: (klass) ->
    $(@headerBar).removeClass(klass)


  removeTravelStyle: ->
    @removeClass('historical')


  focus: ->
    @addClass('active')
    #$(@headerBar).slideDown('fast')
    $(@currentVersionName).addClass('focused')
    $(@variantsButton).addClass('active')
    $(@activeButton).show()
    $(@historyButton).show()
    $(@branchButton).show()


  blur: ->
    @removeClass('active')
    $(@currentVersionName).removeClass('focused')
    $(@variantsButton).removeClass('active')
    $(@activeButton).hide()
    $(@historyButton).hide()
    $(@branchButton).hide()
    $('.icon-primitive-square').removeClass('highlighted')
    $('.atomic-taro_editor-header_version-title').removeClass('highlighted')
    #$(@headerBar).slideUp('fast')

  '''
    TODO ????? WHAT ????
    Update the highlighting to show that a version is no longer an active one.
  '''
  makeNonCurrentVariant: ->
    $(@headerBar).removeClass('activeVariant')
    $(@headerBar).addClass('inactiveVariant')
    $(@variantsButton).remove()


  getNextVisibleVersion: (current) ->
    # If just 1 don't bother switching to a another verison
    if @visibleVersions.length < 2
      $(@buttonArchive).hide()
      return current

    # Switch to an adjacent version in the version bookmark bar
    for v, index in @visibleVersions
      if v.getID() == current.getID()
        if index > 0
          v = @visibleVersions[index - 1]
        else
          v = @visibleVersions[index + 1]
    return v




  update: ->
    $(@versionBookmarkBar).empty()
    @addNameBookmarkBar()


  '''
    Update the highlighting in the header to reflect the change in active version.
  '''
  switchToVersion: (v) ->
    $(@activeButton).data("version", v)
    @update()



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
      $(versionTitle).data("variant", @view)

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
      $(title).data("variant", @view)
      $(title).data("version", v)
      versionTitle.appendChild(title)
      xIcon = document.createElement("span")
      xIcon.classList.add('icon-x')
      xIcon.classList.add('atomic-taro_editor-header_x')
      $(xIcon).data("variant", @view)
      versionTitle.appendChild(xIcon)
      $(xIcon).css('visibility', 'hidden')
      @versionBookmarkBar.appendChild(versionTitle)

      if(v.getID() == current?.id)
        if @focused
          versionTitle.classList.add('focused')
        squareIcon.classList.add('active')
        versionTitle.classList.add('active')
        #$(versionTitle).children('.atomic-taro_editor-header_x').show()
        @currentVersionName = versionTitle

      $(squareIcon).removeClass('highlighted')
      $(versionTitle).removeClass('highlighted')
      if(@model.isMultiSelected(v))
        if @focused
          versionTitle.classList.add('focused')
        squareIcon.classList.add('highlighted')
        versionTitle.classList.add('highlighted')

    #regarless if this verison is active, check branches
    for branch in v.branches
      @addVersionBookmark(branch, current, false)



  addActiveButton: (headerContainer) ->
    @activeButton = document.createElement("span")
    @activeButton.classList.add('atomic-taro_editor-active-button')
    $(@activeButton).html("<span>#</span>")
    $(@activeButton).data("variant", @view)
    $(@activeButton).hide()

    #@activeButton = document.createElement("div")
    #@activeButton.classList.add('atomic-taro_editor-active-button')
    headerContainer.appendChild(@activeButton)

  addHistoryButton: (headerContainer) ->
    @historyButton = document.createElement("span")
    @historyButton.classList.add('atomic-taro_commit-history-button')
    @historyButton.classList.add('icon-history')
    @historyButton.classList.add(@editorID)
    $(@historyButton).data("commitLine", @view.getCommitLine())
    $(@historyButton).hide()
    headerContainer.appendChild(@historyButton)

  addBranchButton: (headerContainer) ->
    @branchButton = document.createElement("span")
    @branchButton.classList.add('atomic-taro_commit-branch-button')
    @branchButton.classList.add('icon-git-branch')
    @branchButton.classList.add(@editorID)
    $(@branchButton).data("branchMap", @view.getBranchMap())
    $(@branchButton).hide()
    headerContainer.appendChild(@branchButton)

  addVariantButtons: (headerContainer) ->
    @variantsButton = document.createElement("div")
    @variantsButton.classList.add('atomic-taro_editor-header-buttons')
    @variantsButton.classList.add('variants-button')
    @variantsButton.classList.add(@editorID)
    $(@variantsButton).text("variants")
    headerContainer.appendChild(@variantsButton)

    $(@variantsButton).hoverIntent \
      (-> $(this).children('.variants-hoverMenu').slideDown('fast')),\
      (-> $(this).children('.variants-hoverMenu').slideUp('fast'))

    variantsMenu = document.createElement("div")
    variantsMenu.classList.add('variants-hoverMenu')
    $(variantsMenu).hide()
    @variantsButton.appendChild(variantsMenu)


    buttonAdd = document.createElement("div")
    buttonAdd.classList.add('variants-hoverMenu-buttons')
    buttonAdd.classList.add('createVariantButton')
    $(buttonAdd).html("<span class='icon icon-repo-create'>new branch</span>")
    $(buttonAdd).click =>
      @view.newVersion()
      $(variantsMenu).hide()
      @view.getBranchMap().redraw()
    variantsMenu.appendChild(buttonAdd)

    @buttonArchive = document.createElement("div")
    @buttonArchive.classList.add('variants-hoverMenu-buttons')
    @buttonArchive.classList.add('archiveVariantButton')
    $(@buttonArchive).html("<span class='icon icon-dash'>archive branch</span>")
    $(@buttonArchive).click =>
      @view.archive()
      $(variantsMenu).hide()
      @view.getBranchMap().redraw()
    variantsMenu.appendChild(@buttonArchive)

    buttonDissolve = document.createElement("div")
    buttonDissolve.classList.add('variants-hoverMenu-buttons')
    buttonDissolve.classList.add('dissolveVariantButton')
    $(buttonDissolve).html("<span class='icon icon-dash'>dissolve variant</span>")
    $(buttonDissolve).click =>
      @view.dissolve()
      $(variantsMenu).hide()
    variantsMenu.appendChild(buttonDissolve)
