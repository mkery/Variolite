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
    xIcon.classList.add('text-smaller')
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

    versions = vModel.getVersions()
    v = versions[0]
    if v.children.length > 0
      listDiv.appendChild @makeVersionWithChildren(v)
    else
      listDiv.appendChild @makeVersionNoKids(v)

    varDiv.appendChild(listDiv)
    varDiv

  makeVersionWithChildren: (version) ->
    nestedListDiv = document.createElement('li')
    nestedListDiv.classList.add('list-nested-item')

    ver = document.createElement('div')
    ver.classList.add('list-item')
    $(ver).html("<span class='icon-git-commit'></span>"+version.title)
    nestedListDiv.appendChild(ver)

    nestedTree = document.createElement('ul')
    nestedTree.classList.add('list-tree')
    nestedListDiv.appendChild(nestedTree)

    for v in version.children
      if v.children.length > 0
        nestedTree.appendChild @makeVersionWithChildren(v)
      else
        nestedTree.appendChild @makeVersionNoKids(v)
    nestedListDiv

  makeVersionNoKids: (version) ->
    ver = document.createElement('li')
    ver.classList.add('list-item')
    $(ver).html("<span class='icon-git-commit'></span>"+version.title)
    ver


  getLineNumbers: (variantModel) ->
    range = variantModel.getMarker().getBufferRange()
    rs = range.start.row
    re = range.end.row
    "lines "+rs+"-"+re
