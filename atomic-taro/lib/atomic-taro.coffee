AtomicTaroView = require './atomic-taro-view'
{CompositeDisposable} = require 'atom'
url = require 'url'
path = require 'path'
fs = require 'fs'


module.exports = AtomicTaro =
  activeViews: null
  subscriptions: null
  focusedView: null

  activate: (state) ->
    @activeViews = [] # no active AtomicTaroView

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomic-taro:open': => @open()

    @subscriptions.add atom.commands.add 'atom-workspace', 'atomic-taro:taronewvariant', (e) => @taroWrapVariant(e)

    @subscriptions.add atom.commands.add 'atom-workspace', 'core:save', (e) =>
      @handleSaveEvent(e)

    @subscriptions.add atom.commands.add 'atom-workspace', 'core:save-as', (e) =>
      @handleSaveAsEvent(e)

    atom.workspace.onDidChangeActivePaneItem (e) =>
      newActiveID = atom.workspace.getActivePaneItem().id
      if @focusedView?.exploratoryEditor.id != newActiveID
        changeTo = null
        for view in @activeViews
          if view.exploratoryEditor.id == newActiveID
            changeTo = view
            break
        @focusedView?.loseTabFocus()
        @focusedView = changeTo
        if changeTo
          @focusedView.gainTabFocus()

    atom.workspace.onDidDestroyPaneItem (e) =>
      #console.log "Destroyed! "
      destroyed = e.item
      @activeViews = @activeViews.filter (view) => view.exploratoryEditor.id != destroyed.id
      #console.log @activeViews

  deactivate: ->
    @subscriptions.dispose()
    for view in @activeViews
      view.deactivate()
      view.destroy()


  serialize: ->
    for view in @activeViews
      atomicTaroViewState: view.serialize()


  taroWrapVariant: (e) ->
    #editor = atom.workspace.getActivePaneItem()
    #if editor instanceof AtomicTaroView
        #@atomicTaroView = editor
    @focusedView.wrapNewVariant(e)


  open: ->
    filePath = atom.workspace.getActiveTextEditor().getPath()
    # check if there is a view for this file already
    for view in @activeViews
      #console.log "active view ", view
      if view?.filePath == filePath
        return

    @addTaroView(filePath)


  addTaroView: (filePath) ->
    # check if the current file is a python file
    #uri = 'tarotaro://file'+atom.workspace.getActiveTextEditor().getPath()
    #if uri? #and path.extname(uri) is '.py'
    editor = atom.workspace.getActiveTextEditor()

    lastIndex = filePath.lastIndexOf('/')
    folder = filePath.substring(0, lastIndex)
    fileName = filePath.substring(lastIndex + 1)
    [fileBase, fileType] = fileName.split(".")
    metaFolder = folder + "/" + fileBase+"-meta"
    @mkdirSync(metaFolder) # If folder does not exist, creates a new folder

    atomicTaroView = new AtomicTaroView filePath, folder, fileName, metaFolder, editor

    #editor.taroView = atomicTaroView
    @activeViews.push atomicTaroView
    @focusedView = atomicTaroView


  handleSaveEvent: (e) ->
    editor = atom.workspace.getActiveTextEditor()
    for view in @activeViews
      #console.log "looking at taro view ", view, "with editor ", view.exploratoryEditor.id, " against ", editor.id
      if view.exploratoryEditor.id == editor.id
        #console.log "TARO VIEW FOUND ", editor.taroView
        #view = editor.taroView
        view.saveVariants(e)
        '''cereal = view.serialize()
        lastIndex = view.filePath.lastIndexOf('/')
        folder = view.filePath.substring(0, lastIndex)
        fileName = view.filePath.substring(lastIndex + 1).split(".")[0]
        console.log cereal
        fs.writeFile (folder+"/"+fileName+".taro"), JSON.stringify(cereal), (error) ->
          console.error("Error writing file", error) if error
        return'''

  handleSaveAsEvent: (e) ->
    console.log "SAVE AS"


  mkdirSync: (path) ->
    try
      fs.mkdirSync(path);
    catch e
      if e.code != 'EEXIST'
        #throw e
        console.log "Failed to create directory."
