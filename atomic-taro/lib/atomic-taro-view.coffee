# The following two set up jquery and jquery-ui (it will only work in
# this browserify version, probably because Atom itself is not a browser)
# If these do not work, install them locally using npm
global.jQuery = global.$ = require 'jquery'
require 'jquery-ui-browserify'
fs = require 'fs'

{TextBuffer} = require 'atom'
{Point, Range} = require 'atom'
{ScrollView} = require 'atom-space-pen-views'
VariantsManager = require './variants-manager'
Variant = require './variant'
ExploratorySegmentView = require './segment-objects/exploratory-segment-view'
VariantView = require './variant-view'
AnnotationProcessorBuffer = require './annotation-processor-buffer'

module.exports =
class AtomicTaroView# extends ScrollView
  variantManager : null
  sourceFile : null

  constructor: (statePath, sourceEditor) ->
    # try to get saved meta data for this file, if there is any
    @deserialize(statePath)

    @sourceEditor = sourceEditor
    # exploratoryEditor is the python file modified to show our visualization things
    @exploratoryEditor = @initExploratoryEditor(@sourceEditor)

    variantWidth = @sourceEditor.getElement().getWidth() - 20
    variants = @initVariants(@exploratoryEditor, variantWidth)

    # create a variant manager
    @variantsManager = new VariantsManager(variants)

    #root element
    @element = document.createElement('div')
    @element.classList.add('atomic-taro_pane')#, 'scroll-view')
    @element.appendChild(@exploratoryEditor.getElement())


    # root container for variant boxes
    block_pane = document.createElement('div')
    block_pane.classList.add('atomic-taro_block-pane')
    @element.appendChild(block_pane)



  # init Exploratory Editor
  initExploratoryEditor: (sourceEditor) ->
    sourceCode = sourceEditor.getBuffer().getText()
    exploratoryEditor = atom.workspace.buildTextEditor(buffer: new AnnotationProcessorBuffer(text: sourceCode), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
    exploratoryEditor



  # This is the title that shows up on the tab
  getTitle: -> 'ExploratoryView'



  # Returns an object that can be retrieved when package is activated
  serialize: ->
    #sourceFile: @sourceFile?
    #variants: @variantManager.serialize()



  deserialize: (statePath) ->
    # try to get saved meta data for this file, if there is any
    $.getJSON (statePath), (state) =>
        console.log "JSON found"
        console.log state
        #atomicTaroViewState =  state.atomicTaroViewState
        #variants = atomicTaroViewState.variants
        #@variantManager.deserialize(variants)
      .fail ->
        console.log "No saved taro file found."



  #since atom doesn't know how ot save our editor, we manually set this up
  saveVariants: (e) ->
    @variantManager.saveVariants(e)



  copyVariant: (e) ->
    @variantManager.copyVariant(e)



  # Tear down any state and detach
  destroy: ->
    @element.remove()



  # Gets the root element
  getElement: ->
    @element



  addJqueryListeners: ->
    @variantManager.addJqueryListeners(@element)



  initVariants: (editor, width) ->
    startBeacon = []
    editor.scan new RegExp('#ʕ•ᴥ•ʔ#', 'g'), (match) =>
      startBeacon.push(match)

    endBeacon = []
    editor.scan new RegExp('##ʕ•ᴥ•ʔ', 'g'), (match) =>
      endBeacon.push(match)
      #console.log "found ##ʕ•ᴥ•ʔ!"

    @addVariants(editor, startBeacon, endBeacon, width)



  addVariants: (editor, startBeacon, endBeacon, variantWidth) ->
    length = Math.min(startBeacon.length, endBeacon.length)
    rowDeletedOffset = 0
    variantList = []

    for i in [0...length]
      sb = startBeacon[i]
      eb = endBeacon[i]

      # create a marker for this range so that we can keep track
      #range = new Range(new Point(sb.range.start.row - rowDeletedOffset, sb.range.start.col), new Point(eb.range.end.row - rowDeletedOffset, eb.range.end.col))
      range = [sb.range.start, eb.range.end]
      start = new Point(range[0].row - rowDeletedOffset, range[0].col)
      end = new Point(range[1].row - rowDeletedOffset, range[1].col)
      range = [start, end]
      marker = editor.markBufferRange(range, invalidate: 'never')

      '''below, useful for debug!!!'''
      #dec = editor.decorateMarker(marker, type: 'highlight', class: 'highlight-green')

      # now, trim annotations
      editorBuffer = editor.getBuffer()
      rowStart = sb.range.start.row
      title = editorBuffer.lineForRow(rowStart - rowDeletedOffset)
      rowEnd = eb.range.end.row
      editorBuffer.deleteRow(rowStart - rowDeletedOffset)
      rowDeletedOffset += 1
      editorBuffer.deleteRow(rowEnd - rowDeletedOffset)
      rowDeletedOffset += 1

      #get title from removed annotation
      title = title.substring(7)

      #finally, make the new variant!
      variant = new ExploratorySegmentView(editor, marker, title, variantWidth)
      variantList.push(variant)
      headerElement = variant.getHeader()
      hm = editor.markScreenPosition([start.row - 1, start.col], invalidate: 'never')
      editor.decorateMarker(hm, {type: 'block', position: 'after', item: headerElement})

      footerElement = variant.getFooter()
      fm = editor.markScreenPosition(end)
      editor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})

    #return
    variantList
