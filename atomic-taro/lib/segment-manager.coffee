Segment = require './segment'
SharedFunctionSegment = require './shared-function-segment'
{Point, Range, TextBuffer} = require 'atom'
CodePartition = require './code-partition'

'''
This class is essentially the model behind the atomic-taro-view, as it
manages all of the segments and all of their interactions.
'''
module.exports =
class SegmentManager
    # source
    sourceEditor: null
    sourceBuffer: null
    # segments/header
    segments: []
    header: null
    # pinning
    pinned : []
    scrollPinned : []
    scrollTopDiv : null
    scrollBotDiv : null

    constructor: (sourceEditor, root) ->
      @segments = [] # for some reason this prevents duplicate blocks
      @sourceEditor = sourceEditor
      @sourceBuffer = sourceEditor.getBuffer()
      CodePartition cp = new CodePartition(@sourceEditor, @sourceBuffer, @header, @segments)
      cp.partition()
      @header = cp.getHeader()
      @segments = cp.getSegments()

      @scrollTopDiv = document.createElement('div')
      @scrollTopDiv.classList.add('scrollTopDiv')
      @scrollBotDiv = document.createElement('div')
      @scrollBotDiv.classList.add('scrollBotDiv')
      root.appendChild(@scrollTopDiv)
      root.appendChild(@scrollBotDiv)

    getSegments: ->
      @segments

    getHeader: ->
      @header

    saveSegments: (e) ->
      console.log "saving segments!"
      @sourceBuffer.save()

    addJqueryListeners: (element) ->
      @addHeaderListeners(element)
      @addScrollListeners(element)
      #----this prevents dragging the whole block from the code editor section
      $ -> $('.atomic-taro_editor-textEditor-box').on 'mousedown', (ev) ->
        ev.stopPropagation()

    addHeaderListeners: (element) ->
      #----sets header buttons to the full height of the header
      $ -> $('.atomic-taro_editor-header-buttons').each ->
        $(this).css('min-height', $('.atomic-taro_editor-header-box').outerHeight() - 2)
      @addHeaderTitleListeners(element)

    addHeaderTitleListeners: (element) ->
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
      $(element).on 'blur', '.txt_sectionname', ->
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
