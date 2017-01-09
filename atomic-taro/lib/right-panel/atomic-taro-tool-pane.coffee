{View, Point, Range, TextBuffer} = require 'atom'
Variant = require '../segment-objects/variant-model'
VariantView = require '../segment-objects/variant-view'
OutputPane = require './output-pane'


module.exports =
class AtomicTaroToolPane

  constructor: (@masterVariant, @programProcessor, @travelAgent, @root) ->
    @pane = document.createElement('div')
    @pane.classList.add('atomic-taro_tools-pane')
    $(@pane).width('20em')
    $(@pane).css('max-width', '20em')

    @outputExplorer = new OutputPane(@masterVariant, @programProcessor, @travelAgent, @root)

    @resizeRegion = document.createElement('div')
    @resizeRegion.classList.add('atomic-taro_tools-resize-handle')

    @initialize()
    @addListeners()

  initialize: ->
    #@pane.appendChild(@variantExplorer.getElement())
    @pane.appendChild(@addSearchBar())
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
    $(@pane).css('max-width', width)

  addSearchBar: ->
    searchContainer = document.createElement('div')
    searchContainer.classList.add('atomic-taro_search-bar-container')
    searchContainer.classList.add('native-key-bindings')
    # searchIcon = document.createElement('span')
    # searchIcon.classList.add('icon-search-save')
    # searchIcon.classList.add('atomic-taro_search-icon')
    searchBar = document.createElement('input')
    searchBar.type = "search"
    searchBar.placeholder = "search"
    searchBar.classList.add('input-search')
    searchBar.classList.add('atomic-taro_search-bar')

    #searchContainer.appendChild(searchIcon)
    searchContainer.appendChild(searchBar)
    searchContainer
