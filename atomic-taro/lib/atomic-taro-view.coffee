# The following two set up jquery and jquery-ui (it will only work in
# this browserify version, probably because Atom itself is not a browser)
# If these do not work, install them locally using npm
global.jQuery = global.$ = require 'jquery'
require 'jquery-ui-browserify'

{TextBuffer} = require 'atom'
{ScrollView} = require 'atom-space-pen-views'
Segment = require './segment-objects/segment'
SegmentManager = require './segment-manager'
SharedFunctionSegment = require './segment-objects/shared-function-segment'

module.exports =
class AtomicTaroView# extends ScrollView
  segmentManager : null
  sourceFile : null

  constructor: (statePath, plainCodeEditor, {fpath, protocol}) ->
    $.getJSON (statePath), (state) =>
      console.log "JSON found"
      console.log state
      @deserialize(state)

    # plainCodeEditor is the user's original python file
    plainCodeEditor = plainCodeEditor
    @sourceFile = fpath
    #root element
    @element = document.createElement('div')
    @element.classList.add('atomic-taro_pane')#, 'scroll-view')

    # create a segment manager from the original editor
    @segmentManager = new SegmentManager(plainCodeEditor, @element)

    # the header is the code that occurs at the top of the file,
    # outside of segment boxes
    header = @segmentManager.getHeader()
    @element.appendChild(header.getDiv())

    # root container for segment boxes
    block_pane = document.createElement('div')
    block_pane.classList.add('atomic-taro_block-pane')
    # make segments draggable in this div
    $(block_pane).sortable({ axis: 'y' }) # < this allows blocks to be re-arranged
    $(block_pane).disableSelection()
    @element.appendChild(block_pane)
    # now add in each segment to the div
    segs = @segmentManager.getSegments()
    for segment in segs
      div = segment.getDiv()
      block_pane.appendChild(div)

    # finally, add jquery listeners for all the interactions
    @addJqueryListeners()

  # This is the title that shows up on the tab
  getTitle: -> 'ExploratoryView'

  # Returns an object that can be retrieved when package is activated
  serialize: ->
    sourceFile: @sourceFile?
    segments: @segmentManager.serialize()

  deserialize: (state) ->
    atomicTaroViewState =  state.atomicTaroViewState
    segments = atomicTaroViewState.segments
    @segmentManager.deserialize(segments)

  #since atom doesn't know how ot save our editor, we manually set this up
  saveSegments: (e) ->
    @segmentManager.saveSegments(e)

  copySegment: (e) ->
    @segmentManager.copySegment(e)

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  # Gets the root element
  getElement: ->
    @element

  addJqueryListeners: ->
    @segmentManager.addJqueryListeners(@element)
