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
    offset_top : null
    top_no_offset : null
    offset_bottom : null
    bottom_no_offset : null

    constructor: (sourceEditor) ->
      @segments = [] # for some reason this prevents duplicate blocks
      @sourceEditor = sourceEditor
      @sourceBuffer = sourceEditor.getBuffer()
      CodePartition cp = new CodePartition(@sourceEditor, @sourceBuffer, @header, @segments)
      cp.partition()
      @header = cp.getHeader()
      @segments = cp.getSegments()
      #first thing, partition the source file into segments

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

    incrementOffsetTop: (n) ->
      @offset_top += n
      @top_no_offset += n

    incrementOffsetBottom: (n) ->
      @offset_bottom += n
      @bottom_no_offset += n

    # :( scroll is a pain.
    addScrollListeners: (element) ->
      '''$ =>
        @offset_top = $(element).offset().top
        @top_no_offset = 0
        @offset_bottom = $(element).height() + $(element).offset().top
        @bottom_no_offset = $(element).height()'''


      $(element).on 'scroll', {'manager': @, 'element': element}, (ev) ->
        # list of all currently pinned segments
        pinned = ev.data.manager.pinned
        # the root element
        element = ev.data.element
        # offset accumulates, so that the segents stack on each other correctly
        offset_top = $(element).offset().top
        top_no_offset = 0
        for segment in pinned
          console.log "offsets TOP "+offset_top+"  no-offset: "+top_no_offset
          # header div of the pinned segment
          header = $(segment.getHeader())
          # ----- pinned to top
          if segment.isPinnedToTop()
            scrollPos = header.data("scrollPos")
            if $(element).scrollTop() < scrollPos
              segment.unPinFromTop()
              offset_top -= header.height()
              top_no_offset -= header.height()
            else if segment.isResetPinTop()
              console.log "reset top"
              segment.resetPinTop(offset_top, $(element).scrollTop())
          # ----- check: pin to top or bottom?
          else if header.position().top <= top_no_offset
              segment.pinToTop(offset_top, $(element).scrollTop())
              console.log "start pinning to top "+offset_top+" when height is "+header.height()
              offset_top += header.height()
              top_no_offset += header.height()

          ##############--- Bottom ---############
          offset_bottom = $(element).height() + $(element).offset().top
          bottom_no_offset = $(element).height()
          for i in [pinned.length - 1..0] by -1
            console.log "offsets BOTTOM "+offset_bottom+" no-offset: "+bottom_no_offset
            # ----- pinned to bottom
            if segment.isPinnedToBottom()
              scrollPos = header.data("scrollPos")
              if $(element).scrollTop() > scrollPos
                segment.unPinFromBottom()
                offset_bottom += header.height()
                bottom_no_offset += header.height()
              else if segment.isResetPinBottom()
                console.log "reset bottom"
                segment.resetPinBottom(offset_bottom, $(element).scrollTop())
            # ----- check: pin to top or bottom?
            else if (header.position().top + header.height()) >= bottom_no_offset
                offset_bottom -= header.height()
                bottom_no_offset -= header.height()
                segment.pinToBottom(offset_bottom, $(element).scrollTop())
                console.log "start pinning to bottom"

      #----click the pin button
      $ => $('.icon-pin').on 'click', {'manager': @}, (ev) ->
        $(this).toggleClass('clicked')
        ev.stopPropagation()
        segment = $(this).data("segment")
        pinned = ev.data.manager.getPinned()
        if $(this).hasClass('clicked')
          pinned.push segment
          segment.pin()
          ev.data.manager.resetPinned()
        else
          segment.unPin()
          ev.data.manager.resetPinnedRemove()
