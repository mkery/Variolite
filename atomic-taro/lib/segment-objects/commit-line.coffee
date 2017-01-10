{Point, Range, TextBuffer} = require 'atom'



module.exports =
class CommitLine

  constructor: (@variantView, @variantModel, width) ->
    @initialized = false
    @showing = false
    @addCommitLine(width) # initialize commit line

  getVariantView: ->
    @variantView

  getModel: ->
    @variantModel

  addCommitLine: (width) ->
    @commitLineElem = document.createElement('div')
    @commitLineElem.classList.add('atomic-taro_commit-element')
    $(@commitLineElem).width(width)

    @commitTraveler = document.createElement('div')
    @commitTraveler.classList.add('atomic-taro_commit-traveler')
    paddT = $(@commitTraveler).innerWidth() - $(@commitTraveler).width()
    $(@commitTraveler).width($(@commitLineElem).width() - paddT)

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
    @showing = false



  getElement: ->
    @commitLineElem


  addClass: ->
    $(@commitTraveler).addClass('historical')

  removeClass: ->
    $(@commitTraveler).removeClass('historical')



  redraw: ->
    #console.log "REDRAW!!! "
    if @showing == true
      #console.log "222 REDRAW 222 !!!"
      @drawTimeline()


  '''
    Show the commit timeline to view and travel between commits.
  '''
  toggleCommitTimeline: ->
    #console.log "TOGGLE SHOW COMMIT LINE ", @showing
    if @showing == true
      #$(@commitLineElem).hide()
      $(@commitLineElem).slideUp('fast')
      @showing = false
      return false
    else
      @drawTimeline()
      @showing = true
      return true


  drawTimeline: ->
      @initialized = true
      commitNum = @getModel().getCurrentVersion().getNumberOfCommits()
      currentCommit = @getModel().getCurrentVersion().getCurrentCommit()
      if currentCommit == -1 # no commit
        currentCommit = commitNum
      #console.log "commit line num ", @getModel().getCurrentVersion(), " num ", commitNum

      if commitNum > 0
        $(@commitSlider).show()
        $(@nowBracket).show()
        $(@commitTraveler).removeClass("textOnly")
        $(@noCommits).html("")
        if $(@tickMarkers).children('.atomic-taro_commit-ticks').length != commitNum
            $(@commitSlider).slider({
              max: commitNum,
              min: 0,
              value: currentCommit,
              slide: (event, ui) =>
                #console.log @variantView.getTitle(), " SLIDER ", ui.value
                if ui.manual != true
                  if ui.value == @getModel().getCurrentVersion().getNumberOfCommits()
                    @getModel().travelToCommit({commitID: @getModel().PRESENT, branchID: @getModel().getCurrentVersion().id})
                    @getVariantView().removeTravelStyle()
                    @getVariantView().getTravelAgent().resetEnvToPresent()
                  else
                    @getModel().travelToCommit({commitID: ui.value, branchID: @getModel().getCurrentVersion().id})
                    commit = @getModel().getCurrentVersion().getCurrentCommitObject()
                    @getVariantView().getTravelAgent().setEnvToCommit(@getModel(), commit)
                    @getVariantView().travelStyle(commit)

            })
            #console.log "commit num: "+commitNum+" ticks: "+$(@commitSlider).children('.atomic-taro_commit-ticks').length
            #console.log "WIDTH "+$(@commitTraveler).width()
            # Add ticks to label the timeline
            @addTickMarks(commitNum)
      else
        $(@commitTraveler).addClass("textOnly")
        $(@noCommits).html("No commits to show yet!")
        $(@commitSlider).hide()
        $(@nowBracket).hide()
      $(@commitLineElem).show()
      @showing = true
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
