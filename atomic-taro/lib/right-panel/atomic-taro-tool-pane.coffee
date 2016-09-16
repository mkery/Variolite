{Point, Range, TextBuffer} = require 'atom'
VariantsManager = require '../variants-manager'
Variant = require '../segment-objects/variant'
VariantView = require '../segment-objects/variant-view'
VariantExplorerPane = require './variant-explorer-pane'
OutputPane = require './output-pane'


module.exports =
class AtomicTaroToolPane

  constructor: (@masterVariant, @programProcessor, @root) ->
    @pane = document.createElement('div')
    @pane.classList.add('atomic-taro_tools-pane')

    @variantExplorer = new VariantExplorerPane(@masterVariant, @root)
    @outputExplorer = new OutputPane(@masterVariant, @programProcessor, @root)

    @resizeRegion = document.createElement('div')
    @resizeRegion.classList.add('atomic-taro_tools-resize-handle')

    @initialize()
    @addListeners()

  initialize: ->
    @pane.appendChild(@variantExplorer.getElement())
    @pane.appendChild(@outputExplorer.getElement())
    @pane.appendChild(@resizeRegion)


  # Gets the root element
  getElement: ->
    @pane

  getWidth: ->
    $(@pane).width()

  addListeners: ->
    $(document).on 'mousedown', '.atomic-taro_tools-resize-handle', (e) => @resizeStarted(e)


  registerOutput: (data, commit) ->
    @outputExplorer.registerOutput(data, commit)


  getVariantPanel: ->
    @variantExplorer

  resizeStarted: =>
    $(document).on('mousemove', @resizeToolView)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resizeToolView)
    $(document).off('mouseup', @resizeStopped)

  resizeToolView: ({pageX, which}) =>
    return @resizeStopped() unless which is 1

    width = $(@pane).outerWidth() + $(@pane).offset().left - pageX
    $(@pane).width(width)
