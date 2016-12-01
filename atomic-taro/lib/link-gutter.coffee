{TextEditor} = require 'atom'
{Point, Range} = require 'atom'

module.exports =
class LinkGutter

  constructor: (@editor, @view) ->
    @decorations = []
    @gutter = @editor.addGutter(name: 'taro-link-gutter', priority: 3)
    @makeContextMenu()
    @mark = null
    @currentVariant = null



  addJqueryListeners: ->
    $('atom-text-editor::shadow .gutter').on 'click', '.taro-gutter-add-button', {'gutter': @}, (ev) ->
      ev.stopPropagation()
      gutter = ev.data.gutter
      gutter.showButtons($(this).parent(), ev.pageX, ev.pageY)

    $('atom-text-editor::shadow .gutter').on 'mouseenter', '.taro-connect', (ev) ->
      $(this).children().show()

    $('atom-text-editor::shadow .gutter').on 'mouseleave', '.taro-connect', (ev) ->
      $(this).children().hide()


    $(document).on 'click', '.atomic-taro_link-rmenu-item', {'gutter': @}, (ev) ->
      vari = $(this).data("variant")
      console.log "clicked! "+vari.getModel().getTitle()
      ev.data.gutter.drawLink(vari)

  makeContextMenu: ->
    @rightClickMenu = document.createElement('div')
    @rightClickMenu.classList.add('atomic-taro_output-rmenu')

    var1 = document.createElement('div')
    var1.classList.add('output-rmemu_itemBox')
    name = document.createElement('span')
    $(name).text("link")
    var1.appendChild(name)
    @rightClickMenu.appendChild(var1)
    #@activateSubMenus()


  activateSubMenus: (vari) ->
    $(@rightClickMenu).empty()
    master = @view.getMasterVariant()
    for child in master.getNestedChildren()
      id = child.getModel().getID()
      if id != vari.getModel().getID()
        name = child.getModel().getTitle()
        console.log "var: "+name
        menuItem = document.createElement('div')
        menuItem.classList.add('atomic-taro_output-rmenu')
        menuItem.classList.add('atomic-taro_link-rmenu-item')
        item = document.createElement('div')
        item.classList.add('output-rmemu_itemBox')
        title = document.createElement('span')
        $(title).text(name)
        item.appendChild(title)
        menuItem.appendChild(item)
        $(menuItem).data("variant", child)
        @rightClickMenu.appendChild(menuItem)



  decorateGutter: (marker, vari) ->
    item = document.createElement('div')
    item.classList.add('taro-connect')
    $(item).data("variant", vari)
    addButton = document.createElement('div')
    #@addButton.classList.add('icon-gist-new')
    addButton.classList.add('taro-gutter-add-button')
    $(addButton).html("+")

    $(addButton).hide()
    item.appendChild(addButton)
    @decorations.push @gutter.decorateMarker(marker, type: 'gutter', item: item)


  drawLink: (vari) ->
    rangeA = vari.getModel().getVariantRange()
    rangeB = @currentVariant.getModel().getVariantRange()
    start = rangeA.start
    end = rangeB.end
    if start.row > end.row
      start = rangeB.start
      end = rangeA.end
    marker = @editor.markBufferRange(new Range(start, end))
    item = document.createElement('div')
    item.classList.add('taro-connect-link')
    @decorations.push @gutter.decorateMarker(marker, type: 'gutter', item: item)


  getMenu: =>
    @rightClickMenu


  showButtons: (div, mouseX, mouseY) ->
    if @mark
      @dec.destroy()
      @mark.destroy()
    console.log "Showing button"
    console.log mouseX+", "+mouseY
    vari =  $(div).data("variant")
    @currentVariant = vari
    pos = @editor.getElement().screenPositionForPixelPosition({top: mouseY, left: mouseX})
    bufferPos = @editor.bufferPositionForScreenPosition(pos)
    console.log bufferPos
    @mark = @editor.markScreenPosition(bufferPos)
    @dec = @editor.decorateMarker(@mark, type: 'overlay', item: @rightClickMenu, position: 'tail')
    #vari.getHeader().appendChild(@rightClickMenu)
    #$(@rightClickMenu).offset({left:mouseX, top:mouseY})
    @activateSubMenus(vari)
