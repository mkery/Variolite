{Point, Range, TextBuffer} = require 'atom'
JsDiff = require('diff')

'''
Represents a single variant of exploratory code.
'''
module.exports =
class Variant


  constructor: (@sourceEditor, @marker, title) ->
    #the header div has it's own marker that must follow around the top of the main marker
    @headerMarker = null

    @copied = false

    text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    date = @dateNow()
    @currentVersion = {title: title, subtitle: 0, text: text, date: date, children: []}
    @rootVersion = @currentVersion
    #@versions = []
    #@versions.push @currentVersion
    @highlighted = []
    @highlightMarkers = []
    @overlapText = ""



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



  serialize: ->
    text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    @currentVersion.text = text

    currentVersion: @currentVersion
    rootVersion: @rootVersion
    #versions: @versions

  deserialize: (state) ->
    @currentVersion = state.currentVersion
    @rootVersion = state.rootVersion
    @walkVersions @rootVersion, (v) =>
      if v.title == @currentVersion.title
        @currentVersion = v
    #@currentVersion.date = state_currentVersion.date
    #TODO resolve if doesn't match text
    #@versions = []
    #state_versions = state.versions
    #for v in state_versions
    #  stored_ver = {title: v.title, text: v.text, date: v.date, children: v.children}
    #  @versions.push stored_ver
    #  if v.title == @currentVersion.title
    #    @currentVersion = stored_ver

  getMarker: ->
    @marker


  walkVersions: (version, fun) ->
    fun(version)
    for child in version.children
      @walkVersions(child, fun)


  setHeaderMarker: (hm) ->
    '''@headerMarker = hm
    @marker.onDidChange (ev) =>
      if ev.newTailBufferPosition != ev.oldTailBufferPosition
        console.log "backspace!!"
        @headerMarker.setHeadBufferPosition(ev.newTailBufferPosition)'''


  getRootVersion: ->
    #@versions
    @rootVersion


  getCurrentVersion: ->
    @currentVersion

  hasVersions: ->
    @rootVersion.children.length > 0


  highlighted: ->
    @highlighted



  newVersion: ->
    text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    @currentVersion.text = text
    subtitle = if @currentVersion.subtitle? then @currentVersion.subtitle else 0
    index = @currentVersion.title + "-" + (subtitle + 1)
    newVersion = {title: index, text: text, date: @dateNow(), children: []}
    #@versions.push newVersion
    @currentVersion.children.push newVersion
    @currentVersion = newVersion
    @clearHighlights()

  toggleActive: ->
    textSelection =  @marker.getBufferRange()
    #console.log textSelection
    selections = @sourceEditor.getSelections()
    #console.log selections
    selections[0].setBufferRange(textSelection)
    selections[0].toggleLineComments()
    @clearHighlights()
    #console.log textSelection
    #ideas - somehow create a selection and use the API to toggle comments. Problem with
    #this is I don't know how to create a selection and looking at the docs, it doesn't appear
    # you can just call a constructor on it
    #idea 2 - use reg expression to append comments to the beginning of lines
    #problem is how would we know to un-toggle those comments and not already existing
    #comments?
    #console.log "done with toggleActive"

  isHighlighted: (v) ->
    for h in @highlighted
      if h.title == v.title
        return true
    false

  clearHighlights: ->
    @highlighted = []
    @overlapText = ""
    for h in @highlightMarkers
      h.destroy()


  switchToVersion: (v) ->
    text = v.text
    @currentVersion.text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    @sourceEditor.setTextInBufferRange(@marker.getBufferRange(), v.text, undo: false)
    @currentVersion = v
    @clearHighlights()


  compareToVersion: (v) ->
    # first, switch to the new version
    compareFrom = @currentVersion
    text = v.text
    @currentVersion.text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    @sourceEditor.setTextInBufferRange(@marker.getBufferRange(), v.text, undo: false)
    @currentVersion = v

    # next, add
    @highlighted.push compareFrom
    textA = compareFrom.text
    if @overlapText != ""
      textA = @overlapText
    textB = v.text

    diff = JsDiff.diffLines(textA, textB)
    range = @marker.getBufferRange()
    start = range.start


    for line in diff
      if line.removed
        continue

      text = line.value
      lines = text.split("\n")
      rows = lines.length - 2
      cols = lines[lines.length - 2].length
      #console.log text + "has r " +rows + " c " + cols
      #console.log "start " + start
      end = new Point(start.row + rows, start.column + cols)
      #console.log text + ", start: " + start + ", end: " + end

      if !line.removed and !line.added
        # then text is in both versions
        #console.log "marker adding"
        mark = @sourceEditor.markBufferRange([start, end])
        dec = @sourceEditor.decorateMarker(mark, type: 'highlight', class: 'highlight-pink')
        @highlightMarkers.push mark
        @overlapText += text

      start = new Point(end.row + 1, 0)







  getTitle: ->
    @currentVersion.title



  setTitle: (title, version) ->
    version.title = title



  getDate: ->
    @currentVersion.date


  getText: ->
    @currentVersion.text



  setText: (text) ->
    @currentVersion.text = text



  getCopied: ->
    @copied



  setCopied: (bool) ->
    @copied = bool



  collapse: ->
    console.log "collaping variant"
    @sourceEditor.setSelectedBufferRange(@marker.getBufferRange())
    @sourceEditor.foldSelectedLines()
