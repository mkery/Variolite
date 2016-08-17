{Point, Range, TextBuffer} = require 'atom'
JsDiff = require 'diff'

'''
Represents a single variant of exploratory code.
'''
module.exports =
class Variant

  constructor: (@view, @sourceEditor, @marker, title) ->
    @sourceBuffer = @sourceEditor.getBuffer()
    #the header div has it's own marker that must follow around the top of the main marker
    @headerMarker = null

    @nestedParent = null
    @copied = false

    if @marker?
      text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
      date = @dateNow()
      @currentVersion = {title: title, subtitle: 0, text: text, date: date, children: [], nested: []}
    else
      @currentVersion = {title: "NoTitle", subtitle: 0, text: "", date: "", children: [], nested: []}

    @rootVersion = @currentVersion
    #@versions = []
    #@versions.push @currentVersion
    @highlighted = []
    @highlightMarkers = []
    @overlapText = ""


  getView: ->
    @view


  getNestedParent: ->
    @nestedParent


  setNestedParent: (p) ->
    @nestedParent = p


  generateNestLabel: ->
    if @nestedParent?
      text = @recurseNestLabel(@nestedParent, "")
      text



  recurseNestLabel: (n, text) ->
    [version, variant] = n
    text = version.title + ": " + text
    grandParent = variant.getModel().getNestedParent()
    if grandParent?
      text = @recurseNestLabel(grandParent, text)
    text



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
    if @marker?
      text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
      @currentVersion.text = text

      # Now, since we can have nested variants that are not in
      # JSON form, put everything in JSON form
      rootVersion: if @rootVersion? then @serializeWalk(@rootVersion) else null
      currentVersion:  {title: @currentVersion.title}


  serializeWalk: (version) ->
    children = []
    if version.children.length > 0
      (children.push @serializeWalk(c)) for c in version.children
    nested = []
    if version.nested.length > 0
      for n in version.nested
        if n.rootVersion?
          nested.push n #already in JSON form
        else
          nested.push n.serialize()
    copy = {title: version.title, subtitle: version.subtitle, text: version.text, date: version.date, children: children, nested: nested}
    copy


  deserialize: (state) ->
    currentTitle = state.currentVersion.title
    @rootVersion = state.rootVersion
    @walkVersions @rootVersion, (v) =>
      if v.title == currentTitle
        for n, index in @currentVersion.nested
          v.nested[index] = n
        @currentVersion = v
        false
      else
        true


  getMarker: ->
    @marker


  setMarker: (m) ->
    @marker = m


  setHeaderMarker: (hm) ->
    @headerMarker = hm


  getHeaderMarker: ->
    @headerMarker


  walkVersions: (version, fun) ->
    flag = fun(version)
    if version.children? and flag
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
    trueEnd = @marker.getBufferRange().end

    for n in @currentVersion.nested
      mark = n.getMarker()
      range = mark.getBufferRange()
      startSymbol = "#%%^%%\n"
      if @sourceBuffer.getTextInRange([new Point(range.start.row, 0), range.start]).trim() != ""
        startSymbol = "\n"+startSymbol
      @sourceBuffer.insert(range.start, startSymbol, undo: 'skip')

      endSymbol = "#^^%^^"
      #if (range.end.row != trueEnd.row)
      #  endSymbol = endSymbol+"\n"
      if @sourceBuffer.getTextInRange([new Point(range.end.row, 0), range.end]).trim() != ""
        endSymbol = "\n"+endSymbol
      @sourceBuffer.insert(new Point(range.end.row + 1, range.end.column), endSymbol, undo: 'skip')
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
        @sourceBuffer.deleteRow(offsetRow + lineno, undo: 'skip')
        # now store this start beacon so that we can add the marker later
        v.nested[n_index] = @testConvertJSONVariant(v.nested[n_index], v)
        n = v.nested[n_index]

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

        pair = queue.pop()
        n = pair.n
        #console.log "found start point "+n.getModel().getCurrentVersion().title
        start = pair.row
        end = lineno + offsetRow

        # set range to correct end column in the final row!
        range = [new Point(start, 0), new Point(end - 1, 1000000)]
        range = @sourceBuffer.clipRange(range)

        # re-setup marker ranges
        marker = n.getMarker()
        headerMarker = n.getHeaderMarker()
        if marker? and headerMarker?
          marker.setBufferRange(range)
          headerMarker.setBufferRange([new Point(start, 0), new Point(end - 1, 0)], reversed: true)
        else
          marker = @sourceEditor.markBufferRange(range, invalidate: 'never')
          marker.setProperties(myVariant: n)
          n.getModel().setMarker(marker)
          headerMarker = @sourceEditor.markBufferRange([new Point(start, 0), new Point(end - 1, 0)], reversed: true)
          headerMarker.setProperties(myVariant: n)
          n.getModel().setHeaderMarker(headerMarker)

        # re-set up decorations
        hdec = @sourceEditor.decorateMarker(headerMarker, {type: 'block', position: 'before', item: n.getHeader()})
        n.setHeaderMarkerDecoration(hdec)
        fdec = @sourceEditor.decorateMarker(marker, {type: 'block', position: 'after', item: n.getFooter()})
        n.setFooterMarkerDecoration(fdec)

        # now, decrement the offsetRow since we've deleted a row from the buffer
        # this delete is special to deal with our eternal offset issues.
        @sourceBuffer.delete([new Point(offsetRow + lineno - 1, 1000000000), new Point(offsetRow + lineno, 100000)],  undo: 'skip')
        offsetRow -= 1

      # don't forget to increment the line number
      lineno += 1


    #return the offset row for recursion purposes
    [offsetRow, lineno]



  testConvertJSONVariant: (v, nestParent) ->
    variantView = v
    root = v.rootVersion
    if root?
      variantView = @view.makeNewFromJson(v)
      variantView.buildVariantDiv()
      if nestParent?
        v.getModel().setNestedParent([@, nestParent])
    variantView



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
    @currentVersion.nested = @currentVersion.nested.sort (a, b) ->
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
