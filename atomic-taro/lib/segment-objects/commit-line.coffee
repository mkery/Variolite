{Point, Range, TextBuffer} = require 'atom'



module.exports =
class CommitLine

  constructor: (@variantView, @variantModel) ->
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


  updateWidth: (width) ->
    $(@commitLineElem).width(width)
    paddT = $(@commitTraveler).innerWidth() - $(@commitTraveler).width()
    $(@commitTraveler).width(width - paddT)


  '''
    Show the commit timeline to view and travel between commits.
  '''
  toggleCommitTimeline: ->
    if $(@commitLineElem).is(":visible")
      $(@commitLineElem).hide()
      return false
    else
      $(@commitLineElem).width($(@commitLineElem).parent().width())
      paddT = $(@commitTraveler).innerWidth() - $(@commitTraveler).width()
      $(@commitTraveler).width($(@commitLineElem).width() - paddT)
      commitNum = @getModel().getCurrentVersion().getNumberOfCommits()
      #console.log @getModel().getCurrentVersion()

      if commitNum > 0
        if $(@tickMarkers).children('.atomic-taro_commit-ticks').length != commitNum
            #$(@nowMarker).show()
            $(@nowBracket).show()
            $(@tickMarkers).html("")
            $(@commitTraveler).removeClass("textOnly")
            $(@noCommits).html("")
            $(@commitSlider).slider({
              max: commitNum,
              min: 0,
              value: commitNum,
              slide: (event, ui) =>
                if ui.value == @getModel().getCurrentVersion().getNumberOfCommits()
                  @getVariantView().backToTheFuture()
                else
                  @getVariantView().travelToCommit({commitID: ui.value, verID: @getModel().getCurrentVersion().id})
            })
            #console.log "commit num: "+commitNum+" ticks: "+$(@commitSlider).children('.atomic-taro_commit-ticks').length
            #console.log "WIDTH "+$(@commitTraveler).width()
            # Add ticks to label the timeline
            offset = 0
            for i in [0 .. commitNum - 1]
              offset -= 4
              label = document.createElement('div')
              label.classList.add('atomic-taro_commit-ticks')
              $(label).css('left',(i/commitNum*$(@commitTraveler).width() + offset))
              $(@tickMarkers).append(label)

      else
        $(@commitTraveler).addClass("textOnly")
        $(@noCommits).html("No commits to show yet!")
      $(@commitLineElem).show()
      return true
