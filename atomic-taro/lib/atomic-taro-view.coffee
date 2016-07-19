global.jQuery = global.$ = require 'jquery'
require 'jquery-ui-browserify'
#$ = jQuery = require 'jquery'
#window.jQueryUI = require 'jquery-ui'
{TextBuffer} = require 'atom'
{ScrollView} = require 'atom-space-pen-views'
CodeSegmenter = require './code-segmenter'
SegmentedBuffer = require './segmented-buffer'

module.exports =
class AtomicTaroView extends ScrollView
  @plainCodeEditor

  constructor: (plainCodeEditor, {@fpath, @protocol}) ->
    @plainCodeEditor = plainCodeEditor
    console.log "creating new exploratory editor"
    #root element
    @element = document.createElement('div')
    @element.classList.add('atomic-taro_pane')
    segmenter = new CodeSegmenter plainCodeEditor.getText()
    header = segmenter.getHeader()
    @addHeaderBox(header)
    block_pane = document.createElement('div')
    block_pane.classList.add('atomic-taro_block-pane')
    $(block_pane).sortable()#(items: '> .atomic-taro_editor-box, :not(.atomic-taro_editor-textEditor-box)', axis: 'y')
    $(block_pane).disableSelection()
    @element.appendChild(block_pane)
    segs = segmenter.getSegments()
    #chunk = segs[0]
    (@addQuestionBox(chunk.code
                     chunk.title
                     block_pane)) for chunk in segs
    @addJqueryListeners()

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
    model_editor = atom.workspace.buildTextEditor(grammar: atom.grammars.selectGrammar("file.py"))#filePath: @plainCodeEditor.getPath()))
    te = model_editor.getElement()
    model_editor.insertText(codeText)
    new_box.appendChild(te)
    @element.appendChild(new_box)

  addQuestionBox: (codeText, codeTitle, block_pane) ->
      #container for entire block
      blockDiv = document.createElement('div')
      blockDiv.classList.add('atomic-taro_editor-box')
      #container for header information like title, meta-data
      headerContainer = document.createElement('div')
      headerContainer.classList.add('atomic-taro_editor-header-box')
      @addQuestionBox_header(codeTitle, headerContainer)
      blockDiv.appendChild(headerContainer)
      #container for code editor
      editorContainer = document.createElement('div')
      editorContainer.classList.add('atomic-taro_editor-textEditor-box')
      model_editor = atom.workspace.buildTextEditor(buffer: new SegmentedBuffer(text: codeText), grammar: atom.grammars.selectGrammar("file.py"))#filePath: @plainCodeEditor.getPath()))
      te = model_editor.getElement()
      
      editorContainer.appendChild(te)
      blockDiv.appendChild(editorContainer)
      #make block expand/minimize by clicking on the header
      $(headerContainer).click ->
         $(editorContainer).slideToggle('slow')
      #finally, add to window container for all blocks
      block_pane.appendChild(blockDiv)

    addQuestionBox_header: (codeTitle, headerContainer) ->
      boxHeader = document.createElement("div")
      boxHeader.classList.add('atomic-taro_editor-header')
      $(boxHeader).text(codeTitle)
      headerContainer.appendChild(boxHeader)

    addJqueryListeners: ->
      #----this prevents dragging the whole block from the code editor section
      $ -> $('.atomic-taro_editor-textEditor-box').on 'mousedown', (ev) ->
        ev.stopPropagation()

      #--------------make header title editable
      $ -> $('.atomic-taro_editor-header').on 'click', (ev) ->
        ev.stopPropagation()
        if $(this).children().length == 0
          name = $(this).text()
          $(this).data("section-title", String(name))
          $(this).html('')
          $('<input></input').attr({
                'type': 'text',
                'name': 'fname',
                'class': 'txt_sectionname',
                'size': '30',
                'value': name
            }).appendTo(this)
          $('.txt_sectionname').focus()
      #--------------make header title editable cont'
      $(@element).on 'blur', '.txt_sectionname', ->
        name = $(this).val()
        if /\S/.test(name)
          $(this).parent().text(name)
        else
          $(this).text($(this).data("section-title"))
      #--------------make header title editable cont'
      $ -> $('.atomic-taro_editor-header').on 'keyup', (e) ->
        if(e.keyCode == 13)
          name = $(this).children(".txt_sectionname").val() #$('#txt_sectionname').val()
          if /\S/.test(name)
            $(this).text(name)
          else
            $(this).text($(this).data("section-title"))
