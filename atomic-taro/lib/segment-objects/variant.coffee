{Point, Range, TextBuffer} = require 'atom'
JsDiff = require 'diff'
crypto = require 'crypto'

'''
Represents a single variant of exploratory code.
'''
module.exports =
class Variant

  constructor: (@view, @sourceEditor, @marker, title, @undoAgent) ->
    @sourceBuffer = @sourceEditor.getBuffer()
    #the header div has it's own marker that must follow around the top of the main marker
    @headerMarker = null
    @range = null # to hold the last range of markers, in case the markers are destroyed

    @nestedParent = null
    @copied = false
    @collapsed = false

    '''
      pendingDestruction is a way to keep variants around (in case the user clicks
      dissolve then later undo) but prevents this variant from being counted in a
      save action. Figure out a better way of handling this in the long run!
    '''
    @pendingDestruction = false

    id = crypto.randomBytes(20).toString('hex')

    if @marker?
      text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
      date = @dateNow()
      @currentVersion = {active: true, id: id, title: title, subtitle: 0, text: text, date: date, branches: [], commits: [], nested: []}
    else
      @currentVersion = {active: true, id: id, title: "NoTitle", subtitle: 0, text: "", date: "", branches: [], commits: [], nested: []}

    @rootVersion = @currentVersion
    #@versions = []
    #@versions.push @currentVersion
    @highlighted = []
    @highlightMarkers = []
    @overlapText = ""
    @prevTitles = []
    @prevVers = []


  getView: ->
    @view


  commit: (params) ->
    start = @marker.getBufferRange().start.row
    @commitChunk(@dateNow(), start)


  commitChunk: (date, textPointer) ->
    commit = {date: date}
    chunks = []
    @sortVariants() # necissary to make sure nested variants are in order

    nested = @currentVersion.nested
    if nested.length > 0
      for nest in nested
        model = nest.getModel()
        marker = model.getMarker()
        range = marker.getBufferRange()

        freeRange = [new Point(textPointer, 0), new Point(range.start.row, 0)]
        freeRange = @sourceBuffer.clipRange(freeRange)
        if not freeRange.isEmpty()
          if chunks.length > 0
            freeText = "\n"+@sourceEditor.getTextInBufferRange(freeRange)
          else
            freeText = @sourceEditor.getTextInBufferRange(freeRange)
          chunks.push {text: freeText}

        textPointer = range.start.row
        commitReference = model.commitChunk(date,textPointer)
        chunks.push commitReference

        textPointer = range.end.row + 1

      #After nested, get any remaining free text
      freeRange = [new Point(textPointer, 0), new Point(@marker.getBufferRange().end.row, 100000000)]
      freeRange = @sourceBuffer.clipRange(freeRange)
      if not freeRange.isEmpty()
        #console.log "END free range"
        #console.log freeRange
        freeText = "\n"+@sourceEditor.getTextInBufferRange(freeRange)
        chunks.push {text: freeText}

    else
      # entire variant
      chunks.push {text: @sourceEditor.getTextInBufferRange(@marker.getBufferRange())}

    commit.text = chunks
    @currentVersion.commits.push commit
    # return a reference, so that others can find this commit
    return {varID: @getVariantID(), verID: @currentVersion.id, commitID: @currentVersion.commits.length - 1}



  registerOutput: (data) ->
    commit = @commit()
    commit


  backToTheFuture: ->
    console.log "BACK TO THE FUTURE"
    latestCommit = @currentVersion.commits.length - 1
    @travelToCommit({commitID: latestCommit, verID: @currentVersion.id})
    @currentVersion.commits.pop()


  travelToCommit: (commitId) ->
    @commit() # SAVE the latest version, not ideal to make a commit every time for this though
    @sourceBuffer.setTextInRange(@marker.getBufferRange(), "", undo: 'skip')
    @travel(commitId)


  travel: (commitId, insertPoint) ->
    versionID = commitId.verID
    commitID = commitId.commitID

    version = @findVersion(versionID)
    commit = version.commits[commitID]
    console.log "Reverting to commit "+commitID
    console.log commit

    if versionID != @currentVersion.id
      console.log "Need to switch versions from "+@currentVersion.title+" to "+version.title
      @currentVersion = version
      @view.switchHeaderToVersion(version)

    version.active = true
    text = commit.text

    #@setCurrentVersionText_Close()
    #@sourceBuffer.setTextInRange(@marker.getBufferRange(), "", undo: 'skip')
    return @unravelCommitText(version, text, insertPoint)
    #@currentVersion = version
    #@clearHighlights()


  unravelCommitText: (version, text, insertPoint) ->
    if not insertPoint?
      insertPoint = @marker.getBufferRange().start
      console.log "Beginning insert at "+insertPoint

    start = insertPoint

    subCommits = []

    for item in text
      if item.commitID?
        # then this item is a nested variant
        for nest in version.nested
          nestID = item.varID
          if nest.getModel().getVariantID() == nestID
            insertPoint = nest.getModel().travel(item, insertPoint)
            break
      else
        range = @sourceBuffer.insert(insertPoint, item.text, undo: 'skip')
        insertPoint = range.end

    after = @sourceBuffer.insert(insertPoint, " ", undo: 'skip')
    newRange = [start, new Point(insertPoint.row, insertPoint.column)]
    newRange = @sourceBuffer.clipRange(newRange)
    #console.log "New range for "+@currentVersion.title+" is "
    #console.log newRange
    @marker.setBufferRange(newRange)
    if  @headerMarker?
      @headerMarker.setBufferRange([newRange.start, new Point(newRange.end.row - 1, newRange.end.column)])

    insertPoint = after.end
    #@sourceEditor.decorateMarker(@marker, type: 'highlight', class: 'highlight-pink')

    # for nest in version.nested
    #   active = false
    #   for sub in subCommits
    #     nestID = sub.item.varID
    #     if nest.getModel().getVariantID() == nestID
    #       nest.getModel().travel(sub.item, sub.point)
    #       active = true
    #       break
    #   if active == false
    #     console.log "This variant should not be showing"
    return insertPoint


  '''
  Sort variants by their marker location. This is helpful for dealing with things
  like offset at save time.
  '''
  sortVariants: ->
    if @currentVersion.nested.length > 0
      nestList = @currentVersion.nested
      nestList = nestList.sort (a, b) ->
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



  getNestedParent: ->
    @nestedParent


  setNestedParent: (p) ->
    @nestedParent = p


  generateNestLabel: ->
    if @nestedParent?
      [version, variant] = @nestedParent
      if variant?.getModel().getNestedParent()?
        text = @recurseNestLabel(@nestedParent, "")
        text


  recurseNestLabel: (n, text) ->
    [version, variant] = n
    text = version.title + ": " + text
    grandParent = variant.getModel().getNestedParent()

    if grandParent? and grandParent[1]?.getModel().getNestedParent()?
      text = @recurseNestLabel(grandParent, text)
    text


  getActiveVersionIDs: ->
    current = [@currentVersion.id]
    if @currentVersion.nested.length > 0
      nCur = []
      for n in @currentVersion.nested
        # assume all nested variants are instantiated
        nCur.push n.getActiveVersionIDs()

      current.push nCur
    current


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
    # we don't want a variant to be saved unless we plan to keep it
    if @pendingDestruction == false
      if @marker?
        text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
        @currentVersion.text = text

        # Now, since we can have nested variants that are not in
        # JSON form, put everything in JSON form
        rootVersion: if @rootVersion? then @serializeWalk(@rootVersion) else null
        currentVersion:  {title: @currentVersion.title}


  serializeWalk: (version) ->
    branches = []
    if version.branches.length > 0
      (branches.push @serializeWalk(c)) for c in version.branches
    nested = []
    if version.nested.length > 0
      for n in version.nested
        if n.rootVersion?
          nested.push n #already in JSON form
        else
          nested.push n.serialize()
    copy = {active: version.active, id: version.id, title: version.title, subtitle: version.subtitle, text: version.text, date: version.date, branches: branches, commits: version.commits, nested: nested}
    copy


  deserialize: (state) ->
    currentID = state.currentVersion.id
    @rootVersion = state.rootVersion
    @walkVersions @rootVersion, (v) =>
      if v.id == currentID
        #console.log "current Nested"
        for n, index in @currentVersion.nested
          #console.log n
          #console.log v.nested[index]
          n.deserialize(v.nested[index])
          v.nested[index] = n
        @currentVersion = v
        false
      else
        true


  dissolve: =>
    @range = @marker.getBufferRange()
    @marker.destroy()
    @headerMarker.destroy()
    @pendingDestruction = true


  reinstate: =>
    if @pendingDestruction
      @marker = @sourceEditor.markBufferRange(@range, invalidate: 'never')
      @marker.setProperties(myVariant: @view)
      #editor.decorateMarker(marker, type: 'highlight', class: 'highlight-green')

      headerElement = @view.getHeader()
      #console.log headerElement
      hRange = [@range.start, new Point(@range.end.row - 1, @range.end.col)]
      @headerMarker = @sourceEditor.markBufferRange(hRange, invalidate: 'never', reversed: true)
      #editor.decorateMarker(hm, type: 'highlight', class: 'highlight-pink')
      @headerMarker.setProperties(myVariant: @view)
      hdec = @sourceEditor.decorateMarker(@headerMarker, {type: 'block', position: 'before', item: headerElement})
      @view.setHeaderMarkerDecoration(hdec)

      footerElement = @view.getFooter()
      fdec = @sourceEditor.decorateMarker(@marker, {type: 'block', position: 'after', item: footerElement})
      @view.setFooterMarkerDecoration(fdec)
      @pendingDestruction = false



  archiveCurrentVerion: ->
    @currentVersion.active = false



  isAlive: ->
    !@pendingDestruction


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
    if version.branches? and flag
      for branch in version.branches
        @walkVersions(branch, fun)
    else
      version


  getRootVersion: ->
    #@versions
    @rootVersion


  getVariantID: ->
    @rootVersion.id


  findVersion: (id, node) ->
    if not node?
      node = @rootVersion
    if node.id == id
      return node

    for child in node.branches
      if child.id == id
        return child

    for child in node.branches
        c = findVersion(id, child)
        if c?
          return c


  getCurrentVersion: ->
    @currentVersion


  hasVersions: ->
    @rootVersion.branches.length > 0


  highlighted: ->
    @highlighted


  toggleActive: (params) =>
    textSelection =  @marker.getBufferRange()
    selections = @sourceEditor.getSelections()
    #console.log selections
    selections[0].setBufferRange(textSelection)
    selections[0].toggleLineComments()
    @clearHighlights()
    if params?.undoSkip? == false
      @undoAgent.pushChange({data: {undoSkip: true}, callback: @toggleActive})
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
      if h.id == v.id
        return true
    false

  clearHighlights: ->
    @highlighted = []
    @overlapText = ""
    for h in @highlightMarkers
      h.destroy()

  isCurrent: (v) ->
    console.log "current version is "+@currentVersion.title+", compared to "+v.title
    if v.id == @currentVersion.id
      return true
    else
      return false

  getPrevs: ->
    prevVers

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
    id = crypto.randomBytes(20).toString('hex')
    newVersion = {active: true, id: id, title: index, text: newText, date: @dateNow(), branches: [], commits: [], nested: []}
    #@versions.push newVersion
    @currentVersion.branches.push newVersion
    @currentVersion = newVersion
    @clearHighlights()
    @currentVersion


  switchToVersion: (v, params) =>
    v.active = true
    @prevVers.push(@currentVersion)
    text = v.text
    @setCurrentVersionText_Close()
    @currentVersion.text = @sourceBuffer.getTextInRange(@marker.getBufferRange())
    @sourceBuffer.setTextInRange(@marker.getBufferRange(), v.text, undo: 'skip')
    @setVersionText_Open(v, @marker.getBufferRange().start.row)
    @currentVersion = v
    @clearHighlights()
    if params?.undoSkip? == false
      @undoAgent.pushChange({data: {undoSkip: true}, callback: @getPrevVersion})


  getPrevVersion: =>
    v = @prevVers.pop()
    @.getView().switchToVersion(v)

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
        @view.getExplorerElement().refresh()

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
        variantView.getModel().setNestedParent([nestParent, @view])
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


  setTitle: (title, version, params) ->
    @prevTitles.push(version.title)
    version.title = title
    if params?.undoSkip? == false
      @undoAgent.pushChange({data: {undoSkip: true}, callback: @getPrevTitle})

  getPrevTitle: =>
    prevTitle = @prevTitles.pop()
    @view.setTitle(prevTitle, @currentVersion)

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
    if @collapsed
      fdec = @sourceEditor.decorateMarker(@marker, {type: 'block', position: 'after', item: @view.getFooter()})
      @view.setFooterMarkerDecoration(fdec)
      @showInsides()
      @sourceEditor.toggleFoldAtBufferRow(@marker.getBufferRange().start.row)
      @collapsed = false
    else
      @view.destroyFooterMarkerDecoration()
      @hideInsides()
      @sourceEditor.setSelectedBufferRange(@marker.getBufferRange())
      @sourceEditor.foldSelectedLines()
      @collapsed = true


  hideInsides: ->
    for n in @currentVersion.nested
      n.destroyHeaderMarkerDecoration()
      n.destroyFooterMarkerDecoration()
      n.getModel().hideInsides()


  showInsides: ->
    for n in @currentVersion.nested
      hdec = @sourceEditor.decorateMarker(n.getModel().getHeaderMarker(), {type: 'block', position: 'before', item: n.getHeader()})
      n.setHeaderMarkerDecoration(hdec)
      fdec = @sourceEditor.decorateMarker(n.getMarker(), {type: 'block', position: 'after', item: n.getFooter()})
      n.setFooterMarkerDecoration(fdec)
      n.getModel().showInsides()
