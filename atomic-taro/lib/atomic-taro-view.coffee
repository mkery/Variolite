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
VariantExplorerPane = require './right-panel/variant-explorer-pane'
AtomicTaroToolPane = require './right-panel/atomic-taro-tool-pane'

module.exports =
class AtomicTaroView


  constructor: (statePath, @filePath, sourceEditor) ->
    @sourceEditor = sourceEditor
    @exploratoryEditor = null
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
        console.log "state variants????"
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

      atom.views.addViewProvider AtomicTaroToolPane, (toolPane) ->
        toolPane.getElement()

      @explorer = new AtomicTaroToolPane(@variantManager, @)

  isShowingExplorer: ->
    @explorer_panel.isVisible()

  toggleExplorerView: ->
    if @explorer_panel?
      if @explorer_panel.isVisible()
        @explorer_panel.hide()
      else
        @explorer_panel.show()

    else
      @explorer_panel = atom.workspace.addRightPanel({item: @explorer})
    @variantManager.updateExplorerPanelShowing(@explorer_panel.isVisible(), @getWidth())
    @explorer_panel.isVisible()

  initializeView: ->
    # exploratoryEditor is the python file modified to show our visualization things
    @exploratoryEditor = @initExploratoryEditor(@sourceEditor)
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
    @exploratoryEditor.onDidChangeCursorPosition (ev) =>
      active = @variantManager.getFocusedVariant()
      if active?
        activeMarker = active.getMarker()
        if activeMarker.getBufferRange().containsPoint(ev.newBufferPosition)
          active.updateFocusPosition(ev.newBufferPosition)
          return
        else
          @variantManager.unFocusVariant(active)

      m = @exploratoryEditor.findMarkers(containsBufferPosition: ev.newBufferPosition)
      if m[0]?
        if m[0].getProperties().myVariant?
          @variantManager.setFocusedVariant(m[0].getProperties().myVariant, ev.newBufferPosition)



  # This is the title that shows up on the tab
  getTitle: -> 'ExploratoryView'



  #since atom doesn't know how ot save our editor, we manually set this up
  saveVariants: (e) ->
    @exploratoryEditor.save()

  getVariants: ->
    @variantManager.getVariants()

  sortVariants: ->
    @variantManager.sortVariants()

  copyVariant: (e) ->
    @variantManager.copyVariant(e)


  wrapNewVariant: (e) ->
    range = @exploratoryEditor.getSelectedBufferRange()
    start = range.start
    end = range.end
    topOfFile = new Range(new Point(0, 0), start)
    checkBuffer = @sourceEditor.getTextInBufferRange(topOfFile)
    count = (checkBuffer.match(/(#ʕ•ᴥ•ʔ#)/g) || []).length
    '''@sourceEditor.setCursorScreenPosition([range.end.row + 2 * count + 1, range.end.col])
    @sourceEditor.moveToEndOfLine()
    @sourceEditor.insertNewlineBelow()
    #@sourceEditor.setCursorScreenPosition([range.end.row + 2 * count + 1, range.end.col])
    #@sourceEditor.moveToEndOfLine()
    #@sourceEditor.insertNewlineBelow()
    startOrig = new Point(range.start.row + 2 * count, range.start.col)
    endOrig = new Point(range.end.row + 2 * count + 2, range.end.col)'''

    #@sourceEditor.getBuffer().insert(startOrig, "#ʕ•ᴥ•ʔ#")
    #@sourceEditor.getBuffer().insert(endOrig, "##ʕ•ᴥ•ʔ")

    marker = @exploratoryEditor.markBufferRange(range, invalidate: 'never')
    #finally, make the new variant!
    variant = new VariantView(@exploratoryEditor, marker, "v0", @)
    marker.setProperties(myVariant: variant)
    @variantManager.getVariants().push(variant)
    headerElement = variant.getHeader()
    hm = @exploratoryEditor.markScreenPosition([start.row - 1, start.col], invalidate: 'never')
    @exploratoryEditor.decorateMarker(hm, {type: 'block', position: 'after', item: headerElement})
    variant.setHeaderMarker(hm)

    footerElement = variant.getFooter()
    @exploratoryEditor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})
    variant.buildVariantDiv()

    #@addJqueryListeners()
    #@postInit_buildView()

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
    beacons = @findMarkers(editor)
    list_offset = @addAllVariants(editor, beacons, 0)
    list_offset.list


  findMarkers: (editor) ->
    beacons = []
    sourceBuffer = editor.buffer
    lineArray = sourceBuffer.getLines()
    prevStart = null
    endStack = []
    for line, index in lineArray
      if line.includes("#ʕ•ᴥ•ʔ#")

        if ((prevStart != null) and (prevStart.end == null))
          b = {start: new Point(index, 0), end: null, nested: []}
          prevStart.nested.push(b)
          endStack.push(b)
          prevStart = b
        else
          beacons.push({start: new Point(index, 0), end: null, nested: []})
          prevStart = beacons[beacons.length - 1]
          endStack.push(prevStart)

      else if line.includes("##ʕ•ᴥ•ʔ")
        endStack.pop().end = new Point(index , 0)
    #return beacons
    beacons


  addAllVariants: (editor, beacons, rowDeletedOffset) ->
    variantList = []
    for b in beacons
      v_offset = @addVariant(editor, b, rowDeletedOffset)
      variant = v_offset.variant
      variantList.push variant
      rowDeletedOffset = v_offset.offset

      nested = b.nested
      if nested.length > 0
        #cancel out end marker offset, since we are inside the range of that marker
        nestedOffset = rowDeletedOffset - 1
        list_offset = @addAllVariants(editor, nested, nestedOffset)
        grandchildren = list_offset.list
        for g in grandchildren
          variantList.push g
          variant.addedNestedVariant(g)
        rowDeletedOffset = list_offset.offset + 1



    #return
    {list: variantList, offset: rowDeletedOffset}


  addVariant: (editor, b, rowDeletedOffset) ->
    sb = b.start #startBeacon[i]
    eb = b.end #endBeacon[i]

    # create a marker for this range so that we can keep track
    range = [sb, eb]
    start = new Point(range[0].row - rowDeletedOffset, range[0].col)
    end = new Point(range[1].row - rowDeletedOffset - 1, range[1].col)
    range = [start, end]
    marker = editor.markBufferRange(range, invalidate: 'never')

    '''below, useful for debug!!!'''
    #dec = editor.decorateMarker(marker, type: 'highlight', class: 'highlight-pink')

    # now, trim annotations
    editorBuffer = editor.getBuffer()
    #rowStart = sb.range.start.row
    rowStart = sb.row
    title = editorBuffer.lineForRow(rowStart - rowDeletedOffset)
    #rowEnd = eb.range.end.row
    rowEnd = eb.row
    editorBuffer.deleteRow(rowStart - rowDeletedOffset)
    rowDeletedOffset += 1
    editorBuffer.deleteRow(rowEnd - rowDeletedOffset)
    rowDeletedOffset += 1

    #get title from removed annotation
    title = title.substring(7)
    console.log "found title! "+title

    #finally, make the new variant!
    variant = new VariantView(editor, marker, title, @)
    marker.setProperties(myVariant: variant)

    headerElement = variant.getHeader()
    hm = editor.markBufferRange(range, invalidate: 'never', reversed: true)
    hm.setProperties(myVariant: variant)
    #console.log hm.getBufferRange()
    editor.decorateMarker(hm, {type: 'block', position: 'before', item: headerElement})
    variant.setHeaderMarker(hm)

    footerElement = variant.getFooter()
    editor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})

    #finally, return variant
    {variant: variant, offset: rowDeletedOffset}
