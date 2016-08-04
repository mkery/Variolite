# The following two set up jquery and jquery-ui (it will only work in
# this browserify version, probably because Atom itself is not a browser)
# If these do not work, install them locally using npm
global.jQuery = global.$ = require 'jquery'
require 'jquery-ui-browserify'
require './ui-helpers/jquery.hoverIntent.minified.js'
fs = require 'fs'

{TextBuffer} = require 'atom'
{Point, Range} = require 'atom'
VariantsManager = require './variants-manager'
Variant = require './segment-objects/variant'
VariantView = require './segment-objects/variant-view'
AnnotationProcessorBuffer = require './annotation-processor-buffer'
VariantExplorerPane = require './variant-explorer-pane'

module.exports =
class AtomicTaroView


  constructor: (statePath, @filePath, sourceEditor) ->
    @sourceEditor = sourceEditor
    @exploratoryEditor = null
    @cursors = null
    @variantWidth = null
    @variantManager = null

    #divs
    @element = null
    @explorer = null
    @explorer_panel = null
    # try to get saved meta data for this file, if there is any
    @initializeView()
    @deserialize(statePath)


  deactivate: ->
    @variantManager.deactivate()


  # Returns an object that can be retrieved when package is activated
  serialize: ->
    variants: @variantManager?.serialize()


  deserialize: (statePath) ->
    # try to get saved meta data for this file, if there is any
    $.getJSON (statePath), (state) =>
        console.log "JSON found"
        console.log state

        stateVariants = state.atomicTaroViewState.variants
        #console.log "state variants????"
        #console.log stateVariants
        @variantManager.deserialize(stateVariants)
        @postInit_buildView()
      .fail =>
        console.log "No saved taro file found."
        @postInit_buildView()

  getWidth: ->
    @exploratoryEditor.getElement().getWidth() - 20

  postInit_buildView: ->
      @element.appendChild(@exploratoryEditor.getElement())
      @variantManager.buildVersionDivs()

      atom.views.addViewProvider VariantExplorerPane, (variantExplorer) ->
        variantExplorer.getElement()

      @explorer = new VariantExplorerPane(@variantManager, @)


  toggleExplorerView: ->
    if @explorer_panel?
      if @explorer_panel.isVisible()
        @explorer_panel.hide()
      else
        @explorer_panel.show()

    else
      @explorer_panel = atom.workspace.addRightPanel({item: @explorer})
    #TODO figure out width of the editor element without the line gutter (55 is a guess)
    @variantManager.updateVariantWidth(@getWidth())#$(@element).width() - 70)


  initializeView: ->
    # exploratoryEditor is the python file modified to show our visualization things
    @exploratoryEditor = @initExploratoryEditor(@sourceEditor)
    @cursors = @exploratoryEditor.getCursors()
    @initCursorListeners()

    #root element
    @element = document.createElement('div')
    @element.classList.add('atomic-taro_pane')#, 'scroll-view')

    #@variantWidth = $(@element).width() - 20 #@sourceEditor.getElement().getWidth() - 20
    variants = @initVariants(@exploratoryEditor, @element)

    # create a variant manager
    @variantManager = new VariantsManager(variants, @)

    #@element.appendChild(@exploratoryEditor.getElement())

    atom.contextMenu.add {'atom-pane': [{label: 'Copy Segment', command: 'atomic-taro:tarocopy'}]}
    atom.contextMenu.add {'atom-pane': [{label: 'Paste Segment', command: 'atomic-taro:taropaste'}]}
    atom.contextMenu.add {'atom-text-editor': [{label: 'Paste Segment', command: 'atomic-taro:taropaste'}]}



  # init Exploratory Editor
  initExploratoryEditor: (sourceEditor) ->
    sourceCode = sourceEditor.getBuffer().getText()
    exploratoryEditor = atom.workspace.buildTextEditor(buffer: new AnnotationProcessorBuffer(text: sourceCode, filePath: @filePath, variantView: @), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: true)
    exploratoryEditor



  initCursorListeners: ->
    for cursor in @cursors
      cursor.onDidChangePosition (ev) =>
        active = @variantManager.getFocusedVariant()
        if active?
          activeMarker = active.getMarker()
          if activeMarker.getBufferRange().containsPoint(ev.newBufferPosition)
            return
          else
            @variantManager.unFocusVariant(active)

        m = @exploratoryEditor.findMarkers(containsBufferPosition: ev.newBufferPosition)
        if m[0]?
          if m[0].getProperties().myVariant?
            @variantManager.setFocusedVariant(m[0].getProperties().myVariant)



  # This is the title that shows up on the tab
  getTitle: -> 'ExploratoryView'



  #since atom doesn't know how ot save our editor, we manually set this up
  saveVariants: (e) ->
    @exploratoryEditor.save()

  getVariants: ->
    @variantManager.getVariants()

  copyVariant: (e) ->
    @variantManager.copyVariant(e)


  wrapNewVariant: (e) ->
    range = @exploratoryEditor.getSelectedBufferRange()
    start = range.start
    end = range.end
    marker = @exploratoryEditor.markBufferRange(range, invalidate: 'never')
    #finally, make the new variant!
    variant = new ExploratorySegmentView(@exploratoryEditor, marker, "", @variantWidth)
    @variantManager.addVariant(variant)
    headerElement = variant.getHeader()
    hm = @exploratoryEditor.markScreenPosition([start.row - 1, start.col], invalidate: 'never')
    @exploratoryEditor.decorateMarker(hm, {type: 'block', position: 'after', item: headerElement})

    footerElement = variant.getFooter()
    fm = @exploratoryEditor.markScreenPosition(end)
    @exploratoryEditor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})

  pasteSegment: (e) ->
    segs = @segmentManager.getSegments()
    for segment in segs
      console.log segment
      div = segment.getDiv()
      if segment instanceof ExploratorySegmentView
        continue
      else if segment.getModel().getCopied() == true
        block_pane = document.createElement('div')
        block_pane.classList.add('atomic-taro_block-pane')
        # make segments draggable in this div
        $(block_pane).sortable({ axis: 'y' }) # < this allows blocks to be re-arranged
        $(block_pane).disableSelection()
        @element.appendChild(block_pane)
        #console.log div
        block_pane.appendChild(div)
        bufferLineCount = segment.getModel().getLineCount()
        endOfFile = @segmentManager.sourceEditor.getLastBufferRow() + 1
        codeRange = new Range(new Point(endOfFile, 0), new Point(endOfFile + bufferLineCount, 0))
        marker = @segmentManager.sourceEditor.markBufferRange(codeRange)
        codeText =  "#ʕ•ᴥ•ʔ" + segment.getModel().getTitle() + "ʔ\n" + segment.getModel().getBuffer().getText() + "\n#ʕ•ᴥ•ʔ"
        @segmentManager.sourceEditor.setTextInBufferRange(codeRange, codeText)
        segment.getModel().addChangeListeners(@segmentManager.sourceBuffer)
    #@segmentManager.pasteSegment(e)

  # Tear down any state and detach
  destroy: ->
    @element.remove()



  # Gets the root element
  getElement: ->
    @element



  addJqueryListeners: ->
    @variantManager.addJqueryListeners(@element)



  initVariants: (editor) ->
    startBeacon = []
    editor.scan new RegExp('#ʕ•ᴥ•ʔ#', 'g'), (match) =>
      startBeacon.push(match)

    endBeacon = []
    editor.scan new RegExp('##ʕ•ᴥ•ʔ', 'g'), (match) =>
      endBeacon.push(match)
      #console.log "found ##ʕ•ᴥ•ʔ!"

    @addVariants(editor, startBeacon, endBeacon)



  addVariants: (editor, startBeacon, endBeacon) ->
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
      variant = new VariantView(editor, marker, title, @)
      marker.setProperties(myVariant: variant)
      variantList.push(variant)
      headerElement = variant.getWrappedHeader()
      hm = editor.markScreenPosition([start.row - 1, start.col], invalidate: 'never')
      editor.decorateMarker(hm, {type: 'block', position: 'after', item: headerElement})
      variant.setHeaderMarker(hm)

      footerElement = variant.getWrappedFooter()
      editor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})

    #return
    variantList
