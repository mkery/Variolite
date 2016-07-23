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
    topOffset : 0

    constructor: (sourceEditor) ->
      @segments = [] # for some reason this prevents duplicate blocks
      @sourceEditor = sourceEditor
      @sourceBuffer = sourceEditor.getBuffer()
      CodePartition cp = new CodePartition(@sourceEditor, @sourceBuffer, @header, @segments)
      cp.partition()
      @header = cp.getHeader()
      @segments = cp.getSegments()
      console.log("loaded???? "+@header+"  and segments: "+@segments.length)
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

    addScrollListeners: (element) ->
      $(element).on 'scroll', {'pinned': @pinned, 'scrollPinned': @scrollPinned, 'element': element}, (ev) ->
        pinned = ev.data.pinned
        scrollPinned = ev.data.scrollPinned
        element = ev.data.element
        offset_top = $(element).offset().top
        top_no_offset = 1
        if scrollPinned.length > 0
          temp2 = []
          for tuple in scrollPinned
            console.log "fixed "
            header = tuple.header
            scrollPos = tuple.scroll
            height = $(header).height()
            #console.log "poppin "+scrollPos+"  window: "+$(element).scrollTop()
            if $(element).scrollTop() < scrollPos
              console.log "poppin "+scrollPos+"  window: "+$(element).scrollTop()+" class "+header.hasClass('pinned')
              header.toggleClass('pinned')
              pinned.push(header)
            else
              offset_top += height
              top_no_offset += height
              temp2.push header
          scrollPinned = temp2

        if pinned.length > 0
          temp1 = []
          i = pinned.length
          while i > 0
            console.log "pinned "+pinned.length
            header = pinned[i]
            if header.position().top <= top_no_offset
              console.log "changing "
              header.toggleClass('pinned')
              header.css({ top: offset_top+"px", width: $(header).parent().width()+"px"});
              scrollPinned.push({'header': header, 'scroll': $(element).scrollTop()+0})
              offset_top += $(header).height()
              top_no_offset += $(header).height()
            else
              console.log "moving free"
              temp1.push header
          pinned = temp1

      #----click the pin button
      $ => $('.icon-pin').on 'click', {'pinned': @pinned}, (ev) ->
        $(this).toggleClass('clicked')
        ev.stopPropagation()
        #console.log $(this).position().top+"  position!"
        header = $(this).parent()
        #console.log "header is "+header
        pinned = ev.data.pinned
        if $(this).hasClass('clicked')
          pinned.push header
          #console.log "pinned "+pinned.length+ " "+pinned
        #header.toggleClass('pinned')
