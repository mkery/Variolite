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
Listeners = require './listeners'
Variant = require './segment-objects/variant-model'
VariantView = require './segment-objects/variant-view'
AnnotationProcessorBuffer = require './annotation-processor-buffer'
AtomicTaroToolPane = require './right-panel/atomic-taro-tool-pane'
UndoAgent = require './undo-agent'
ProgramProcessor = require './program-processor'
CommitTravelAgent = require './commit-travel-agent'
VariantFactory = require './variant-factory'
Output = require './output'
AnnotationAgent = require './annotation-agent'

'''
  TODO - rethink annotation-processor-buffer
       - get save working
       - get serialize/deserialize working again
'''

module.exports =
class AtomicTaroView

  constructor: (statePath, @filePath, @baseFolder, @fileName, @fileType, sourceEditor) ->
    # editors. The source editor is the editor of the original file.
    # The exploratory editor is uses our annotation processor buffer.
    #@filePath = @baseFolder+"/"+@fileName+"."+@fileType
    #console.log "BASE FILE IS ", @filePath
    @sourceEditor = sourceEditor
    @exploratoryEditor = atom.workspace.getActiveTextEditor() #sourceEditor #null

    @variantListeners = null # holds jquery listeners

    # The master variant is a top level variant that wraps the entire file
    @masterVariant = null

    @variantFactory = null
    @undoAgent = new UndoAgent(50) #max undo entries
    @travelAgent = null
    @programProcessor = null # object to run code and record output
    @provenanceAgent = null #new ProvUtils()
    @annotationAgent = new AnnotationAgent(@baseFolder, @fileName)

    #divs
    @element = null
    @explorer = null
    @explorer_panel = null # the Panel object of @explorer

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
    $('.showVariantsButton').text("hide")


  closeExplorerView: ->
    @explorer_panel.hide()
    $('.showVariantsButton').text("show")
    @masterVariant.updateWidth()


  toggleExplorerView: ->
    if @explorer_panel?
      if @explorer_panel.isVisible()
        @explorer_panel.hide()
        $('.showVariantsButton').text("show")
        @masterVariant.updateWidth()
      else
        @explorer_panel.show()
        $('.showVariantsButton').text("hide")

    else
      @explorer_panel = atom.workspace.addRightPanel({item: @explorer})
      $('.showVariantsButton').text("hide")

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
  registerOutput: (command, data) ->
    out = new Output(command, data)
    commitId = @masterVariant.registerOutput(out)
    out.setCommit(commitId)
    @explorer.registerOutput(out, commitId)


  registerErr: (command, data) ->
    out = new Output(command, data)
    #commitId = @masterVariant.registerOutput(out)
    #out.setCommit(commitId)
    @explorer.registerOutput(out)


  getTravelAgent: ->
    @travelAgent


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


  '''
    Run when tool is first opened, to put all the main div elements in place, while the
    variant informaiton may still be loading.
  '''
  initializeView: ->
    # exploratoryEditor is the python file modified to show our visualization things
    #@exploratoryEditor = @initExploratoryEditor(@sourceEditor)
    #@exploratoryEditor.getElement().setHeight(635) # WARNING HARD CODED!!!!
    @initCursorListeners()

    #root element
    #@element = document.createElement('div')
    #@element.classList.add('atomic-taro_pane')#, 'scroll-view')
    @element = @exploratoryEditor.getElement()

    @travelAgent = new CommitTravelAgent(@)
    @variantFactory = new VariantFactory(@filePath, @, @undoAgent, @provenanceAgent, @travelAgent, @annotationAgent)
    @masterVariant = @variantFactory.buildMasterVariant(@exploratoryEditor, @masterVariant)
    @travelAgent.setMasterVariant(@masterVariant)
    @annotationAgent.setMasterVariant(@masterVariant)
    @annotationAgent.load (annot) =>
      if annot?
        @exploratoryEditor.setText(annot)
      @variantFactory.initVariants(@exploratoryEditor, @masterVariant)


    # create a variant manager
    @variantListeners = new Listeners(@masterVariant, @)
    @programProcessor = new ProgramProcessor(@baseFolder, @filePath, @fileName, @)



  getWrapLineX: (editor) ->
    editorElement = editor.getElement()
    column = atom.config.get('editor.preferredLineLength', scope: editor.getRootScopeDescriptor())
    columnWidth = editorElement.getDefaultCharacterWidth() * column
    if editorElement.logicalDisplayBuffer
      columnWidth -= editorElement.getScrollLeft()
    else
      columnWidth -= editor.getScrollLeft()
    return Math.round(columnWidth)



  '''
    Run after the variant's have loaded in their meta-data, so that we can finish
    up building and display the tool.
  '''
  postInit_buildView: ->
      #@element.appendChild(@exploratoryEditor.getElement())
      wrapWidth = @getWrapLineX(@exploratoryEditor)

      @masterVariant.buildVariantDiv(wrapWidth)
      @variantListeners.addJqueryListeners()

      atom.views.addViewProvider AtomicTaroToolPane, (toolPane) ->
        toolPane.getElement()

      @explorer = new AtomicTaroToolPane(@masterVariant, @programProcessor, @travelAgent, @)
      @showExplorerView()

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


  wrapNewVariant: ->
    #console.log "WRAP NEW VARIANT"
    @variantFactory.wrapNewVariant(@exploratoryEditor, @masterVariant)


  '''
   This is the title that shows up on the tab in Atom
  '''
  getTitle: -> @fileName


  '''
    Since atom doesn't know how to save our editor, we manually set this up
  '''
  saveVariants: (e) ->
    #@exploratoryEditor.save()
    @annotationAgent.save()
