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
UndoAgent = require './undo-agent'

module.exports =
class AtomicTaroView


  constructor: (statePath, @filePath, @fileName, @fileType, sourceEditor) ->
    @sourceEditor = sourceEditor
    @exploratoryEditor = null
    @variantWidth = null
    @variantManager = null

    @undoAgent = new UndoAgent(50) #max undo entries

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
      #console.log "HEIGHT??"
      #console.log @exploratoryEditor.getElement().getHeight()
      #console.log @exploratoryEditor.getElement().getScrollHeight()
      #$(@exploratoryEditor.getElement()).css('overflow-y', 'scroll')

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
    @exploratoryEditor.getElement().setHeight(635) # WARNING HARD CODED!!!!
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
    exploratoryEditor = atom.workspace.buildTextEditor(buffer: new AnnotationProcessorBuffer(text: sourceCode, undoAgent: @undoAgent, filePath: @filePath, variantView: @), grammar: atom.grammars.selectGrammar("file."+@fileType),  scrollPastEnd: true)
    exploratoryEditor



  initCursorListeners: ->
    @exploratoryEditor.onDidChangeCursorPosition (ev) =>
      cursorPosition = ev.newBufferPosition
      active = @variantManager.getFocusedVariant()
      if active?
        activeMarker = active.getMarker()
        if !activeMarker.getBufferRange().containsPoint(cursorPosition)
          @variantManager.unFocusVariant(active)

      m = @exploratoryEditor.findMarkers(containsBufferPosition: cursorPosition)
      #console.log "MARKERS FOUND"
      #console.log m
      if m.length > 0
        @variantManager.setFocusedVariant(m)



  # This is the title that shows up on the tab
  getTitle: -> @fileName



  #since atom doesn't know how ot save our editor, we manually set this up
  saveVariants: (e) ->
    @exploratoryEditor.save()

  getVariants: ->
    @variantManager.getVariants()

  sortVariants: ->
    @variantManager.sortVariants()

  copyVariant: (e) ->
    @variantManager.copyVariant(e)


  wrapNewVariant: (e, params) ->
    # first, get range
    range = @exploratoryEditor.getSelectedBufferRange()
    start = range.start
    end = range.end

    # now, see if there are any preexisting variants that overlap
    selected = @exploratoryEditor.findMarkers(containsBufferRange: range)
    nest_Parent = null
    for marker in selected
      p = marker.getProperties().myVariant
      if p?
        nest_Parent = [p.getModel().getCurrentVersion(),p]

    # now initialize everything
    marker = @exploratoryEditor.markBufferRange(range, invalidate: 'never')
    #finally, make the new variant!
    variant = new VariantView(@exploratoryEditor, marker, "v0", @, @undoAgent)
    marker.setProperties(myVariant: variant)
    headerElement = variant.getHeader()
    hm = @exploratoryEditor.markScreenPosition([start.row - 1, start.col], invalidate: 'never')
    hd = @exploratoryEditor.decorateMarker(hm, {type: 'block', position: 'after', item: headerElement})
    variant.setHeaderMarker(hm)
    variant.setHeaderMarkerDecoration(hd)

    footerElement = variant.getFooter()
    fd = @exploratoryEditor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})
    variant.setFooterMarkerDecoration(fd)
    variant.buildVariantDiv()

    @explorer.getVariantPanel().newVariant(variant)

    # Either add as a neted variant to a parent, or add as a top-level variant
    if nest_Parent?
      nest_Parent[1].addedNestedVariant(variant, nest_Parent[0])  #nest_Parent is an array - second item is the VariantView
    else
      @variantManager.getVariants().push(variant)


    if params?.undoSkip? == false
      variant = @variantManager.getVariants().pop()
      console.log variant
      @undoAgent.pushChange({data: {undoSkip: true}, callback: variant.dissolve})



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
    #console.log "beacons!! "
    #console.log beacons
    list_offset = @addAllVariants(editor, beacons, 0, [])
    #console.log "variant List"
    #for l in list_offset.list
    #  console.log l.getModel().getRootVersion()
    list_offset.list


  findMarkers: (editor) ->
    beacons = []
    sourceBuffer = editor.buffer
    lineArray = sourceBuffer.getLines()
    prevStart = null
    endStack = []
    for line, index in lineArray
      if line.includes("#%%^%%")

        if ((prevStart != null) and (prevStart.end == null))
          b = {start: new Point(index, 0), end: null, nested: []}
          prevStart.nested.push(b)
          endStack.push(b)
          prevStart = b
        else
          beacons.push({start: new Point(index, 0), end: null, nested: []})
          prevStart = beacons[beacons.length - 1]
          endStack.push(prevStart)

      else if line.includes("#^^%^^")
        endStack.pop().end = new Point(index , 0)
    #return beacons
    beacons


  addAllVariants: (editor, beacons, rowDeletedOffset, variantList) ->
    variantList = []
    for b in beacons
      priorRow = rowDeletedOffset

      nested = b.nested
      grandchildren = []
      if nested.length > 0
        #cancel out end marker offset, since we are inside the range of that marker
        nestedOffset = rowDeletedOffset
        list_offset = @addAllVariants(editor, nested, nestedOffset, variantList)
        grandchildren = list_offset.list
        rowDeletedOffset = list_offset.offset

      v_offset = @addVariant(editor, b, priorRow, rowDeletedOffset)
      variant = v_offset.variant
      variantList.push variant
      rowDeletedOffset = v_offset.offset
      for g in grandchildren
        variant.addedNestedVariant(g, variant.getModel().getCurrentVersion())


    #return
    {list: variantList, offset: rowDeletedOffset}


  addVariant: (editor, b, rowDeletedOffset, endDeleteOffset) ->
    if endDeleteOffset? == false
      endDeleteOffset = rowDeletedOffset

    sb = b.start #startBeacon[i]
    eb = b.end #endBeacon[i]
    editorBuffer = editor.getBuffer()

    # create a marker for this range so that we can keep track
    range = [sb, eb]
    start = new Point(range[0].row - rowDeletedOffset, range[0].col)
    end = new Point(range[1].row - endDeleteOffset - 1, range[1].col)
    range = [start, new Point(end.row, 100000000000)]
    range = editorBuffer.clipRange(range)
    marker = editor.markBufferRange(range, invalidate: 'never')

    '''below, useful for debug!!!'''
    #dec = editor.decorateMarker(marker, type: 'highlight', class: 'highlight-pink')

    # now, trim annotations
    #rowStart = sb.range.start.row
    rowStart = sb.row
    title = editorBuffer.lineForRow(rowStart - rowDeletedOffset)
    #rowEnd = eb.range.end.row
    rowEnd = eb.row
    editorBuffer.deleteRow(rowStart - rowDeletedOffset)
    endDeleteOffset += 1
    editorBuffer.deleteRow(rowEnd - endDeleteOffset)
    endDeleteOffset += 1

    #get title from removed annotation
    title = title.trim().substring(6)

    #finally, make the new variant!
    variant = new VariantView(editor, marker, title, @, @undoAgent)
    marker.setProperties(myVariant: variant)
    #editor.decorateMarker(marker, type: 'highlight', class: 'highlight-green')

    headerElement = variant.getHeader()
    #console.log headerElement
    hRange = [start, new Point(end.row - 1, end.col)]
    hm = editor.markBufferRange(hRange, invalidate: 'never', reversed: true)
    #editor.decorateMarker(hm, type: 'highlight', class: 'highlight-pink')
    hm.setProperties(myVariant: variant)
    hdec = editor.decorateMarker(hm, {type: 'block', position: 'before', item: headerElement})
    variant.setHeaderMarker(hm)
    variant.setHeaderMarkerDecoration(hdec)

    footerElement = variant.getFooter()
    fdec = editor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})
    variant.setFooterMarkerDecoration(fdec)

    #finally, return variant
    {variant: variant, offset: endDeleteOffset}
