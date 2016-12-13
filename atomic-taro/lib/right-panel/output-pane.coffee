{Point, Range, TextBuffer} = require 'atom'
Variant = require '../segment-objects/variant-model'
VariantView = require '../segment-objects/variant-view'


module.exports =
class OutputPane


  constructor: (@masterVariant, @programProcessor, @travelAgent, @atomicTaroView) ->
    @pane = document.createElement('div')
    @pane.classList.add('atomic-taro_explore-pane')
    @pane.classList.add('native-key-bindings');
    @outputList = document.createElement('div')

    @initialize()
    @travelAgent.setOutputPane(@)


  initialize: ->
    @pane.appendChild(@makeTitleDiv())
    @pane.appendChild(@outputList)
    @pane.appendChild(@makeContextMenu())
    @addJqueryListeners()


  # Gets the root element
  getElement: ->
    @pane

  getWidth: ->
    $(@pane).width()

  makeTitleDiv: ->
    titleBox = document.createElement('div')
    titleBox.classList.add('atomic-taro_explore-title-container')
    titleBox.classList.add('active')
    titleText = document.createElement('span')
    $(titleText).text("Output")

    xIcon = document.createElement('span')
    xIcon.classList.add('icon-x')
    xIcon.classList.add('atomic-taro_explore')
    xIcon.classList.add('text-smaller')
    $ => $(document).on 'click', '.icon-x.atomic-taro_explore', (ev) =>
      console.log "clicked exit!!!"
      @atomicTaroView.closeExplorerView()

    titleBox.appendChild(titleText)
    titleBox.appendChild(xIcon)
    # titleBox.appendChild(playButton)
    titleBox


  registerOutput: (data, commit) ->
    $('.atomic-taro_output_box').removeClass('newest')
    outputContainer = document.createElement('div')
    outputContainer.classList.add('list-item')
    outputContainer.classList.add('atomic-taro_output_box')
    outputContainer.classList.add('newest')
    $(outputContainer).text(data)
    $(outputContainer).data('commit', commit)
    $(outputContainer).click (ev) ->
      console.log 'clicked with ctrl?', ev.ctrlKey


    outDate = document.createElement('div')
    outDate.classList.add('atomic-taro_output_date')
    $(outDate).text(@dateNow()+" commit "+commit.commitID)
    outputContainer.appendChild(outDate)

    @outputList.appendChild(outputContainer)


  backToTheFuture: ->
    $('.atomic-taro_output_box').removeClass('travel')


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
    $(document).on 'click', '.atomic-taro_output_box', (ev) ->
      $('.atomic-taro_output_box').removeClass('selected')
      $(this).addClass('selected')
      ev.stopPropagation()

    $(document).on 'dblclick', '.atomic-taro_output_box', {'travelAgent': @travelAgent}, (ev) ->
      $('.atomic-taro_output_box').removeClass('selected')
      $('.atomic-taro_output_box').removeClass('travel')
      $(this).addClass('travel')
      commit = $(this).data('commit')
      ev.data.travelAgent.travelToGlobalCommit(commit)
      console.log "return to commit ", commit
      ev.stopPropagation()

    $(document).on 'mousedown', '.atomic-taro_output_box', {'menu': @rightClickMenu}, (ev) ->
      if ev.which != 1
        console.log "right click!"
        ev.stopPropagation()
        $(ev.data.menu).show()
        $(ev.data.menu).offset({left:ev.pageX,top:ev.pageY})
        $(ev.data.menu).data('output', this)

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
