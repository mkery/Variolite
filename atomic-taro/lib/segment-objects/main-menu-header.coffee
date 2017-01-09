{TextEditor} = require 'atom'
{Point, Range} = require 'atom'
HeaderElement = require './header-element'

module.exports =
class MainMenuHeader extends HeaderElement



  buildHeader: (width) ->
    @headerBar = document.createElement('div')
    @headerBar.classList.add('atomic-taro_main-menu')
    $(@headerBar).width(width)

    @variantButtons = document.createElement('div')
    @variantButtons.classList.add('atomic-taro_main-menu_variantContainer')

    @addRunButton(@headerBar)

    # add version tabs
    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')
    @versionBookmarkBar = document.createElement("div")
    @versionBookmarkBar.classList.add('atomic-taro_editor-header-name')
    $(@versionBookmarkBar).data("variant", @model)
    @addNameBookmarkBar()
    nameContainer.appendChild(@versionBookmarkBar)
    @headerBar.appendChild(nameContainer)
    @headerBar.appendChild(@variantButtons)
    @headerWrapper.appendChild(@headerBar)

    @addJqueryListeners()



  '''
    Specific to main menu, need to connect to atomicTaroView in order
    to trigger package-level events, like running the program.
  '''
  setTaroView: (view) ->
    @taroView = view


  showAlertPane: (commit) ->
    $(@commitAlertLabel).text("commit "+commit.commitID+" on "+commit.date)
    $(@alertPane).show()


  hideAlertPane: ->
    $(@alertPane).slideUp('fast')


  getElement: ->
    #@headerWrapper = document.createElement('div')
    @headerWrapper


  focus: ->
    @addClass('active')
    $(@currentVersionName).addClass('focused')
    $(@variantsButton).addClass('active')


  blur: ->
    @removeClass('active')
    $(@currentVersionName).removeClass('focused')
    $(@variantsButton).removeClass('active')
    $('.icon-primitive-square').removeClass('highlighted')
    $('.atomic-taro_editor-header_version-title').removeClass('highlighted')


  travelStyle: (commit) ->
    @addClass('historical')
    @showAlertPane(commit)


  removeTravelStyle: ->
    @removeClass('historical')
    @hideAlertPane()


  buildAlertPane: ->
    @alertPane = document.createElement('div')
    @alertPane.classList.add('atomic-taro_main-menu_alertBox')
    lockIcon = document.createElement('span')
    lockIcon.classList.add('icon-lock')
    lockIcon.classList.add('atomic-taro_commitLock')

    @commitAlertLabel = document.createElement('span')
    @commitAlertLabel.classList.add('atomic-taro_commitAlertLabel')
    $(@commitAlertLabel).text("commit N on 9/16/16 10:20pm")

    returnButton = document.createElement('span')
    returnButton.classList.add('atomic-taro_commitBackButton')
    returnButton.classList.add(@editorID)
    clockIcon = document.createElement('span')
    clockIcon.classList.add('icon-arrow-left')
    returnButton.appendChild(clockIcon)


    @alertPane.appendChild(returnButton)
    @alertPane.appendChild(lockIcon)
    @alertPane.appendChild(@commitAlertLabel)
    $(@alertPane).hide()
    @headerWrapper.appendChild(@alertPane)


  buildButtons: ->
    @addVariantButtons(@variantButtons)
    @addHistoryButton(@variantButtons)
    @addBranchButton(@variantButtons)
    @branchButton.classList.add('atomic-taro_main-menu_branchIcon')
    @historyButton.classList.add('atomic-taro_main-menu_branchIcon')
    $(@activeButton).show()
    $(@historyButton).show()
    $(@branchButton).show()
    @buildAlertPane()



  addRunButton: (header) ->
    @runIcon = document.createElement('span')
    @runIcon.classList.add('icon-playback-play')
    @runIcon.classList.add('atomic-taro_main-menu_runIcon')
    @runIcon.classList.add(@editorID)
    header.appendChild(@runIcon)



  addVariantButtons: (header) ->
    variantsButton = document.createElement("span")
    variantsButton.classList.add('main-menu_variantButton')
    variantsButton.classList.add('variants-button')
    $(variantsButton).text("variants")
    header.appendChild(variantsButton)

    $(variantsButton).hoverIntent \
      (-> $(this).children('.variants-hoverMenu').slideDown('fast')),\
      (-> $(this).children('.variants-hoverMenu').slideUp('fast'))

    variantsMenu = document.createElement("div")
    variantsMenu.classList.add('variants-hoverMenu')
    $(variantsMenu).hide()
    variantsButton.appendChild(variantsMenu)

    buttonShow = document.createElement("div")
    buttonShow.classList.add('variants-hoverMenu-buttons')
    buttonShow.classList.add('showVariantsButton')
    $(buttonShow).text("show variant panel")
    $(buttonShow).data("variant", @)
    $(buttonShow).click (ev) =>
      ev.stopPropagation()
      @taroView.toggleExplorerView()
      $(variantsMenu).hide()
    variantsMenu.appendChild(buttonShow)

    buttonAdd = document.createElement("div")
    buttonAdd.classList.add('variants-hoverMenu-buttons')
    buttonAdd.classList.add('createVariantButton')
    $(buttonAdd).html("<span class='icon icon-repo-create'>new version</span>")
    $(buttonAdd).click =>
      @view.newVersion()
      $(variantsMenu).hide()
    variantsMenu.appendChild(buttonAdd)


  addNameBookmarkBar: ->
    current = @model.getCurrentVersion()
    root = @model.getRootVersion()
    singleton = !@model.hasVersions()
    if !singleton
      @visibleVersions = [] # reset
      @addVersionBookmark(root, current, singleton)
      if @visibleVersions.length > 1
        $(@buttonArchive).show()
      else
        $(@buttonArchive).hide()
    else
      $(@buttonArchive).hide()


  addJqueryListeners: ->
    # run icon
    $ => $(document).on 'mousedown', '.atomic-taro_main-menu_runIcon'+"."+@editorID, (ev) =>
      $(@runIcon).addClass('click')
      @taroView.runProgram()
      @taroView.showExplorerView()
    $ => $(document).on 'mouseup', '.atomic-taro_main-menu_runIcon'+"."+@editorID, (ev) =>
      $(@runIcon).removeClass('click')

    # commit back button
    $(document).on 'click', '.atomic-taro_commitBackButton', (ev) =>
      @taroView.getTravelAgent().globalBackToFuture(@view)
      $(@alertPane).slideUp('fast')
