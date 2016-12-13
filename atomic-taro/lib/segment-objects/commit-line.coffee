{Point, Range, TextBuffer} = require 'atom'



module.exports =
class CommitLine

  constructor: (@variantView, @variantModel) ->
    @initialized = false
    @addCommitLine() # initialize commit line

  getVariantView: ->
    @variantView

  getModel: ->
    @variantModel

  addCommitLine: () ->
    @commitLineElem = document.createElement('div')
    @commitLineElem.classList.add('atomic-taro_commit-element')
    @commitTraveler = document.createElement('div')
    @commitTraveler.classList.add('atomic-taro_commit-traveler')
    @commitSlider = document.createElement('div')
    @commitSlider.classList.add('commit-slider')
    @tickMarkers = document.createElement('div')
    @commitSlider.appendChild(@tickMarkers)
    @commitTraveler.appendChild(@commitSlider)
    @noCommits = document.createElement('div')
    @commitTraveler.appendChild(@noCommits)
    @nowBracket = document.createElement('div')
    @nowBracket.classList.add('atomic-taro_commit-nowBracket')
    $(@nowBracket).data("commitLine", @)
    @commitTraveler.appendChild(@nowBracket)
    $(@nowBracket).hide()

    # @nowMarker = document.createElement('div')
    # @nowMarker.classList.add('atomic-taro_commit-nowMarker')
    # $(@nowMarker).html("now")
    # $(@nowMarker).hide()
    @commitLineElem.appendChild(@commitTraveler)
    #@commitLineElem.appendChild(@nowMarker)
    $(@commitLineElem).hide()



  getElement: ->
    @commitLineElem


  addClass: ->
    $(@commitTraveler).addClass('historical')

  removeClass: ->
    $(@commitTraveler).removeClass('historical')



  redraw: ->
    if $(@commitLineElem).is(":visible")
      @drawTimeline()


  '''
    Show the commit timeline to view and travel between commits.
  '''
  toggleCommitTimeline: ->
    if $(@commitLineElem).is(":visible")
      #$(@commitLineElem).hide()
      $(@commitLineElem).slideUp('fast')
      return false
    else
      @drawTimeline()
      return true


  drawTimeline: ->
      @initialized = true
      #$(@commitLineElem).width($(@commitLineElem).parent().width())
      #paddT = $(@commitTraveler).innerWidth() - $(@commitTraveler).width()
      #$(@commitTraveler).width($(@commitLineElem).width() - paddT)
      commitNum = @getModel().getCurrentVersion().getNumberOfCommits()
      currentCommit = @getModel().getCurrentVersion().getCurrentCommit()
      if currentCommit == -1 # no commit
        currentCommit = commitNum
      #console.log @getModel().getCurrentVersion()

      if commitNum > 0
        if $(@tickMarkers).children('.atomic-taro_commit-ticks').length != commitNum
            #$(@nowMarker).show()
            $(@nowBracket).show()
            $(@commitTraveler).removeClass("textOnly")
            $(@noCommits).html("")
            $(@commitSlider).slider({
              max: commitNum,
              min: 0,
              value: currentCommit,
              slide: (event, ui) =>
                #console.log @variantView.getTitle(), " SLIDER ", ui.value
                if ui.manual != true
                  if ui.value == @getModel().getCurrentVersion().getNumberOfCommits()
                    @getModel().travelToCommit({commitID: @getModel().PRESENT, branchID: @getModel().getCurrentVersion().id})
                    @getVariantView().getTravelAgent().resetEnvToPresent()
                  else
                    @getModel().travelToCommit({commitID: ui.value, branchID: @getModel().getCurrentVersion().id})
                    @getVariantView().getTravelAgent().setEnvToCommit(@getModel(), {commitID: ui.value, branchID: @getModel().getCurrentVersion().id})

            })
            #console.log "commit num: "+commitNum+" ticks: "+$(@commitSlider).children('.atomic-taro_commit-ticks').length
            #console.log "WIDTH "+$(@commitTraveler).width()
            # Add ticks to label the timeline
            @addTickMarks(commitNum)
      else
        $(@commitTraveler).addClass("textOnly")
        $(@noCommits).html("No commits to show yet!")
      $(@commitLineElem).show()
      #$(@commitLineElem).slideDown('fast')



  slideToPresent: ->
    # don't bother if timeline hasn't been constructed
    if @initialized
      max = @getModel().getCurrentVersion().getNumberOfCommits()
      $(@commitSlider).slider('option', 'value',max)
      $(@commitSlider).slider('option','slide')
         .call($(@commitSlider),null,{ manual: true, handle: $('.ui-slider-handle', $(@commitSlider)), value: max })


  manualSet: (commitNum) ->
    # don't bother if timeline hasn't been constructed
    if @initialized
      #console.log "MANUAL SET CALLED ", commitNum
      $(@commitSlider).slider('option', 'value',commitNum)
      $(@commitSlider).slider('option','slide')
         .call($(@commitSlider),null,{ manual: true, handle: $('.ui-slider-handle', $(@commitSlider)), value: commitNum })



  addTickMarks: (commitNum) ->
    $(@tickMarkers).html("")
    offset = 0
    for i in [0 .. commitNum - 1]
      offset -= 4
      label = document.createElement('div')
      label.classList.add('atomic-taro_commit-ticks')
      $(label).css('left',(i/commitNum*$(@commitTraveler).width() + offset))
      $(@tickMarkers).append(label)
