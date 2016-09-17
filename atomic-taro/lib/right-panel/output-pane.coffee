{Point, Range, TextBuffer} = require 'atom'
VariantsManager = require '../variants-manager'
Variant = require '../segment-objects/variant'
VariantView = require '../segment-objects/variant-view'


module.exports =
class OutputPane


  constructor: (@masterVariant, @programProcessor, @atomicTaroView) ->
    @pane = document.createElement('div')
    @pane.classList.add('atomic-taro_explore-pane')
    @outputList = document.createElement('div')

    @initialize()

  initialize: ->
    @pane.appendChild(@makeTitleDiv())
    @pane.appendChild(@outputList)
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
      @root.toggleExplorerView()

    # playButton = document.createElement('span')
    # playButton.classList.add('icon-playback-play')
    # playButton.classList.add('atomic-taro_explore-play-button')
    # $(playButton).click =>
    #   @programProcessor.run()

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

    outDate = document.createElement('div')
    outDate.classList.add('atomic-taro_output_date')
    $(outDate).text(@dateNow())
    outputContainer.appendChild(outDate)

    @outputList.appendChild(outputContainer)


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

    $(document).on 'dblclick', '.atomic-taro_output_box', {'atomicTaroView': @atomicTaroView}, (ev) ->
      $('.atomic-taro_output_box').removeClass('selected')
      $(this).addClass('selected')
      commit = $(this).data('commit')
      ev.data.atomicTaroView.travelToCommit(commit)
      console.log "return to commit "+commit
      ev.stopPropagation()
