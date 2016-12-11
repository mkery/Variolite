{TextEditor} = require 'atom'
{Point, Range} = require 'atom'
HeaderElement = require './header-element'

module.exports =
class MainMenuHeader extends HeaderElement



  buildHeader: (width) ->
    # alert element
    #@menuContainer = document.createElement('div')
    @menuContainer.classList.add('atomic-taro_editor-header-wrapper')
    $(@menuContainer).width(width)
    $(@menuContainer).data('view', @view)

    @headerBar = document.createElement('div')
    @headerBar.classList.add('atomic-taro_main-menu')
    $(@headerBar).width(width)

    @addRunButton(@headerBar)
    @menuContainer.appendChild(@headerBar)


  showAlertPane: ->
    $(@alertPane).show()


  getElement: ->
    @menuContainer = document.createElement('div')
    @menuContainer


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
    clockIcon = document.createElement('span')
    clockIcon.classList.add('icon-arrow-left')
    returnButton.appendChild(clockIcon)
    $(document).on 'click', '.atomic-taro_commitBackButton', (ev) =>
      @view.backToTheFuture()
      $('.atomic-taro_output_box').removeClass('travel')
      $('.atomic-taro_editor-header-box').removeClass('historical')
      $('.atomic-taro_commit-traveler').removeClass('historical')
      $('.atomic-taro_editor-footer-box').removeClass('historical')
      $(@alertPane).slideUp('fast')

    @alertPane.appendChild(returnButton)
    @alertPane.appendChild(lockIcon)
    @alertPane.appendChild(@commitAlertLabel)
    $(@alertPane).hide()
    @menuContainer.appendChild(@alertPane)


  buildButtons: ->
    @addVariantButtons(@headerBar)
    @addHistoryButton(@headerBar)
    @addBranchButton(@headerBar)
    @branchButton.classList.add('atomic-taro_main-menu_branchIcon')
    @historyButton.classList.add('atomic-taro_main-menu_branchIcon')



  addRunButton: (header) ->
    @runIcon = document.createElement('span')
    @runIcon.classList.add('icon-playback-play')
    @runIcon.classList.add('atomic-taro_main-menu_runIcon')
    header.appendChild(@runIcon)

    $ => $(document).on 'mousedown', '.atomic-taro_main-menu_runIcon', (ev) =>
      $(@runIcon).addClass('click')
      @atomicTaroView.runProgram()
      @atomicTaroView.showExplorerView()
    $ => $(document).on 'mouseup', '.atomic-taro_main-menu_runIcon', (ev) =>
      $(@runIcon).removeClass('click')


  addVariantButtons: (header) ->
    variantsButton = document.createElement("span")
    variantsButton.classList.add('main-menu_variantButton')
    variantsButton.classList.add('variants-button')
    $(variantsButton).text("variants")
    header.appendChild(variantsButton)
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
      @atomicTaroView.toggleExplorerView()
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
