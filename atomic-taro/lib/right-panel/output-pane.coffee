{Point, Range, TextBuffer} = require 'atom'
Variant = require '../segment-objects/variant-model'
VariantView = require '../segment-objects/variant-view'
require '../ui-helpers/jquery.hoverIntent.minified.js'

module.exports =
class OutputPane


  constructor: (@masterVariant, @programProcessor, @travelAgent, @atomicTaroView) ->
    @pane = document.createElement('div')
    @pane.classList.add('atomic-taro_explore-pane')
    @pane.classList.add('native-key-bindings');
    @outputList = document.createElement('div')
    @outputList.classList.add('atomic-taro_output-list-pane')

    @initialize()
    @travelAgent.setOutputPane(@)


  initialize: ->
    @pane.appendChild(@makeTitleDiv())
    @pane.appendChild(@outputList)
    @pane.appendChild(@makeContextMenu())
    @makeTerminal()
    @maketravelDiv()
    @addJqueryListeners()


  # Gets the root element
  getElement: ->
    @pane

  getWidth: ->
    $(@pane).width()


  makeTitleDiv: ->
    @titleBox = document.createElement('div')
    @titleBox.classList.add('atomic-taro_explore-title-container')
    @titleBox.classList.add('active')
    titleText = document.createElement('span')
    $(titleText).text("Output")

    xIcon = document.createElement('span')
    xIcon.classList.add('icon-x')
    xIcon.classList.add('atomic-taro_explore')
    xIcon.classList.add('text-smaller')
    $ => $(document).on 'click', '.icon-x.atomic-taro_explore', (ev) =>
      #console.log "clicked exit!!!"
      @atomicTaroView.closeExplorerView()

    @titleBox.appendChild(titleText)
    @titleBox.appendChild(xIcon)
    # @titleBox.appendChild(playButton)
    @titleBox


  registerOutput: (output, commit) ->
    $('.atomic-taro_output_box').removeClass('selected')
    $('.atomic-taro_output_box').removeClass('newest')
    outputContainer = document.createElement('div')
    outputContainer.classList.add('list-item')
    outputContainer.classList.add('atomic-taro_output_box')
    outputContainer.classList.add('newest')
    $(outputContainer).addClass('selected')

    command = document.createElement('div')
    command.classList.add('atomic-taro_output_command')
    $(command).text(output.command)
    outputContainer.appendChild(command)
    #$(command).hide()


    outData = document.createElement('span')
    $(outData).text(output.data)
    outputContainer.appendChild(outData)
    $(outputContainer).data('commit', commit)
    $(outputContainer).data('output', output)
    # $(outputContainer).click (ev) ->
    #   console.log 'clicked with ctrl?', ev.ctrlKey

    $(outputContainer).hoverIntent \
       (-> $(this).children('.atomic-taro_output-x').show()),\
       (-> $(this).children('.atomic-taro_output-x').hide())

    xIcon = document.createElement('div')
    xIcon.classList.add('icon-x')
    #xIcon.classList.add('atomic-taro_explore')
    xIcon.classList.add('atomic-taro_output-x')
    xIcon.classList.add('text-smaller')
    #$ => $(document).on 'click', '.icon-x.atomic-taro_explore', (ev) =>
    #  console.log "clicked exit!!!"
    $(xIcon).hide()
    outputContainer.appendChild(xIcon)

    if commit?
      outDate = document.createElement('div')
      outDate.classList.add('atomic-taro_output_date')
      $(outDate).text(commit.date+" commit "+commit.commitID)
      outputContainer.appendChild(outDate)
      $(outDate).hide()

    @outputList.appendChild(outputContainer)
    $(@outputList).scrollTop($(@outputList)[0].scrollHeight)

    return outputContainer


  resetToPresent: ->
    $('.atomic-taro_output_box').removeClass('travel')
    $(@travelWrapper).hide()


  setToCommit: (variant, commit) ->
    # show past outputs
    #console.log "SET OUTPUT PANE TO COMMIT ",commit
    out = commit.output
    $(@travelDiv).empty()
    for result in out
      @travelDiv.appendChild(@registerOutput(result, commit))
    $(@travelWrapper).slideDown('fast')


  makeTerminal: ->
    terminalWrapper = document.createElement('div')
    terminalWrapper.classList.add('atomic-taro_terminal-wrapper')

    # terminal = document.createElement('input')
    # terminal.type = "text"
    # terminal.placeholder = "terminal"
    # terminal.classList.add('input-text')
    # terminal.classList.add('atomic-taro_terminal')
    #
    # $(terminal).on 'keyup', (ev) =>
    #   if(ev.keyCode == 13) # enter/return key
    #     @programProcessor.run($(terminal).val())

    terminal = document.createElement('textarea')
    terminal.placeholder = "terminal"
    terminal.classList.add('input-textarea')
    terminal.classList.add('atomic-taro_terminal')

    $(terminal).on 'keyup', (ev) =>
      if(ev.keyCode == 38)# up key
        $(terminal).val(@programProcessor.getLast())
      else if(ev.keyCode == 13) # enter/return key
        @programProcessor.run($(terminal).val().slice(0, -1))
        $(terminal).val("")

    terminalWrapper.appendChild(terminal)
    @pane.appendChild(terminalWrapper)


  maketravelDiv: ->
    @travelWrapper = document.createElement('div')
    @travelWrapper.classList.add('atomic-taro_output_travel-wrapper')

    @travelDiv = document.createElement('div')
    @travelDiv.classList.add('atomic-taro_output_travel-div')

    label = document.createElement('div')
    label.classList.add('atomic-taro_explore-title-container')
    label.classList.add('active')
    label.classList.add('past')
    titleText = document.createElement('span')
    $(titleText).text("Output from this commit")

    xIcon = document.createElement('span')
    xIcon.classList.add('icon-dash')
    xIcon.classList.add('atomic-taro_explore')
    xIcon.classList.add('text-smaller')
    $ => $(document).on 'click', '.icon-dash.atomic-taro_explore', (ev) =>
      $(@travelDiv).hide()
      xIcon.classList.add('icon-file-add')
      $(xIcon).removeClass('icon-dash')

    $ => $(document).on 'click', '.icon-file-add.atomic-taro_explore', (ev) =>
      $(@travelDiv).show()
      xIcon.classList.add('icon-dash')
      $(xIcon).removeClass('icon-file-add')

    label.appendChild(titleText)
    label.appendChild(xIcon)
    @travelWrapper.appendChild(label)
    @travelWrapper.appendChild(@travelDiv)
    $(@travelWrapper).hide()
    @outputList.appendChild(@travelWrapper)



  tagCommit: (outputBox, tag) ->
    badge = document.createElement('span')
    badge.classList.add('badge')
    badge.classList.add('badge-info')
    $(badge).text(tag)
    outputBox.appendChild(badge)



  makeContextMenu: ->
    @rightClickMenu = document.createElement('div')
    @rightClickMenu.classList.add('atomic-taro_output-rmenu')

    travelBox = document.createElement('div')
    travelBox.classList.add('output-rmemu_itemBox')
    travelBox.classList.add('output-rmemu_travel')
    travel = document.createElement('span')
    $(travel).text("travel to commit")
    travelBox.appendChild(travel)

    tagBox = document.createElement('div')
    tagBox.classList.add('output-rmemu_itemBox')
    tagBox.classList.add('output-rmemu_tag')
    @tagText = document.createElement('input')
    @tagText.type = "text"
    @tagText.placeholder = "tag"
    @tagText.classList.add('tag-input-text')
    @tagText.classList.add('input-text')
    @tagText.classList.add('native-key-bindings')
    tagBox.appendChild(@tagText)

    @rightClickMenu.appendChild(tagBox)
    @rightClickMenu.appendChild(travelBox)
    $(@rightClickMenu).hide()
    @rightClickMenu



  dateNow: ->
    date = new Date()
    hour = date.getHours()
    sign = "am"
    if hour > 11
      sign = "pm"
      hour = hour%12

    minute = date.getMinutes();
    if minute < 10
      minute = "0"+minute
    $.datepicker.formatDate('mm/dd/yy', date)+" "+hour+":"+minute+sign




  addJqueryListeners: ->
    $(document).on 'click', '.atomic-taro_output-x', (ev) ->
      $(this).parent().remove()


    $(document).on 'click', '.atomic-taro_output_box', {'output-pane': @}, (ev) ->
      $('.atomic-taro_output_box').removeClass('selected')
      children = $(this).children('.atomic-taro_output_date')
      if children.is(":visible")
        #$(this).children('.atomic-taro_output_command').hide()
        children.slideUp('fast')
      else
        #$('.atomic-taro_output_date').hide()
        #$(this).children('.atomic-taro_output_command').show()
        children.slideDown('fast')
      $(this).addClass('selected')
      #ev.stopPropagation()

    $(document).on 'dblclick', '.atomic-taro_output_box', {'travelAgent': @travelAgent}, (ev) ->
      $('.atomic-taro_output_box').removeClass('selected')
      $('.atomic-taro_output_box').removeClass('travel')
      $(this).addClass('travel')
      commit = $(this).data('commit')
      if commit?
        ev.data.travelAgent.travelToGlobalCommit(commit)
        #console.log "return to commit ", commit
      ev.stopPropagation()

    $(document).on 'mousedown', '.atomic-taro_output_box', {'menu': @rightClickMenu}, (ev) ->
      if ev.which != 1
        console.log "right click!"
        ev.stopPropagation()
        $(ev.data.menu).show()
        $(ev.data.menu).offset({left:ev.pageX,top:ev.pageY})
        $(ev.data.menu).data('output', this)

    # $(document).on 'mouseover', '.atomic-taro_output_box', (ev) ->
    #   $(this).children('.atomic-taro_output_date').slideDown('fast')
    #   ev.stopPropagation()
    #
    # $(document).on 'mouseleave', '.atomic-taro_output_box', (ev) ->
    #   $(this).children('.atomic-taro_output_date').hide()
    #   ev.stopPropagation()

    $(document).on 'blur', '.output-rmemu_tag', (e) =>
      $(@rightClickMenu).hide()
      output = $(@rightClickMenu).data('output')
      @tagCommit(output, $(@tagText).val())
      @tagText.value = ""


    $(document).on 'keyup', '.tag-input-text', (e) =>
      if(e.keyCode == 13)# enter key
        $(@rightClickMenu).hide()
        output = $(@rightClickMenu).data('output')
        @tagCommit(output, $(@tagText).val())
        @tagText.value = ""


    $(document).on 'click', '.output-rmemu_travel', (ev) =>
      ev.stopPropagation()
      output = $(@rightClickMenu).data('output')
      $('.atomic-taro_output_box').removeClass('selected')
      $('.atomic-taro_output_box').removeClass('travel')
      $(output).addClass('travel')
      $(@rightClickMenu).hide()
      @masterVariant.travelToCommit($(output).data('commit'))
      #@travelToCommit()
