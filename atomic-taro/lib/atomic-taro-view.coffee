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
Variant = require './segment-objects/variant'
VariantView = require './segment-objects/variant-view'
AnnotationProcessorBuffer = require './annotation-processor-buffer'
VariantExplorerPane = require './right-panel/variant-explorer-pane'
AtomicTaroToolPane = require './right-panel/atomic-taro-tool-pane'
UndoAgent = require './undo-agent'
ProgramProcessor = require './program-processor'

module.exports =
class AtomicTaroView


  constructor: (statePath, @filePath, @fileName, @fileType, sourceEditor) ->
    @sourceEditor = sourceEditor
    @exploratoryEditor = null
    @variantWidth = null
    @variantManager = null
    @masterVariant = null

    @undoAgent = new UndoAgent(50) #max undo entries
    @programProcessor = null

    #divs
    @element = null
    @explorer = null
    @explorer_panel = null
    # try to get saved meta data for this file, if there is any
    @initializeView()
    @deserialize(statePath)


  deactivate: ->
    @masterVariant.deactivate()

  saveActiveItemAs: ->
    console.log "save as!"

  # Returns an object that can be retrieved when package is activated
  serialize: ->
    variants: @masterVariant?.serialize()


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

  saveAs: (newItemPath) ->
    console.log "asked me to save!!!"


  save: ->
    console.log "asked me to save!!!"


  getURI: ->
    @filePath


  getPath: ->
    @filePath


  getWidth: ->
    @exploratoryEditor.getElement().getWidth() - 20


  getMasterVariant: ->
    @masterVariant


  postInit_buildView: ->
      @element.appendChild(@exploratoryEditor.getElement())
      #console.log "HEIGHT??"
      #console.log @exploratoryEditor.getElement().getHeight()
      #console.log @exploratoryEditor.getElement().getScrollHeight()
      #$(@exploratoryEditor.getElement()).css('overflow-y', 'scroll')

      #console.log "master Variant"
      #console.log @masterVariant
      @masterVariant.buildVariantDiv()
      @variantManager.addJqueryListeners()

      atom.views.addViewProvider AtomicTaroToolPane, (toolPane) ->
        toolPane.getElement()

      @explorer = new AtomicTaroToolPane(@masterVariant, @programProcessor, @)

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
    @masterVariant.updateVariantWidth(@getWidth())
    @explorer_panel.isVisible()

  initializeView: ->
    # exploratoryEditor is the python file modified to show our visualization things
    @exploratoryEditor = @initExploratoryEditor(@sourceEditor)
    @exploratoryEditor.getElement().setHeight(635) # WARNING HARD CODED!!!!
    @initCursorListeners()

    #root element
    @element = document.createElement('div')
    @element.classList.add('atomic-taro_pane')#, 'scroll-view')

    # alert element
    menuContainer = document.createElement('div')
    @mainMenu = document.createElement('div')
    @mainMenu.classList.add('atomic-taro_main-menu')
    branchIcon = document.createElement('span')
    branchIcon.classList.add('icon-git-branch')
    branchIcon.classList.add('atomic-taro_main-menu_branchIcon')
    @runIcon = document.createElement('span')
    @runIcon.classList.add('icon-playback-play')
    @runIcon.classList.add('atomic-taro_main-menu_runIcon')
    @mainMenu.appendChild(branchIcon)
    @mainMenu.appendChild(@runIcon)
    @addVariantButtons(@mainMenu)
    $ => $(document).on 'mousedown', '.atomic-taro_main-menu_runIcon', (ev) =>
      $(@runIcon).addClass('click')
      @programProcessor.run()
      if not @explorer_panel?
        @explorer_panel = atom.workspace.addRightPanel({item: @explorer})
      if not @explorer_panel.isVisible()
        @explorer_panel.show()
      @variantManager.updateExplorerPanelShowing(@explorer_panel.isVisible(), @getWidth())
      @masterVariant.updateVariantWidth(@getWidth())
    $ => $(document).on 'mouseup', '.atomic-taro_main-menu_runIcon', (ev) =>
      $(@runIcon).removeClass('click')

    @alertPane = document.createElement('div')
    @alertPane.classList.add('atomic-taro_main-menu_alertBox')
    lockIcon = document.createElement('span')
    lockIcon.classList.add('icon-lock')
    lockIcon.classList.add('atomic-taro_commitLock')

    @commitAlertLabel = document.createElement('span')
    @commitAlertLabel.classList.add('atomic-taro_commitAlertLabel')
    $(@commitAlertLabel).text("commit N on 9/16/16 10:20pm")

    returnButton = document.createElement('span')
    returnButton.classList.add('atomic-taro_commitBackButton')
    clockIcon = document.createElement('span')
    clockIcon.classList.add('icon-arrow-left')
    returnButton.appendChild(clockIcon)
    $ => $(document).on 'click', '.atomic-taro_commitBackButton', (ev) =>
      @masterVariant.backToTheFuture()
      $('.atomic-taro_output_box').removeClass('travel')
      $(@alertPane).slideUp('fast')

    @alertPane.appendChild(returnButton)
    @alertPane.appendChild(lockIcon)
    @alertPane.appendChild(@commitAlertLabel)
    $(@alertPane).hide()

    menuContainer.appendChild(@mainMenu)
    menuContainer.appendChild(@alertPane)

    @element.appendChild(menuContainer)

    #@variantWidth = $(@element).width() - 20 #@sourceEditor.getElement().getWidth() - 20
    @initVariants(@exploratoryEditor, @element)

    # create a variant manager
    @variantManager = new VariantsManager(@masterVariant, @)
    @programProcessor = new ProgramProcessor(@filePath, @)

    #@element.appendChild(@exploratoryEditor.getElement())

    atom.contextMenu.add {'atom-pane': [{label: 'Copy Segment', command: 'atomic-taro:tarocopy'}]}
    atom.contextMenu.add {'atom-pane': [{label: 'Paste Segment', command: 'atomic-taro:taropaste'}]}
    atom.contextMenu.add {'atom-text-editor': [{label: 'Paste Segment', command: 'atomic-taro:taropaste'}]}

  addVariantButtons: () ->
    variantsButton = document.createElement("span")
    variantsButton.classList.add('main-menu_variantButton')
    variantsButton.classList.add('variants-button')
    $(variantsButton).text("variants")
    @mainMenu.appendChild(variantsButton)
    variantsMenu = document.createElement("div")
    variantsMenu.classList.add('variants-hoverMenu')
    $(variantsMenu).hide()
    variantsButton.appendChild(variantsMenu)

    buttonShow = document.createElement("div")
    buttonShow.classList.add('variants-hoverMenu-buttons')
    buttonShow.classList.add('showVariantsButton')
    $(buttonShow).text("show variant panel")
    $(buttonShow).data("variant", @)
    $(buttonShow).click (ev) =>
      ev.stopPropagation()
      @toggleExplorerView()
      $(variantsMenu).hide()
    variantsMenu.appendChild(buttonShow)

    buttonAdd = document.createElement("div")
    buttonAdd.classList.add('variants-hoverMenu-buttons')
    buttonAdd.classList.add('createVariantButton')
    $(buttonAdd).html("<span class='icon icon-repo-create'>new version</span>")
    $(buttonAdd).click =>
      @newVersion()
      $(variantsMenu).hide()
    variantsMenu.appendChild(buttonAdd)


  # init Exploratory Editor
  initExploratoryEditor: (sourceEditor) ->
    sourceCode = sourceEditor.getBuffer().getText()
    exploratoryEditor = atom.workspace.buildTextEditor(buffer: new AnnotationProcessorBuffer(text: sourceCode, undoAgent: @undoAgent, filePath: @filePath, variantView: @), grammar: atom.grammars.selectGrammar("file."+@fileType),  scrollPastEnd: true)
    atom.textEditors.add(exploratoryEditor)
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

  #getVariants: ->
  #  @variantManager.getVariants()

  sortVariants: ->
    @variantManager.sortVariants()

  copyVariant: (e) ->
    @variantManager.copyVariant(e)


  registerOutput: (data) ->
    commitId = @masterVariant.registerOutput(data)
    @explorer.registerOutput(data, commitId)


  travelToCommit: (commitId) ->
    $(@commitAlertLabel).text("viewing commit "+commitId.commitID)
    $(@alertPane).show()
    @masterVariant.travelToCommit(commitId)



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
      variant = new VariantView(@exploratoryEditor, marker, "v0", @, @undoAgent)
      marker.setProperties(myVariant: variant)
      headerElement = variant.getHeader()
      #console.log headerElement
      hRange = [start, new Point(end.row - 1, end.column)]
      hm = @exploratoryEditor.markBufferRange(hRange, invalidate: 'never', reversed: true)
      #editor.decorateMarker(hm, type: 'highlight', class: 'highlight-pink')
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
        @masterVariant.addNested(variant)


      '''if params?.undoSkip? == false
        varList = @variantManager.getVariants()
        variant = varList[varList.length - 1]
        @undoAgent.pushChange({data: {undoSkip: true}, callback: variant.dissolve})'''



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
    wholeFile = [new Point(0,0), new Point(10000000, 10000000)]
    range = @exploratoryEditor.getBuffer().clipRange(wholeFile)
    marker = editor.markBufferRange(range, invalidate: 'never')
    @masterVariant = new VariantView(@exploratoryEditor, marker, @fileName, @, @undoAgent)
    # b = {start: range.start, end: range.end, nested: []}
    # console.log "b is "
    # console.log b
    #@masterVariant = @addVariant(@exploratoryEditor, b, 0, 0, @fileName).variant


    list_offset = @addAllVariants(editor, beacons, 0, [])
    range = @exploratoryEditor.getBuffer().clipRange(range)
    @masterVariant.getModel().getMarker().setBufferRange(range)
    #console.log "RAnge: "+range

    curr = @masterVariant.getModel().getCurrentVersion()
    @masterVariant.addedNestedVariant(v, curr) for v in list_offset.list


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


  addAllVariants: (editor, beacons, rowDeletedOffset) ->
    variantList = []
    for b in beacons
      priorRow = rowDeletedOffset

      nested = b.nested
      grandchildren = []
      if nested.length > 0
        #cancel out end marker offset, since we are inside the range of that marker
        nestedOffset = rowDeletedOffset
        list_offset = @addAllVariants(editor, nested, nestedOffset)
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


  addVariant: (editor, b, rowDeletedOffset, endDeleteOffset, title) ->
    if endDeleteOffset? == false
      endDeleteOffset = rowDeletedOffset

    sb = b.start #startBeacon[i]
    eb = b.end #endBeacon[i]
    editorBuffer = editor.getBuffer()

    # create a marker for this range so that we can keep track
    range = [sb, eb]
    start = new Point(range[0].row - rowDeletedOffset, 0)
    end = new Point(range[1].row - endDeleteOffset - 1, range[1].column)
    range = [start, new Point(end.row, 100000000000)]
    range = editorBuffer.clipRange(range)
    marker = editor.markBufferRange(range, invalidate: 'never')

    '''below, useful for debug!!!'''
    #dec = editor.decorateMarker(marker, type: 'highlight', class: 'highlight-pink')

    # now, trim annotations
    #rowStart = sb.range.start.row
    rowStart = sb.row
    if not title?
      title = editorBuffer.lineForRow(rowStart - rowDeletedOffset)
      #get title from removed annotation
      title = title.trim().substring(6)
    #rowEnd = eb.range.end.row
    rowEnd = eb.row
    editorBuffer.deleteRow(rowStart - rowDeletedOffset)
    endDeleteOffset += 1
    editorBuffer.deleteRow(rowEnd - endDeleteOffset)
    endDeleteOffset += 1


    #finally, make the new variant!
    variant = new VariantView(editor, marker, title, @, @undoAgent)
    marker.setProperties(myVariant: variant)
    #editor.decorateMarker(marker, type: 'highlight', class: 'highlight-pink')

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
