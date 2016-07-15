global.jQuery = global.$ = require 'jquery'
require 'jquery-ui-browserify'
#$ = jQuery = require 'jquery'
#window.jQueryUI = require 'jquery-ui'
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
    block_pane = document.createElement('div')
    block_pane.classList.add('atomic-taro_block-pane')
    $(block_pane).sortable()
    $(block_pane).disableSelection()
    @element.appendChild(block_pane)
    segs = segmenter.getSegments()
    (@addQuestionBox(chunk.code
                     chunk.title
                     block_pane)) for chunk in segs

  getTitle: -> 'ExploratoryView'

  # Returns an object that can be retrieved when package is activated
  serialize: ->
    'todo'

  # Tear down any state and detach
  destroy: ->
    @element.remove()

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

  addQuestionBox: (codeText, codeTitle, block_pane) ->
      accordian = document.createElement('div')
      accordian.classList.add('atomic-taro_editor-box')
      boxHeader = document.createElement("h3")
      boxHeader.innerHTML = codeTitle
      #boxHeader.classList.add('atomic-taro_editor-box-header')
      accordian.appendChild(boxHeader)
      editorContainer = document.createElement('div')
      editorContainer.classList.add('atomic-taro_editor-box')
      te = document.createElement('atom-text-editor')
      model_editor = te.getModel()
      model_editor.insertText(codeText)
      editorContainer.appendChild(te)
      accordian.appendChild(editorContainer)
      $(accordian).click ->
         $(editorContainer).slideToggle('slow')
      block_pane.appendChild(accordian)
