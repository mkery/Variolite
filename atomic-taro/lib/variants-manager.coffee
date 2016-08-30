
{Point, Range, TextBuffer} = require 'atom'
Variant = require './segment-objects/variant'
VariantView = require './segment-objects/variant-view'
'''
This class is essentially the model behind the atomic-taro-view, as it
manages all of the segments and all of their interactions.
'''
module.exports =
class VariantsManager

    constructor: (variants, @root, @undoAgent) ->
      # segments/header
      @variantWidth = null
      @focusedVariant = null
      @variants = variants # for some reason this prevents duplicate blocks


    serialize: ->
      cereal = []
      for v in @variants
        c = v.serialize()
        if c?
          cereal.push c
      variants: cereal

    deserialize: (varStates) ->
      #TODO when could perhaps the number of saved variants
      # not match up with code? If someone manually messes with
      # the variants? Needs more thought.
      if varStates?
        for i in [0...varStates.length]
          @variants[i].deserialize(varStates[i])

    buildVersionDivs: ->
      @variantWidth = $(@root.getElement()).width()
      for v in @variants
        v.buildVariantDiv()

      @addJqueryListeners()


    deactivate: ->
      for v in @variants
        v.deactivate()

    addVariant: (v) ->
      @variants.push v

    getVariants: ->
      @variants

    '''
    Sort variants by their marker location. This is helpful for dealing with things
    like offset at save time.
    '''
    sortVariants: ->
      @variants = @variants.sort (a, b) ->
        rangeA = a.getModel().getMarker().getBufferRange()
        startA = rangeA.start.row
        rangeB = b.getModel().getMarker().getBufferRange()
        startB = rangeB.start.row
        #console.log "sorting "+startA+", "+startB
        if startA < startB
          return -1
        if startA > startB
          return 1
        return 0

    getFocusedVariant: ->
      @focusedVariant

    setFocusedVariant: (selected, cursorPosition) ->
      v = null
      for marker in selected
        v = marker.getProperties().myVariant
        if v?
          v.unFocus()
          @focusedVariant = v
      v?.focus(cursorPosition)

    unFocusVariant: (v) ->
      @focusedVariant.unFocus()
      @focusedVariant = null

    updateExplorerPanelShowing: (showing, w) ->
      if showing
        $('.showVariantsButton').text("hide")
      else
        $('.showVariantsButton').text("show")
      @updateVariantWidth(w)

    updateVariantWidth: (w) ->
      for v in @variants
        v.updateVariantWidth(w)
      #$('.atomic-taro_editor-header-box').width(w)

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

      #$('.variants-button').hoverIntent (ev) ->
      $(document).on 'mouseenter', '.variants-button', (ev) ->
        hoverMenu = $(this).children('.variants-hoverMenu')
        hoverMenu.slideDown('fast')
        topPos = $(this).position().top + $(this).outerHeight() #+ hoverMenu.css('padding-top')
        rightPos = $(this).position().left - hoverMenu.width()/2
        hoverMenu.css({top : topPos+"px" , left : rightPos+"px"})
      $(document).on 'mouseleave', '.variants-button', ->
        hoverMenu = $(this).children('.variants-hoverMenu')
        hoverMenu.slideUp('fast')

      $(document).on 'click', '.icon-primitive-square', (ev) ->
        v = $(this).data("version")
        ev.stopPropagation()
        ev.preventDefault()
        variant = $(this).data("variant")
        if (ev.shiftKey)
         variant.highlightMultipleVersions(v)
        else
         v = $(this).data("version")
         variant = $(this).data("variant")
         variant.switchToVersion(v)


      $(document).on 'click', '.atomic-taro_editor-active-button', (ev) ->
        $(this).addClass('clicked')
        v = $(this).data("variant")
        v.toggleActive()

    addHeaderListeners: (element) ->
      $(document).on 'mouseenter', '.atomic-taro_editor-header-wrapper', (ev) ->
        view = $(this).data('view')
        view.hover()
      $(document).on 'mouseleave', '.atomic-taro_editor-header-wrapper', (ev) ->
        view = $(this).data('view')
        view.unHover()


      #------sets header buttons to the full height of the header
      $ -> $('.atomic-taro_editor-header-buttons').each ->
        $(this).css('min-height', $('.atomic-taro_editor-header-box').height())
      @addHeaderTitleListeners(element)

    addHeaderTitleListeners: (element) ->
      #--------------make header title editable
      $(document).on 'dblclick', '.version-title', (ev) ->
        console.log("title clicked! "+$(this).children())
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


      $(document).on 'click', '.version-title', (ev) ->
        if $(this).children().length > 0
          $('.txt_sectionname').focus()

      #--------------make header title editable cont'
      $(document).on 'blur', '.version-title', ->
        name = $(this).children(".txt_sectionname").val()
        if(name)
          #if /\S/.test(name)
          $(this).text(name)
          variant = $(this).data("variant")
          version = $(this).data("version")
          variant.setTitle(name, version)

      #--------------make header title editable cont'
      $(document).on 'keyup', '.txt_sectionname', (e) ->
        if(e.keyCode == 13)# enter key
          name = $(this).val() #$('#txt_sectionname').val()
          #if /\S/.test(name)
          $(this).parent().text(name)
          '''variant = $(this).parent().data("variant")
          version = $(this).parent().data("version")
          console.log $(this).parent()
          variant.setTitle(name, version)''' #TODO

        else
          text = String.fromCharCode(e.keyCode)
          txtarea = this
          strPos = txtarea.selectionStart
          front = (txtarea.value).substring(0,strPos);
          back = (txtarea.value).substring(strPos,txtarea.value.length)
          txtarea.value=front+text+back
          strPos = strPos + text.length
          txtarea.selectionStart = strPos;
          txtarea.selectionEnd = strPos;
          txtarea.focus();




      $(document).on 'keypress', '.txt_sectionname', (e) ->
        #e.stopPropagation()
        $(this).focus()
        ev = $.Event('keyup')
        ev.keyCode = e.keyCode
        $(this).focus().trigger(ev)

        e.preventDefault()




    copySegment: (e) ->
      if(e.target.outerHTML.includes("atomic-taro_editor-header-box"))
        i = 0
        for s in @segments
          #console.log s
          if(s instanceof ExploratorySegmentView)
            i++
            continue
          else if(s.getModel().getCopied() == true)
            s.getModel().setCopied(false)
            break
          else
            i++
        codeText = e.target.nextElementSibling.nextElementSibling.firstChild.model.buffer.lines
        len = codeText.length
        editorCopy = atom.workspace.buildTextEditor(grammar: atom.grammars.selectGrammar("file.py"))#filePath: @plainCodeEditor.getPath()))
        fullCodeText = codeText.join("\n")
        codeRange = new Range(new Point(0, 0), new Point(len, 0))
        editorCopy.setTextInBufferRange(codeRange, fullCodeText)
        titleCopy = e.target.innerText.split("\n")[0] + " - copy" #probably also want to add date or something else here in case they copy this block multiple times
        #currently have "null" for marker as we don't know where this copied segment will be marked in the original .py file
        copiedSegmentView = new SegmentView(null, editorCopy, null, titleCopy)
        copiedSegmentView.getModel().setCopied(true)
        @segments.push copiedSegmentView
        console.log copiedSegmentView
        '''for s in @segments
          console.log s'''
      else
        return

    pasteSegment: (e) ->
      #find the segment that is to be pasted - in order to be pasted it's gotta be copied
      i = 0
      for s in @segments
        #console.log s
        if(s instanceof ExploratorySegmentView)
          i++
          continue
        else if(s.getModel().getCopied() == true)
          break
        else
          i++
      console.log @segments[i] #this is the one!!!
      #so we need to append this new segment to the bottom of the editor
      #then we place a corresponding marker in the original .py file??
      #ye
      #console.log "made it to pasteSegment"
      #@segments[i].addSegmentDiv()

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
