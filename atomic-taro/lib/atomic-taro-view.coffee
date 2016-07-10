
module.exports =
class AtomicTaroView

  constructor: (plainCodeEditor, {@fpath, @protocol}) ->
    #root element
    @element = document.createElement('div')
    @element.classList.add('atomic-taro_pane')


  getTitle: -> 'tarotaro'

  # Returns an object that can be retrieved when package is activated
  serialize: ->
    'todo'

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  addQuestionBox: (codeText) ->
      new_box = document.createElement('div')
      new_box.classList.add('atomic-taro_editor-box')
      boxHeader = document.createElement('div')
      boxHeader.textContent = "Block 1"
      boxHeader.classList.add('atomic-taro_editor-box-header')
      new_box.appendChild(boxHeader)
      te = document.createElement('atom-text-editor')
      model_editor = te.getModel()
      model_editor.setText(codeText)
      new_box.appendChild(te)
      @element.appendChild(new_box)
