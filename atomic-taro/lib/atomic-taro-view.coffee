# The following two set up jquery and jquery-ui (it will only work in
# this browserify version, probably because Atom itself is not a browser)
# If these do not work, install them locally using npm
global.jQuery = global.$ = require 'jquery'
require 'jquery-ui-browserify'

{TextBuffer} = require 'atom'
{ScrollView} = require 'atom-space-pen-views'
CodeSegmenter = require './code-segmenter'

module.exports =
class AtomicTaroView extends ScrollView

  constructor: (plainCodeEditor, {@fpath, @protocol}) ->
    # plainCodeEditor is the user's original python file
    plainCodeEditor = plainCodeEditor
    #root element
    @element = document.createElement('div')
    @element.classList.add('atomic-taro_pane')#, 'scroll-view')

    # chunk the original code into segments
    segmenter = new CodeSegmenter plainCodeEditor
    # the header is the code that occurs at the top of the file,
    # outside of segment boxes
    header = segmenter.getHeader()
    @addHeaderBox(header)
    # root container for segment boxes
    block_pane = document.createElement('div')
    block_pane.classList.add('atomic-taro_block-pane')
    $(block_pane).sortable({ axis: 'y' }) # < this allows blocks to be re-arranged
    $(block_pane).disableSelection()
    @element.appendChild(block_pane)
    segs = segmenter.getSegments()
    (@addQuestionBox(chunk.getEditor()
                     chunk.getTitle()
                     block_pane)) for chunk in segs
    @addJqueryListeners()

  # This is the title that shows up on the tab
  getTitle: -> 'ExploratoryView'

  # Returns an object that can be retrieved when package is activated
  serialize: ->
    'todo'

  # Tear down any state and detach
  destroy: ->
    @element.remove()


  getElement: ->
    @element

  addHeaderBox: (header) ->
    new_box = document.createElement('div')
    #new_box.classList.add('atomic-taro_header-box')
    model_editor = header.getEditor()
    te = model_editor.getElement()
    new_box.appendChild(te)
    @element.appendChild(new_box)

  addQuestionBox: (model_editor, codeTitle, block_pane) ->
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
      # create an editor element
      #model_editor = atom.workspace.buildTextEditor(buffer: new SegmentedBuffer(text: codeText), grammar: atom.grammars.selectGrammar("file.py"))#filePath: @plainCodeEditor.getPath()))
      te = model_editor.getElement()
      editorContainer.appendChild(te)
      blockDiv.appendChild(editorContainer)
      $(headerContainer).click ->
         $(editorContainer).slideToggle('slow')
      #finally, add to window container for all blocks
      block_pane.appendChild(blockDiv)

    addQuestionBox_header: (codeTitle, headerContainer) ->
      nameContainer = document.createElement("div")
      nameContainer.classList.add('atomic-taro_editor-header-name-container')
      boxHeader = document.createElement("div")
      boxHeader.classList.add('atomic-taro_editor-header-name')
      $(boxHeader).text(codeTitle)
      nameContainer.appendChild(boxHeader)
      #add placeholder for data
      dateHeader = document.createElement("div")
      $(dateHeader).text("7/16/19 7:04pm")
      dateHeader.classList.add('atomic-taro_editor-header-date')
      nameContainer.appendChild(dateHeader)
      headerContainer.appendChild(nameContainer)
      #add placeholders for versions and output
      outputBox = document.createElement("div")
      outputBox.classList.add('atomic-taro_editor-header-buttons')
      $(outputBox).text("in/output")
      headerContainer.appendChild(outputBox)
      variantsBox = document.createElement("div")
      variantsBox.classList.add('atomic-taro_editor-header-buttons')
      $(variantsBox).text("variants")
      headerContainer.appendChild(variantsBox)
      pin = document.createElement("span")
      pin.classList.add('icon-pin', 'pinButton')
      headerContainer.appendChild(pin)

    addJqueryListeners: ->
      '''$(@element).on 'scroll', ->
        #console.log "scrolled!"
        pinned = $('.pinned')
        if pinned.length > 0
          pane = atom.workspace.getActivePane()
          paneElement = atom.views.getView(pane)
          #console.log($('.pinned').html()+" pinned! scroll top "+$(@element).scrollTop())
          if pinned.position().top <=1
            paneElement.appendChild(pinned)
            #atom.workspace.addTopPanel(item: pinned, visible: true, priority: 10000000000)
      '''
      #----click the pin button
      $ -> $('.icon-pin').on 'click', (ev) ->
        $(this).toggleClass('clicked')
        #console.log $(this).position().top+"  position!"
        $(this).parent().toggleClass('pinned')
        ev.stopPropagation()

      #----sets header buttons to the full height of the header
      $ -> $('.atomic-taro_editor-header-buttons').each ->
        $(this).css('min-height', $('.atomic-taro_editor-header-box').outerHeight() - 2)

      #----this prevents dragging the whole block from the code editor section
      $ -> $('.atomic-taro_editor-textEditor-box').on 'mousedown', (ev) ->
        ev.stopPropagation()

      #--------------make header title editable
      $ -> $('.atomic-taro_editor-header-name').on 'click', (ev) ->
        console.log("title clicked!")
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
          $('.txt_sectionname').addClass('native-key-bindings')
      #--------------make header title editable cont'
      $(@element).on 'blur', '.txt_sectionname', ->
        name = $(this).val()
        if /\S/.test(name)
          $(this).parent().text(name)
        else
          $(this).text($(this).data("section-title"))
      #--------------make header title editable cont'
      $ -> $('.atomic-taro_editor-header-name').on 'keyup', (e) ->
        if(e.keyCode == 13)# enter key
          name = $(this).children(".txt_sectionname").val() #$('#txt_sectionname').val()
          if /\S/.test(name)
            $(this).text(name)
          else
            $(this).text($(this).data("section-title"))
