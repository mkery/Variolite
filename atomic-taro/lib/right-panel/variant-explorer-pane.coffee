{Point, Range, TextBuffer} = require 'atom'
VariantsManager = require '../variants-manager'
Variant = require '../segment-objects/variant'
VariantView = require '../segment-objects/variant-view'
ExplorerVariantElement = require './explorer-variant-element'
ExplorerGroupElement = require './explorer-group-element'


module.exports =
class VariantExplorerPane


  constructor: (@manager, @root) ->
    @pane = document.createElement('div')
    @pane.classList.add('atomic-taro_explore-pane')
    @rootVariants = []
    @initialize()


  initialize: ->
    @pane.appendChild(@makeTitleDiv())

    variants = @manager.getVariants()
    for v in variants
      groupV = new ExplorerGroupElement(v, v.getModel().getRootVersion(), @pane)

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


  addListeners: ->
    $(document).on 'click', '.atomic-taro_explore_version-label', (ev) ->
      $('.atomic-taro_explore_version').removeClass('selected')
      $('.atomic-taro_explore_group_label').removeClass('selected')
      $(this).closest('.atomic-taro_explore_version').addClass('selected')
      variantElem = $(this).data('variantElem')
      variantElem.switchToVersion()
      ev.stopPropagation()

    $(document).on 'click', '.atomic-taro_explore_group_label', (ev) ->
      $('.atomic-taro_explore_version-label').removeClass('selected')
      $('.atomic-taro_explore_group_label').removeClass('selected')
      $(this).addClass('selected')
      variantElem = $(this).data('variantElem')
      variantElem.collapse()
      ev.stopPropagation()
