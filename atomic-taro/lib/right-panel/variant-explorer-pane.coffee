{Point, Range, TextBuffer} = require 'atom'
VariantsManager = require '../variants-manager'
Variant = require '../segment-objects/variant'
VariantView = require '../segment-objects/variant-view'


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
      v.setExplorerGroup(varDiv)
      @pane.appendChild(varDiv)

    @addListeners()

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

    v = vModel.getRootVersion()
    if v.children.length > 0
      listDiv.appendChild @makeVersionWithChildren(variant, v)
    else
      listDiv.appendChild @makeVersionNoKids(variant, v)

    varDiv.appendChild(listDiv)
    varDiv

  makeVersionWithChildren: (variant, version) ->
    nestedListDiv = document.createElement('li')
    nestedListDiv.classList.add('list-nested-item')
    nestedListDiv.classList.add('atomic-taro_explore_version')
    $(nestedListDiv).data('version', version)
    $(nestedListDiv).data('variant', variant)

    ver = document.createElement('div')
    ver.classList.add('list-item')

    label = document.createElement('span')
    label.classList.add('atomic-taro_explore_version-label')
    label.classList.add('icon-git-commit')
    if version.title == variant.getModel().getCurrentVersion().title
      label.classList.add('focused')
    $(label).html(version.title)
    ver.appendChild(label)
    nestedListDiv.appendChild(ver)

    # give the version-view a reference for this div so that
    # it can update the title or which version is focused
    #variant.setExplorerDivForVersion(version, label)
    label.classList.add(version.title)

    nestedTree = document.createElement('ul')
    nestedTree.classList.add('list-tree')
    nestedListDiv.appendChild(nestedTree)

    for v in version.children
      if v.children.length > 0
        nestedTree.appendChild @makeVersionWithChildren(variant, v)
      else
        nestedTree.appendChild @makeVersionNoKids(variant, v)
    nestedListDiv

  makeVersionNoKids: (variant, version) ->
    ver = document.createElement('li')
    ver.classList.add('list-item')
    ver.classList.add('atomic-taro_explore_version')
    $(ver).data('version', version)
    $(ver).data('variant', variant)

    label = document.createElement('span')
    label.classList.add('atomic-taro_explore_version-label')
    label.classList.add('icon-git-commit')
    if version.title == variant.getModel().getCurrentVersion().title
      label.classList.add('focused')
    $(label).html(version.title)
    ver.appendChild(label)

    # give the version-view a reference for this div so that
    # it can update the title or which version is focused
    #variant.setExplorerDivForVersion(version, label)
    # label.classList.add(version.title)
    ver


  addListeners: ->
    $(document).on 'click', '.atomic-taro_explore_version', (ev) ->
      $('.atomic-taro_explore_version').removeClass('selected')
      $(this).addClass('selected')
      version = $(this).data('version')
      variant = $(this).data('variant')
      variant.switchToVersion(version)
      ev.stopPropagation()



  getLineNumbers: (variantModel) ->
    range = variantModel.getMarker().getBufferRange()
    rs = range.start.row
    re = range.end.row
    "lines "+rs+"-"+re
