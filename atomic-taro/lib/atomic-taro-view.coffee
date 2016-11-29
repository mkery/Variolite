# The following two set up jquery and jquery-ui (it will only work in
# this browserify version, probably because Atom itself is not a browser)
# If these do not work, install them locally using npm
global.jQuery = global.$ = require 'jquery'
require 'jquery-ui-browserify'
require './ui-helpers/jquery.hoverIntent.minified.js'
fs = require 'fs'

{Pane} = require 'atom'
{TextEditor} = require 'atom'
{Point, Range} = require 'atom'
VariantsManager = require './variants-manager'
Variant = require './segment-objects/variant-model'
VariantView = require './segment-objects/variant-view'
AnnotationProcessorBuffer = require './annotation-processor-buffer'
VariantExplorerPane = require './right-panel/variant-explorer-pane'
AtomicTaroToolPane = require './right-panel/atomic-taro-tool-pane'
UndoAgent = require './undo-agent'
ProvUtils = require './provenance-utils'
ProgramProcessor = require './program-processor'
MainHeaderMenu = require './main-header-menu'
LinkGutter = require './link-gutter'

'''
  TODO - rethink annotation-processor-buffer
       - get save working
       - get serialize/deserialize working again
'''

module.exports =
class AtomicTaroView

  constructor: (statePath, @filePath, @fileName, @fileType, sourceEditor) ->
    # editors. The source editor is the editor of the original file.
    # The exploratory editor is uses our annotation processor buffer.
    @sourceEditor = sourceEditor
    @exploratoryEditor = null

    @variantListeners = null # holds jquery listeners

    # The master variant is a top level variant that wraps the entire file
    @masterVariant = null

    @undoAgent = new UndoAgent(50) #max undo entries
    @programProcessor = null # object to run code and record output
    @provenanceAgent = new ProvUtils()

    #divs
    @element = null
    @explorer = null
    @explorer_panel = null # the Panel object of @explorer
    @mainHeaderMenu = null

    # try to get saved meta data for this file, if there is any
    @initializeView()
    @deserialize(statePath)


  '''
    ???
  '''
  deactivate: ->
    @masterVariant.deactivate()


  '''
    ??? used ??? Tear down any state and detach
  '''
  destroy: ->
    @element.remove()


  '''
    Returns an object that can be retrieved when package is activated
  '''
  serialize: ->
    variants: @masterVariant?.serialize()


  '''
    Decodes a JSON file metadata into variant boxes and commits
  '''
  deserialize: (statePath) ->
    # try to get saved meta data for this file, if there is any
    $.getJSON (statePath), (state) =>
        console.log "JSON found"
        console.log state

        stateVariants = state.atomicTaroViewState.variants
        #console.log "state variants????"
        #console.log stateVariants.variants
        @masterVariant.deserialize(stateVariants)
        @postInit_buildView()

      .fail =>
        console.log "No saved taro file found."
        @postInit_buildView()


  '''
    ??? used
  '''
  saveAs: (newItemPath) ->
    console.log "asked me to save!!!"


  '''
    ??? used
  '''
  save: ->
    console.log "asked me to save!!!"


  '''
    ??? used
  '''
  getURI: ->
    @filePath


  '''
    Returns the file path of the current program file being shown in the tool.
  '''
  getPath: ->
    @filePath


  '''
    Returns the current width of the editor area of the tool, when the editor
    is resized.
  '''
  getWidth: ->
    @exploratoryEditor.getElement().getWidth()# - 20


  '''
    There is a master variant that wraps the entire file.
  '''
  getMasterVariant: ->
    @masterVariant


  '''
    There is a master variant that wraps the entire file.
  '''
  getExplorerPanel: ->
    @explorer_panel


  isShowingExplorer: ->
    @explorer_panel.isVisible()


  showExplorerView: ->
    if not @explorer_panel?
      @explorer_panel = atom.workspace.addRightPanel({item: @explorer})
    if not @explorer_panel.isVisible()
      @explorer_panel.show()
    width = @getWidth()
    @variantListeners.updateExplorerPanelShowing(@isShowingExplorer(), width)
    @masterVariant.updateVariantWidth(width)
    @mainHeaderMenu.updateWidth(width)


  closeExplorerView: ->
    @explorer_panel.hide()
    width = @getWidth()
    @variantListeners.updateExplorerPanelShowing(@explorer_panel.isVisible(), width)
    @masterVariant.updateVariantWidth(width)
    @mainHeaderMenu.updateWidth(width)


  toggleExplorerView: ->
    if @explorer_panel?
      if @explorer_panel.isVisible()
        @explorer_panel.hide()
      else
        @explorer_panel.show()

    else
      @explorer_panel = atom.workspace.addRightPanel({item: @explorer})
    width = @getWidth()
    @variantListeners.updateExplorerPanelShowing(@isShowingExplorer(), width)
    @masterVariant.updateVariantWidth(width)
    @mainHeaderMenu.updateWidth(width)
    @explorer_panel.isVisible()


  '''
    When the user hits the 'run' button, this sends the current program to be run.
    The output is then passed back to @registerOutput()
  '''
  runProgram: ->
    @programProcessor.run()


  '''
    When the user's program is run, Variolite wraps the output and returns the
    output to here.
  '''
  registerOutput: (data) ->
    commitId = @masterVariant.registerOutput(data)
    @explorer.registerOutput(data, commitId)




  '''
    Gets the root element
  '''
  getElement: ->
    @element


  '''
    Adds Jquery listeners and functions to all variant boxes
  '''
  addJqueryListeners: ->
    @variantListeners.addJqueryListeners(@element)
    @gutter.addJqueryListeners()


  '''
    Run when tool is first opened, to put all the main div elements in place, while the
    variant informaiton may still be loading.
  '''
  initializeView: ->
    # exploratoryEditor is the python file modified to show our visualization things
    @exploratoryEditor = @initExploratoryEditor(@sourceEditor)
    @exploratoryEditor.getElement().setHeight(635) # WARNING HARD CODED!!!!
    @initCursorListeners()

    #root element
    @element = document.createElement('div')
    @element.classList.add('atomic-taro_pane')#, 'scroll-view')

    # gutter
    @gutter = new LinkGutter(@exploratoryEditor, @)

    #@variantWidth = $(@element).width() - 20 #@sourceEditor.getElement().getWidth() - 20
    @initVariants(@exploratoryEditor, @element)

    # menu at the top of the code
    @mainHeaderMenu = new MainHeaderMenu(@masterVariant, @)
    @element.appendChild(@mainHeaderMenu.getElement())

    # create a variant manager
    @variantListeners = new VariantsManager(@masterVariant, @)
    @programProcessor = new ProgramProcessor(@filePath, @)

    # right click menu
    atom.contextMenu.add {'atom-pane': [{label: 'Copy Segment', command: 'atomic-taro:tarocopy'}]}
    atom.contextMenu.add {'atom-pane': [{label: 'Paste Segment', command: 'atomic-taro:taropaste'}]}
    atom.contextMenu.add {'atom-text-editor': [{label: 'Paste Segment', command: 'atomic-taro:taropaste'}]}


  '''
    Run after the variant's have loaded in their meta-data, so that we can finish
    up building and display the tool.
  '''
  postInit_buildView: ->
      @element.appendChild(@exploratoryEditor.getElement())

      @masterVariant.buildVariantDiv()
      @addJqueryListeners()

      atom.views.addViewProvider AtomicTaroToolPane, (toolPane) ->
        toolPane.getElement()

      @explorer = new AtomicTaroToolPane(@masterVariant, @programProcessor, @)


  '''
    Creates a TextEditor that uses AnnotationProcessorBuffer for this tool. Ideally
    we can use the text editor that is already there once we figure out a good alternative
    for dealing with annotations!
  '''
  initExploratoryEditor: (sourceEditor) ->
    sourceCode = sourceEditor.getBuffer().getText()
    exploratoryEditor = atom.workspace.buildTextEditor(buffer: new AnnotationProcessorBuffer(text: sourceCode, undoAgent: @undoAgent, filePath: @filePath, variantView: @), grammar: atom.grammars.selectGrammar("file."+@fileType),  scrollPastEnd: true)
    atom.textEditors.add(exploratoryEditor)
    exploratoryEditor


  '''
    Detects when the cursor is focused or in the boundaries of a variant box
  '''
  initCursorListeners: ->
    @exploratoryEditor.onDidChangeCursorPosition (ev) =>
      cursorPosition = ev.newBufferPosition
      active = @variantListeners.getFocusedVariant()
      if active?
        activeMarker = active.getMarker()
        if !activeMarker.getBufferRange().containsPoint(cursorPosition)
          @variantListeners.unFocusVariant(active)

      m = @exploratoryEditor.findMarkers(containsBufferPosition: cursorPosition)

      if m.length > 0
        @variantListeners.setFocusedVariant(m)


  '''
   This is the title that shows up on the tab in Atom
  '''
  getTitle: -> @fileName


  '''
    Since atom doesn't know how to save our editor, we manually set this up
  '''
  saveVariants: (e) ->
    @exploratoryEditor.save()



  #sortVariants: ->
  #  @variantListeners.sortVariants()



  '''
    When the user selects to 'travel' to an earlier commit, this starts the process
    of adjusting the whole UI to reflect that past or future state of the code.
  '''
  travelToCommit: (commitId) ->
    $(@commitAlertLabel).text("viewing commit "+commitId.commitID)
    $(@alertPane).show()
    $('.atomic-taro_editor-header-box').addClass('historical')
    $('.atomic-taro_commit-traveler').addClass('historical')
    $('.atomic-taro_editor-footer-box').addClass('historical')
    @masterVariant.travelToCommit(commitId)


  '''
    When the user selects to 'travel' to an earlier commit, this starts the process
    of adjusting the whole UI to reflect that past or future state of the code.
  '''
  wrapNewVariant: (e, params) ->
    # first, get range
    clickRange = @exploratoryEditor.getSelectedBufferRange()
    start = clickRange.start
    end = clickRange.end
    range = [new Point(start.row, 0), new Point(end.row, 100000000000)]
    range = @exploratoryEditor.getBuffer().clipRange(range)
    start = range.start
    end = range.end

    # now, see if there are any preexisting variants that overlap
    overlap_start = @exploratoryEditor.findMarkers(containsBufferPosition: range.start)
    overlap_end = @exploratoryEditor.findMarkers(containsBufferPosition: range.end)
    selected = @exploratoryEditor.findMarkers(containsBufferRange: range)
    #console.log "found N markers: start "+overlap_start.length+", end: "+overlap_end.length+", "+selected.length

    # cannot allow new variants that partially intersect other variants
    if overlap_start.length == overlap_end.length == selected.length
      nest_Parent = null
      for marker in selected
        p = marker.getProperties().myVariant
        if p?
          nest_Parent = [p.getModel().getCurrentVersion(),p]

      # now initialize everything
      marker = @exploratoryEditor.markBufferRange(range, invalidate: 'never')

      #@exploratoryEditor.decorateMarker(marker, {type: 'highlight', class: 'highlight-green'})

      #finally, make the new variant!
      variant = new VariantView(@exploratoryEditor, marker, "v0", @, @undoAgent, @provenanceAgent)
      marker.setProperties(myVariant: variant)
      headerElement = variant.getHeader()
      @gutter.decorateGutter(marker, variant)

      #console.log headerElement
      hRange = [start, new Point(end.row, end.column)]
      hm = @exploratoryEditor.markBufferRange(hRange, invalidate: 'never', reversed: true)
      #@exploratoryEditor.decorateMarker(hm, type: 'highlight', class: 'highlight-pink')
      hm.setProperties(myVariant: variant)
      hdec = @exploratoryEditor.decorateMarker(hm, {type: 'block', position: 'before', item: headerElement})
      variant.setHeaderMarker(hm)
      variant.setHeaderMarkerDecoration(hdec)

      footerElement = variant.getFooter()
      fdec = @exploratoryEditor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})
      variant.setFooterMarkerDecoration(fdec)

      variant.buildVariantDiv()

      @explorer.getVariantPanel().newVariant(variant)

      # Either add as a neted variant to a parent, or add as a top-level variant
      if nest_Parent != null
        nest_Parent[1].addedNestedVariant(variant, nest_Parent[0])  #nest_Parent is an array - second item is the VariantView
      else
        console.log "adding variant to manager"
        @masterVariant.addedNestedVariant(variant, @masterVariant.getModel().getCurrentVersion())


      # if params?.undoSkip? == false
      #   varList = @variantListeners.getVariants()
      #   variant = varList[varList.length - 1]
      #   @undoAgent.pushChange({data: {undoSkip: true}, callback: variant.dissolve})




  '''
    Starting with a plain code file, adds existing variant boxes to display.
    Existing variant boxes are indicated by annotations in the code.
  '''
  initVariants: (editor) ->
    # Get the location of all variant annotaions in the file.
    beacons = @findMarkers(editor)

    # First, wrap the entire file in a variant by default
    wholeFile = [new Point(0,0), new Point(10000000, 10000000)]
    range = @exploratoryEditor.getBuffer().clipRange(wholeFile)
    marker = editor.markBufferRange(range, invalidate: 'never')
    @masterVariant = new VariantView(@exploratoryEditor, marker, @fileName, @, @undoAgent, @provenanceAgent)

    # Build all variant boxes indicated by annotations
    list_offset = @addAllVariants(editor, beacons, 0, [])

    # Fix range for the master variant. Since we've just deleted a bunch of
    # rows that only contained variant annotations, the length of the file
    # has changed.
    range = @exploratoryEditor.getBuffer().clipRange(range)
    @masterVariant.getModel().getMarker().setBufferRange(range)

    # Now, make all variant boxes in the file nested children of the master
    # file-level variant.
    curr = @masterVariant.getModel().getCurrentVersion()
    @masterVariant.addedNestedVariant(v, curr) for v in list_offset.list



  '''
    Search file for variant box annotations and match nested pairs of annotations to
    get the boundaries of each variant box, even if they are nested.
  '''
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



  '''
    For each start/end pair of annotaions in 'beacons', replace them with a variant box in the
    code. As we delete the annotations to replace them with GUI, keep the rowDeletedOffset
    updated.
  '''
  addAllVariants: (editor, beacons, rowDeletedOffset) ->
    variantList = []
    for b in beacons
      priorRow = rowDeletedOffset

      # First, recursively add any nested variant boxes of this variant box
      nested = b.nested
      grandchildren = []
      if nested.length > 0
        #cancel out end marker offset, since we are inside the range of that marker
        nestedOffset = rowDeletedOffset
        list_offset = @addAllVariants(editor, nested, nestedOffset)
        grandchildren = list_offset.list # list of new VariantViews
        rowDeletedOffset = list_offset.offset

      # Now, create this variant box
      v_offset = @addVariant(editor, b, priorRow, rowDeletedOffset)
      variant = v_offset.variant
      variantList.push variant
      rowDeletedOffset = v_offset.offset # update rowDeletedOffset
      for g in grandchildren # If there where nested, now add these to the current Variant
        variant.addedNestedVariant(g, variant.getModel().getCurrentVersion())

    #return
    {list: variantList, offset: rowDeletedOffset}



  '''
    Build a single Variant.
  '''
  addVariant: (editor, b, rowDeletedOffset, endDeleteOffset, title) ->
    if endDeleteOffset? == false
      endDeleteOffset = rowDeletedOffset

    # Get start and end annotation Point of beacon
    sb = b.start
    eb = b.end
    editorBuffer = editor.getBuffer()

    # create a marker for this range so that we can keep track
    range = [sb, eb]
    start = new Point(range[0].row - rowDeletedOffset, 0) # substract rowDeletedOffset
    end = new Point(range[1].row - endDeleteOffset - 1, range[1].column)
    range = [start, new Point(end.row, 100000000000)]
    range = editorBuffer.clipRange(range) # This is important! To end at the end of the last line.
    marker = editor.markBufferRange(range, invalidate: 'never')

    '''below, useful for debug!!!'''
    #dec = editor.decorateMarker(marker, type: 'highlight', class: 'highlight-red')
    #dec = editor.decorateMarker(marker, type: 'line-number', class: 'taro-line-connect')



    # get title from start annnotation
    rowStart = sb.row
    if not title?
      title = editorBuffer.lineForRow(rowStart - rowDeletedOffset)
      title = title.trim().substring(6)
    rowEnd = eb.row

    # now, delete annotation rows
    editorBuffer.deleteRow(rowStart - rowDeletedOffset)
    endDeleteOffset += 1
    editorBuffer.deleteRow(rowEnd - endDeleteOffset)
    endDeleteOffset += 1


    #finally, make the new variant!
    variant = new VariantView(editor, marker, title, @, @undoAgent, @provenanceAgent)
    marker.setProperties(myVariant: variant)
    #editor.decorateMarker(marker, type: 'line-number', class: 'taro-line-connect')
    @gutter.decorateGutter(marker, variant)

    headerElement = variant.getHeader()
    #console.log headerElement
    hRange = [start, new Point(end.row - 1, end.column)]
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
