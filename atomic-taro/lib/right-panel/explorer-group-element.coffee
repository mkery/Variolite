{Point, Range, TextBuffer} = require 'atom'
VariantsManager = require '../variants-manager'
Variant = require '../segment-objects/variant'
VariantView = require '../segment-objects/variant-view'
ExplorerVariantElement = require './explorer-variant-element'

module.exports =
class ExplorerGroupElement

  constructor: (@variant, @rootVersion, @parentDiv, @nestedParentElem) ->
    @myContainer = null
    @lineNoDiv = null
    @nestedTree = null
    @varElement = null
    if @nestedParentElem? == false
      @nestedParentElem = @

    @initialize()
    @parentDiv.appendChild(@myContainer)
    @variant?.setExplorerGroup(@)


  getDiv: ->
    @myContainer


  dissolve: ->
    $(@myContainer).html('')


  collapse: ->
    $(@nestedTree).slideToggle('fast')


  setVariant: (v) ->
    @variant = v
    @varElement.setVariant(v)


  focus: ->
    $(@myContainer).find('.atomic-taro_explore_version-label').removeClass('focused')


  updateTitle: ->
    @varElement.updateTitle()


  refresh: ->
    @varElement.refresh()
    @variant.setExplorerGroup(@)


  addVersion: (v) ->
    vElem = new ExplorerVariantElement(@variant, v, @nestedTree, @nestedParentElem)
    vElem.focus()
    $('.atomic-taro_explore_version').removeClass('selected')
    $('.atomic-taro_explore_group_label').removeClass('selected')
    vElem.select()


  renameVersion: (v, title) ->
    # foo


  initialize: ->
    @myContainer = document.createElement('ul')
    @myContainer.classList.add('list-tree')
    @myContainer.classList.add('has-collapsable-children')


    listRoot = document.createElement('li')
    listRoot.classList.add('list-nested-item')
    $(listRoot).data('variantElem', @)

    ver = document.createElement('div')
    ver.classList.add('list-item')
    ver.classList.add('atomic-taro_explore_group_label')
    $(ver).data('variantElem', @)

    @lineNoDiv = document.createElement('span')
    @lineNoDiv.classList.add('atomic-taro_explore-lineno')
    $(@lineNoDiv).html("variant " + @rootVersion.title)
    ver.appendChild(@lineNoDiv)
    listRoot.appendChild(ver)

    @nestedTree = document.createElement('ul')
    @nestedTree.classList.add('list-tree')

    # Now add the root variant to this
    @varElement = new ExplorerVariantElement(@variant, @rootVersion, @nestedTree, @nestedParentElem)

    listRoot.appendChild(@nestedTree)
    if $(@parentDiv).hasClass('list-tree')
      @myContainer = listRoot
    else
      @myContainer.appendChild(listRoot)


  getLineNumbers: () ->
    range = @variant.getModel().getMarker().getBufferRange()
    rs = range.start.row
    re = range.end.row
    "lines "+rs+"-"+re
