CodeSegmenter = require './code-segmenter'

module.exports =
class AtomicTaroView

  constructor: (plainCodeEditor, {@fpath, @protocol}) ->
    console.log "creating new exploratory editor"
    #root element
    @element = document.createElement('div')
    @element.classList.add('atomic-taro_pane')
    segmenter = new CodeSegmenter plainCodeEditor.getText()
    header = segmenter.getHeader()
    @addHeaderBox(header)
    segs = segmenter.getSegments()
    (@addQuestionBox(chunk.code
                     chunk.title)) for chunk in segs

  getTitle: -> 'tarotaro'

  # Returns an object that can be retrieved when package is activated
  serialize: ->
    'todo'

  # Tear down any state and detach
  destroy: ->
    @element.remove()
    @element.destroy()

  getElement: ->
    @element

  addHeaderBox: (codeText) ->
    new_box = document.createElement('div')
    #new_box.classList.add('atomic-taro_header-box')
    te = document.createElement('atom-text-editor')
    model_editor = te.getModel()
    model_editor.insertText(codeText)
    new_box.appendChild(te)
    @element.appendChild(new_box)

  addQuestionBox: (codeText, codeTitle) ->
      new_box = document.createElement('div')
      new_box.classList.add('atomic-taro_editor-box')
      boxHeader = document.createElement('div')
      boxHeader.textContent = codeTitle
      boxHeader.classList.add('atomic-taro_editor-box-header')
      new_box.appendChild(boxHeader)
      te = document.createElement('atom-text-editor')
      model_editor = te.getModel()
      model_editor.insertText(codeText)
      new_box.appendChild(te)
      @element.appendChild(new_box)
