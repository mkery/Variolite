{Point, Range, TextBuffer} = require 'atom'
VariantsManager = require './variants-manager'
Variant = require './segment-objects/variant'
VariantView = require './segment-objects/variant-view'


module.exports =
class VariantExplorerPane


  constructor: (@manager, @root) ->
    @pane = document.createElement('div')
    @pane.classList.add('atomic-taro_explore-pane')

    @initialize()

  initialize: ->
    @pane.appendChild(@makeTitleDiv())

    variants = @manager.getVariants()
    for v in variants
      varDiv = @makeDivForVariant(v)
      @pane.appendChild(varDiv)

  # Gets the root element
  getElement: ->
    @pane

  getWidth: ->
    $(@pane).width()

  makeTitleDiv: ->
    branchIcon = document.createElement('span')
    branchIcon.classList.add('icon-git-branch')
    titleBox = document.createElement('div')
    titleBox.classList.add('atomic-taro_explore-title-container')
    xIcon = document.createElement('span')
    xIcon.classList.add('icon-x')
    xIcon.classList.add('atomic-taro_explore')
    $ => $(document).on 'click', '.icon-x.atomic-taro_explore', (ev) =>
      @root.toggleExplorerView()
    titleText = document.createElement('span')
    $(titleText).text("Variants")

    titleBox.appendChild(xIcon)
    titleBox.appendChild(branchIcon)
    titleBox.appendChild(titleText)
    titleBox


  makeDivForVariant: (variant) ->
    vModel = variant.getModel()
    varDiv = document.createElement('div')

    lineNoDiv = document.createElement('div')
    lineNoDiv.classList.add('atomic-taro_explore-lineno')
    $(lineNoDiv).text(@getLineNumbers(vModel))
    varDiv.appendChild(lineNoDiv)

    listDiv = document.createElement('ul')
    listDiv.classList.add('list-tree', 'has-collapsable-children')

    currentVarDiv = document.createElement('li')
    currentVarDiv.classList.add('list-nested-item')
    current = document.createElement('span')
    current.classList.add('list-item')
    $(currentVarDiv).html("<span class='icon-primitive-square'></span>"+vModel.getTitle())
    currentVarDiv.appendChild(current)
    listDiv.appendChild(currentVarDiv)

    varDiv.appendChild(listDiv)
    varDiv


  getLineNumbers: (variantModel) ->
    range = variantModel.getMarker().getBufferRange()
    rs = range.start.row
    re = range.end.row
    "lines "+rs+"-"+re
