AtomicTaroView = require './atomic-taro-view'
{CompositeDisposable} = require 'atom'
url = require 'url'
path = require 'path'

module.exports = AtomicTaro =
  atomicTaroView: null
  modalPanel: null
  subscriptions: null
  plainCodeEditor: null #probably needs refactoring, keep track of prev pane (python file)

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomic-taro:open': => @open()

    '''
    We set up an opener such that if the user
    opens our package while on a python file, it
    will open our exploratory view of that python file.
    '''
    atom.workspace.addOpener (uriToOpen, plainCodeEditor) ->
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
      new AtomicTaroView plainCodeEditor, fpath: pathname, protocol
      #if path.extname(uri) is '.py'


  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomicTaroView.destroy()

  serialize: ->
    atomicTaroViewState: @atomicTaroView?.serialize()

  open: ->
    @addTaroView()

  addTaroView: ->
    # check if the current file is a python file
    uri = 'tarotaro://file'+atom.workspace.getActiveTextEditor().getPath()
    if uri? and path.extname(uri) is '.py'
      previousActivePane = atom.workspace.getActivePane()
      plainCodeEditor = atom.workspace.getActiveTextEditor()
      atom.workspace.open(uri, plainCodeEditor, split: 'right', searchAllPanes: true).done (view) ->
          previousActivePane.activate()
