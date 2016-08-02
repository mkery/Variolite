AtomicTaroView = require './atomic-taro-view'
{CompositeDisposable} = require 'atom'
url = require 'url'
path = require 'path'


#@todo @atomicTaroView isn't really keeping track of anything
module.exports = AtomicTaro =
  atomicTaroView: null
  modalPanel: null
  subscriptions: null
  plainCodeEditor: null #probably needs refactoring, keep track of prev pane (python file)
  filePath : null

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    # todo: find css selector for textBuffer so we can append the right click menu option there as well
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomic-taro:open': => @open()

    @subscriptions.add atom.commands.add 'atom-workspace', 'atomic-taro:tarocopy', (e) => @tarocopy(e)

    @subscriptions.add atom.commands.add 'atom-workspace', 'core:save', (e) =>
      @handleSaveEvent(e)

    '''
    We set up an opener such that if the user
    opens our package while on a python file, it
    will open our exploratory view of that python file.
    '''
    atom.workspace.addOpener (uriToOpen, plainCodeEditor) =>
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        console.log "opener failed"
        return

      return unless protocol is 'tarotaro:'
      console.log "opening a new exploratory editor"
      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return
      lastIndex = @filePath.lastIndexOf('/')
      folder = @filePath.substring(0, lastIndex)
      fileName = @filePath.substring(lastIndex + 1).split(".")[0]
      statePath = folder+"/"+fileName+".taro"
      @atomicTaroView = new AtomicTaroView statePath, plainCodeEditor, fpath: pathname, protocol
      @atomicTaroView


  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomicTaroView.destroy()

  serialize: ->
    atomicTaroViewState: @atomicTaroView?.serialize()

  tarocopy: (e) ->
    editor = atom.workspace.getActivePaneItem()
    if editor instanceof AtomicTaroView
        @atomicTaroView = editor
        @atomicTaroView.copyVariant(e)

  open: ->
    @addTaroView()

  addTaroView: ->
    # check if the current file is a python file
    @filePath = atom.workspace.getActiveTextEditor().getPath()
    uri = 'tarotaro://file'+atom.workspace.getActiveTextEditor().getPath()
    if uri? and path.extname(uri) is '.py'
      previousActivePane = atom.workspace.getActivePane()
      plainCodeEditor = atom.workspace.getActiveTextEditor()
      atom.workspace.open(uri, plainCodeEditor, split: 'right', searchAllPanes: true)#.done (view) ->
          #previousActivePane.activate()


  getAtomicTaroView: ->
    @atomicTaroView



  handleSaveEvent: (e) ->
    editor = atom.workspace.getActivePaneItem()
    if editor instanceof AtomicTaroView
        @atomicTaroView = editor
        @atomicTaroView.saveVariants(e)
        cereal = @serialize()
        lastIndex = @filePath.lastIndexOf('/')
        folder = @filePath.substring(0, lastIndex)
        fileName = @filePath.substring(lastIndex + 1).split(".")[0]

        fs.writeFile (folder+"/"+fileName+".taro"), JSON.stringify(cereal), (error) ->
          console.error("Error writing file", error) if error
