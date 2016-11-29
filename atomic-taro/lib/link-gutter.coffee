{TextEditor} = require 'atom'
{Point, Range} = require 'atom'

module.exports =
class LinkGutter

  constructor: (@editor, @view) ->
    @decorations = []
    @gutter = @editor.addGutter(name: 'taro-link-gutter', priority: 3)
    @addButton = document.createElement('div')
    #@addButton.classList.add('icon-gist-new')
    @addButton.classList.add('taro-gutter-add-button')
    $(@addButton).html("+")
    @makeContextMenu()
    #@addButton.appendChild(@rightClickMenu)
    $(@addButton).click (ev) =>
      console.log "Add clicked! "+ev.pageX
      $(@rightClickMenu).offset({left:ev.pageX,top:ev.pageY})
      ev.stopPropagation()



  addJqueryListeners: ->
    $('atom-text-editor::shadow .gutter').on 'mouseenter', '.taro-connect', {'gutter': @}, (ev) ->
      gutter = ev.data.gutter
      gutter.showButtons(this)

    #$('atom-text-editor::shadow .gutter').on 'mouseleave', '.taro-connect', (ev) ->
    #  $(this).empty()

  makeContextMenu: ->
    @rightClickMenu = document.createElement('div')
    @rightClickMenu.classList.add('atomic-taro_output-rmenu')

    var1 = document.createElement('div')
    var1.classList.add('output-rmemu_itemBox')
    name = document.createElement('span')
    $(name).text("travel to commit")
    var1.appendChild(name)
    @rightClickMenu.appendChild(var1)


  decorateGutter: (marker, vari) ->
    item = document.createElement('div')
    item.classList.add('taro-connect')
    $(item).data("variant", vari)
    @decorations.push @gutter.decorateMarker(marker, type: 'gutter', item: item)


  showButtons: (div) ->
    console.log "Showing button"
    console.log div
    vari =  $(div).data("variant")
    vari.getHeader().appendChild(@rightClickMenu)
    div.appendChild(@addButton)
