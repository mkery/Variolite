
{Point, Range, TextBuffer} = require 'atom'
Variant = require './segment-objects/variant-model'
VariantView = require './segment-objects/variant-view'
'''
This class is essentially the model behind the atomic-taro-view, as it
manages all of the segments and all of their interactions.
'''
module.exports =
class Listeners

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


    deactivate: ->
      for v in @variants
        v.deactivate()


    addVariant: (v) ->
      @variants.push v


    getVariants: ->
      @variants


    registerOutput: (data) ->
      for v in @variants
        console.log "The current active versions"
        console.log v.getActiveVersionIDs()


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


    addJqueryListeners: (element) ->
      @variantWidth = $(@root.getElement()).width()
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

      #$(document).on 'mouseup', '.atomic-taro_editor-header_version-title', (ev) ->
      #  $(this).children('.atomic-taro_editor-header_x').show()

      $(document).on 'click', '.atomic-taro_editor-header_version-title', (ev) ->
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

      $(document).on 'mouseenter', '.atomic-taro_editor-header_version-title', (ev) ->
        $(this).children('.atomic-taro_editor-header_x').show()
      $(document).on 'mouseleave', '.atomic-taro_editor-header_version-title', (ev) ->
        $(this).children('.atomic-taro_editor-header_x').hide()


      $(document).on 'click', '.atomic-taro_editor-header_x', (ev) ->
          ev.stopPropagation()
          variant = $(this).data("variant")
          variant.archive()

      $(document).on 'click', '.atomic-taro_editor-active-button', (ev) ->
        $(this).addClass('clicked')
        v = $(this).data("variant")
        v.toggleActive()

      $(document).on 'click', '.atomic-taro_commit-history-button', (ev) ->
        v = $(this).data("commitLine")
        if v.toggleCommitTimeline()
          $(this).addClass('clicked')
        else
          $(this).removeClass('clicked')

      $(document).on 'click', '.atomic-taro_commit-branch-button', (ev) ->
        ev.stopPropagation()
        v = $(this).data("branchMap")
        if v.toggleBranchMap()
          $(this).addClass('clicked')
        else
          $(this).removeClass('clicked')


      $(document).on 'click', '.atomic-taro_commit-nowBracket', (ev) ->
          ev.stopPropagation()
          c = $(this).data("commitLine")
          c.slideToPresent()


      $(document).on 'click', '.atomic-taro_branch-map-square', (ev) ->
        ev.stopPropagation()
        # if $(this).hasClass('current')
        #   branch = $(this).data("branch")
        #   if branch.archive()
        #     $(this).removeClass('current')
        #     $(this).removeClass('active')
        if $(this).hasClass('active')
          $(this).parent().children('.atomic-taro_branch-map-square').removeClass('current')
          $(this).addClass('current')
          branch = $(this).data("branch")
          branch.switchToVersion()
        else
          $(this).addClass('active')
          branch = $(this).data("branch")
          branch.activateVersion()

    addHeaderListeners: (element) ->
      $(document).on 'mouseenter', '.atomic-taro_editor-header-wrapper', (ev) ->
        view = $(this).data('view')
        view.hover()
      $(document).on 'mouseleave', '.atomic-taro_editor-header-wrapper', (ev) ->
        view = $(this).data('view')
        view.unHover()

      $(document).on 'click', '.atomic-taro_diff-side-panel', (ev) ->
        ev.stopPropagation()
        $(this).children().focus()


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
