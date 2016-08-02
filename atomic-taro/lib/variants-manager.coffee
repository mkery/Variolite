SegmentView = require './segment-objects/segment-view'
Segment = require './segment-objects/segment'
SharedFunctionSegment = require './segment-objects/shared-function-segment'

{Point, Range, TextBuffer} = require 'atom'
VariantPartition = require './variant-partition'

'''
This class is essentially the model behind the atomic-taro-view, as it
manages all of the segments and all of their interactions.
'''
module.exports =
class VariantsManager

    constructor: (variants) ->
      # segments/header
      @variants = variants # for some reason this prevents duplicate blocks
      @addJqueryListeners()


    addJqueryListeners: (element) ->
      @addHeaderListeners(element)
      #@addScrollListeners(element)
      @addVariantsListeners(element)
      @addOutputListeners(element)
      #----this prevents dragging the whole block from the code editor section
      $ -> $('.atomic-taro_editor-textEditor-box').on 'mousedown', (ev) ->
        ev.stopPropagation()
      #---- todo make box resizable
      '''$ -> $(".atomic-taro_editor-textEditor-box").resizable (ev, ui) ->
        ui.size.height = ui.originalSize.height'''

    addOutputListeners: (element) ->
      $ -> $(document).on 'click', '.output-button', (ev) ->
        ev.stopPropagation()
        segment = $(this).data('segment')
        outputDiv = segment.getOutputsDiv()
        $(outputDiv).slideToggle('fast')

    addVariantsListeners: (element) ->
      #------------- hover for variants button
      $(document).on 'mouseenter', '.variants-button', ->
        hoverMenu = $(this).children('.variants-hoverMenu')
        hoverMenu.slideDown('fast')
        topPos = $(this).position().top + $(this).outerHeight() - hoverMenu.css('padding-top')
        hoverMenu.css({top : topPos+"px" })
      #------------- hover for variants button
      $(document).on 'mouseleave', '.variants-button', ->
        hoverMenu = $(this).children('.variants-hoverMenu')
        hoverMenu.slideUp('fast')

      #prevent dragging around or collapsing the header when interacting with these buttons
      $ -> $(document).on 'click', '.variants-hoverMenu-buttons', (ev) ->
        ev.stopPropagation()

      #prevent dragging around or collapsing the header when interacting with these buttons
      $ -> $(document).on 'click', '.atomic-taro_editor-header-buttons', (ev) ->
        ev.stopPropagation()



    addHeaderListeners: (element) ->
      #------sets header buttons to the full height of the header
      $ -> $('.atomic-taro_editor-header-buttons').each ->
        $(this).css('min-height', $('.atomic-taro_editor-header-box').outerHeight() - 2)
      @addHeaderTitleListeners(element)

    addHeaderTitleListeners: (element) ->
      #--------------make header title editable
      $(document).on 'dblclick', '.atomic-taro_editor-header-name', (ev) ->
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
      $(element).on 'blur', '.atomic-taro_editor-header-name', ->
        name = $(this).children(".txt_sectionname").val()
        #if /\S/.test(name)
        $(this).text(name)
        '''segment = $(this).data("segment")
          segment.setTitle(name)
        else
          $(this).text($(this).data("section-title"))'''
      #--------------make header title editable cont'
      $(element).on 'keyup', '.atomic-taro_editor-header-name', (e) ->
        if(e.keyCode == 13)# enter key
          name = $(this).children(".txt_sectionname").val() #$('#txt_sectionname').val()
          #if /\S/.test(name)
          $(this).text(name)
          '''segment = $(this).data("segment")
            segment.setTitle(name)
          else
            $(this).text($(this).data("section-title"))'''


    copySegment: (e) ->
      codeText = e.target.nextElementSibling.nextElementSibling.firstChild.model.buffer.lines
      len = codeText.length
      editorCopy = atom.workspace.buildTextEditor()#filePath: @plainCodeEditor.getPath()))
      fullCodeText = codeText.join("\n")
      codeRange = new Range(new Point(0, 0), new Point(len, 0))
      editorCopy.setTextInBufferRange(codeRange, fullCodeText)
      titleCopy = e.target.innerText.split("\n")[0] + " - copy"
      #currently have "null" for marker as we don't know where this copied segment will be marked in the original .py file
      copiedSegmentView = new SegmentView(null, editorCopy, null, titleCopy)
      copiedSegmentView.getModel().setCopied(true)
      @segments.push copiedSegmentView


    getPinned: ->
      @pinned

    resetPinned: ->
      for segment in @segments
        if segment.isPinned()
          segment.resetPinning()

    resetPinnedRemove: ->
      @pinned = []
      for segment in @segments
        if segment.isPinned()
          @pinned.push segment
          segment.resetPinning()

    # :( scroll is a pain.
    addScrollListeners: (element) ->
      $ =>
        element = $(element)
        offset_bottom = element.height() + element.offset().top
        $(@scrollBotDiv).css({top: offset_bottom+"px", width: element.width()+"px"})
        offset_top = element.offset().top
        $(@scrollTopDiv).css({ top: offset_top+"px", width: element.width()+"px"})
        console.log "placed scroll divs!!! "+$(@scrollTopDiv).position().bottom+"   ofset "+offset_top
        console.log "placed scroll divs!!! "+$(@scrollBotDiv).position().top+"   ofset "+offset_bottom

      $(element).on 'scroll', {'element': element, 'manager': @, 'scrollBotDiv': @scrollBotDiv, 'scrollTopDiv': @scrollTopDiv}, (ev) ->
        element = ev.data.element
        # list of all currently pinned segments
        segments = ev.data.manager.segments
        # the root element
        scrollTopDiv = ev.data.scrollTopDiv
        scrollBotDiv = ev.data.scrollBotDiv

        for segment in segments
          if segment.isPinned()
            header = $(segment.getHeader())
            if segment.isPinnedToTop()
              scrollPos = header.data("scrollPos")
              if $(element).scrollTop() < scrollPos
                segment.unPinFromTop()
            else if segment.isPinnedToBottom()
              scrollPos = header.data("scrollPos")
              if $(element).scrollTop() > scrollPos
                segment.unPinFromBottom()
            if header.position().top < ($(scrollTopDiv).position().top + $(scrollTopDiv).height())
                console.log "pinning to the top "+$(scrollTopDiv).position().bottom
                segment.pinToTop(scrollTopDiv, $(element).scrollTop())
            else if (header.position().top + header.height()) > ($(scrollBotDiv).position().top - $(scrollBotDiv).height())
                console.log "pinning to the bottom "+$(scrollBotDiv).position()
                segment.pinToBottom(scrollBotDiv, $(element).scrollTop())

      #----click the pin button
      $ => $('.icon-pin').on 'click', {'manager': @}, (ev) ->
        $(this).toggleClass('clicked')
        ev.stopPropagation()
        segment = $(this).data("segment")
        if $(this).hasClass('clicked')
          segment.pin()
        else
          segment.unPin()
