{CompositeDisposable} = require 'atom'
AtomicTaroView = require './atomic-taro-view'


module.exports = AtomicTaro =
  atomicTaroView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomicTaroView = new AtomicTaroView(state.atomicTaroViewState)
    @modalPanel = atom.workspace.addModalPanel(
      item: this.atomicTaroView.getElement(),
      visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'wordcount:toggle': => @toggle()


  deactivate: ->
    @modalPanel.destroy();
    @subscriptions.dispose();
    @atomicTaroView.destroy();


  serialize: ->
      atomicTaroViewState: @atomicTaroView.serialize()


  toggle() {
    console.log 'AtomicTaro was toggled!'
    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
