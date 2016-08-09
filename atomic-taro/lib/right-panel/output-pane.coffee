{Point, Range, TextBuffer} = require 'atom'
VariantsManager = require '../variants-manager'
Variant = require '../segment-objects/variant'
VariantView = require '../segment-objects/variant-view'


module.exports =
class OutputPane


  constructor: (@manager, @root) ->
    @pane = document.createElement('div')
    @pane.classList.add('atomic-taro_explore-pane')

    @initialize()

  initialize: ->
    @pane.appendChild(@makeTitleDiv())


  # Gets the root element
  getElement: ->
    @pane

  getWidth: ->
    $(@pane).width()

  makeTitleDiv: ->
    titleBox = document.createElement('div')
    titleBox.classList.add('atomic-taro_explore-title-container')
    titleText = document.createElement('span')
    $(titleText).text("Output")

    titleBox.appendChild(titleText)
    titleBox
