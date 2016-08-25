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

    @initialize()
    @parentDiv.appendChild(@myContainer)


  getDiv: ->
    @myContainer


  collapse: ->
    $(@nestedTree).slideToggle('slow')


  setVariant: (v) ->
    @varElement.setVariant(v)


  refresh: ->
    @varElement.refresh()

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
    @myContainer.appendChild(listRoot)


  getLineNumbers: () ->
    range = @variant.getModel().getMarker().getBufferRange()
    rs = range.start.row
    re = range.end.row
    "lines "+rs+"-"+re
