{Point, Range, TextBuffer} = require 'atom'
JsDiff = require('diff')

'''
Represents a single variant of exploratory code.
'''
module.exports =
class Variant


  constructor: (@sourceEditor, @marker, title) ->
    @sourceBuffer = @sourceEditor.getBuffer()
    #the header div has it's own marker that must follow around the top of the main marker
    @headerMarker = null

    @copied = false

    text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    date = @dateNow()
    @currentVersion = {title: title, subtitle: 0, text: text, date: date, children: [], nested: []}
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

    #currentVersion: @currentVersion
    #rootVersion: @rootVersion
    rootVersion: if @rootVersion? then @serializeWalk(@rootVersion) else null
    currentVersion:  {title: @currentVersion.title}


  serializeWalk: (version) ->
    children = []
    if version.children.length > 0
      children = [@serializeWalk(c) for c in version.children]
    nested = [n.serialize() for n in version.nested]
    copy = {title: version.title, subtitle: version.subtitle, text: version.text, date: version.date, children: children, nested: nested}
    copy

  serializeNested: (version) ->



  deserialize: (state) ->
    @currentVersion = state.currentVersion
    @rootVersion = state.rootVersion
    @walkVersions @rootVersion, (v) =>
      if v.title == @currentVersion.title
        @currentVersion = v


  getMarker: ->
    @marker


  setHeaderMarker: (hm) ->
    @headerMarker = hm


  getHeaderMarker: ->
    @headerMarker


  walkVersions: (version, fun) ->
    fun(version)
    if version.children?
      for child in version.children
        @walkVersions(child, fun)


  getRootVersion: ->
    #@versions
    @rootVersion


  getCurrentVersion: ->
    @currentVersion


  hasVersions: ->
    @rootVersion.children.length > 0


  highlighted: ->
    @highlighted


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


  newVersion: ->
    # new text has clean text before we add marker placeholders
    newText = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    @setCurrentVersionText_Close()
    # currentVersion has text after we add marker placeholders
    @currentVersion.text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())

    # now, set the text for the new version we're switching to
    @sourceBuffer.setTextInRange(@marker.getBufferRange(), newText, undo: 'skip')

    subtitle = if @currentVersion.subtitle? then @currentVersion.subtitle else 0
    index = @currentVersion.title + "-" + (subtitle + 1)
    newVersion = {title: index, text: newText, date: @dateNow(), children: [], nested: []}
    #@versions.push newVersion
    @currentVersion.children.push newVersion
    @currentVersion = newVersion
    @clearHighlights()


  switchToVersion: (v) ->
    text = v.text
    @setCurrentVersionText_Close()
    @currentVersion.text = @sourceBuffer.getTextInRange(@marker.getBufferRange())
    @sourceBuffer.setTextInRange(@marker.getBufferRange(), v.text, undo: 'skip')
    @setVersionText_Open(v, @marker.getBufferRange().start.row)
    @currentVersion = v
    @clearHighlights()


  setCurrentVersionText_Close: ->
    for n in @currentVersion.nested
      mark = n.getMarker()
      range = mark.getBufferRange()
      @sourceBuffer.insert(range.start, "#%%^%%\n", undo: 'skip')
      @sourceBuffer.insert(new Point(range.end.row + 1, range.end.column), "#^^%^^\n", undo: 'skip')
      n.destroyHeaderMarkerDecoration()
      n.destroyFooterMarkerDecoration()
      n.getModel().setCurrentVersionText_Close()


  setVersionText_Open: (v, offsetRow, lines, lineno) ->
    n_index = 0
    queue = []

    # not super efficient, but first split text into lines
    if lines? == false
      text = v.text
      lines = text.split("\n")
      lineno = 0

    while lineno < lines.length
      line = lines[lineno]

      # look for marker start token
      if line.startsWith("#%%^%%")
        # get rid of this annotation, since it was temporary
        @sourceBuffer.deleteRow(offsetRow + lineno)
        # now store this start beacon so that we can add the marker later
        n = v.nested[n_index]
        console.log "found start point "+n.getModel().getCurrentVersion().title
        queue.push {n: n, row: lineno + offsetRow}
        n_index += 1
        # now, decrement the offsetRow since we've deleted a row from the buffer
        offsetRow -= 1
        # now, recurse on any nested markers within with nested marker!
        nested_model = n.getModel()
        nested_current = nested_model.getCurrentVersion()
        if nested_current.nested.length > 0
          [offsetRow, lineno] = nested_model.setVersionText_Open(nested_current, offsetRow, lines, lineno + 1)

      # okay, next search for an end marker
      else if line.startsWith("#^^%^^")

        # If this end symbol doesn't have a start pair, it belongs to a parent
        # variant. We've gone too far, so back up a line and return up the recursion.
        if queue.length == 0
          return [offsetRow, lineno - 1]

        # get rid of this annotation, since it was temporary
        @sourceBuffer.deleteRow(offsetRow + lineno)
        pair = queue.pop()
        n = pair.n
        start = pair.row
        end = lineno + offsetRow

        # re-setup marker ranges
        marker = n.getMarker()
        headerMarker = n.getHeaderMarker()
        marker.setBufferRange([new Point(start, 0), new Point(end, 0)])
        headerMarker.setBufferRange([new Point(start, 0), new Point(end - 1, 0)], reversed: true)

        # re-set up decorations
        hdec = @sourceEditor.decorateMarker(headerMarker, {type: 'block', position: 'before', item: n.getHeader()})
        n.setHeaderMarkerDecoration(hdec)
        fdec = @sourceEditor.decorateMarker(marker, {type: 'block', position: 'after', item: n.getFooter()})
        n.setFooterMarkerDecoration(fdec)

        # now, decrement the offsetRow since we've deleted a row from the buffer
        offsetRow -= 1

      # don't forget to increment the line number
      lineno += 1

    #return the offset row for recursion purposes
    [offsetRow, lineno]





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



  getNested: ->
    @currentVersion.nested


  addNested: (n) ->
    @currentVersion.nested.push n


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
