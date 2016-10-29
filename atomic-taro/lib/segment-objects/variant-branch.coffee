{Point, Range, TextBuffer} = require 'atom'
JsDiff = require 'diff'
crypto = require 'crypto'
GitUtils = require './git-utils'

'''
Represents a single variant of exploratory code.
'''

'''
  TODO: - commit only when the code has changed (track change sets)
        - compare multiple
        - travel to different versions and commits
        - output data is not recorded with commits
        - can make a commit even when nothing has changed D:
        - Is currentVersion maintained when traveling in commits?
        - How to deal with variant boxes that were dissolved but existed in the past?
'''

module.exports =
class VariantBranch

  # {active: true, id: id, title: title, subtitle: 0, text: text, date: date, branches: [], commits: [], nested: []}
  constructor: (@model, params) ->
    @id = crypto.randomBytes(20).toString('hex')
    @title = params?.title?
    @subtitle = 0
    @text = params?.text?
    @date = params?.date?
    @commits = []
    @branches = []
    @nested = []
    @active = true

    @currentState = null # a place to store the current state while traveling to past commits

    @latestCommit = "" #TODO for now just plaintext of last commit


  getID: ->
    @id


  getTitle: ->
    @title

  setTitle: (t) ->
    @title = t

  getDate: ->
    @date

  setDate: (d) ->
    @date = d


  getSubtitle: ->
    @subtitle


  getNested: ->
    @nested


  addNested: (n) ->
    @nested.push n
    @nested = @nested.sort (a, b) ->
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


  setActive: (val) ->
    @active = val


  getActive: ->
    @active


  getText: ->
    @text


  setText: (newText) ->
    @text = newText


  getBranches: ->
    @branches


  addBranch: (newBranch) ->
    @branches.push newBranch


  getNumberOfCommits: ->
    @commits.length

  open: ->
    #TODO
    @setVersionText_Open(@, @model.getVariantRange().start.row)


  '''
    Closes this branch and stores its contents for easy access in the future
  '''
  close: ->
    #TODO
    @setCurrentVersionText_Close()


  '''
    TODO
  '''
  setCurrentVersionText_Close: ->
    trueEnd = @model.getTextInVariantRange().end

    for n in @nested
      mark = n.getMarker()
      range = mark.getBufferRange()
      startSymbol = "#%%^%%\n"
      if @model.getTextInVariantRange([new Point(range.start.row, 0), range.start]).trim() != ""
        startSymbol = "\n"+startSymbol
      @mode.insertTextInRange(range.start, startSymbol, 'skip')

      endSymbol = "#^^%^^"
      #if (range.end.row != trueEnd.row)
      #  endSymbol = endSymbol+"\n"
      if @model.getTextInVariantRange([new Point(range.end.row, 0), range.end]).trim() != ""
        endSymbol = "\n"+endSymbol
      @mode.insertTextInRange(new Point(range.end.row + 1, range.end.column), endSymbol,'skip')
      n.destroyHeaderMarkerDecoration()
      n.destroyFooterMarkerDecoration()
      n.getModel().getCurrentVersion().setCurrentVersionText_Close()



  '''
    Returns if the variant box has changed since the last run
  '''
  isChanged: ->
    @text = @model.getTextInVariantRange()
    if ( @latestCommit? )
      return @text != @latestCommit
    return true


  '''
    Travels to most recent in time commit.
  '''
  backToTheFuture: ->
    console.log "BACK TO THE FUTURE"
    @model.clearTextInRange()
    @unravelCommitText(@currentState)
    @currentState = null
    #latestCommit = @currentVersion.commits.length - 1
    #@travelToCommit({commitID: latestCommit, verID: @currentVersion.id})
    #@currentVersion.commits.pop()


  '''
    Starts process of travel to a commit.
    Changes display to show the user's code as it was at the time of a specific commit
  '''
  travelToCommit: (commitId) ->
    @model.clearTextInRange()
    @travel(commitId)


  '''
    Changes display to show the user's code as it was at the time of a specific commit.
    Recursively loads in commits from chunked text.
  '''
  travel: (commitId, insertPoint) ->
    commit = @commits[commitId]
    text = commit.text
    return @unravelCommitText(text, insertPoint)


  '''
    save the current state, that may not be committed yet, so that we can return to it.
  '''
  saveUncomittedState: ->
    #TODO
    console.log "Save uncomitted state"
    @recordCurrentState()
    console.log "Saved state:"
    console.log @currentState


  recordCurrentState: ->
    @currentState = null # erase what current state was there previosly
    @currentState = @chunk(false)



  '''
    Given a chunked formatted text of a commit, parses this back into code that
    goes outside variant boxes, variant boxes and their nested boxes.
  '''
  unravelCommitText: (text, insertPoint) ->
    if not insertPoint?
      insertPoint = @model.getVariantRange().start
      #console.log "Beginning insert at "+insertPoint

    start = insertPoint

    subCommits = []

    for item in text
      if item.commitID?
        # then this item is a nested variant
        for nest in @nested
          nestID = item.varID
          if nest.getModel().getVariantID() == nestID
            insertPoint = nest.getModel().travel(item, insertPoint)
            break
      else
        range = @model.insertTextInRange(insertPoint, item.text, 'skip')
        insertPoint = range.end

    after = @model.insertTextInRange(insertPoint, " ", 'skip')
    newRange = [start, new Point(insertPoint.row, insertPoint.column)]
    newRange = @model.clipRange(newRange)
    #console.log "New range for "+@currentVersion.title+" is "
    #console.log newRange
    @model.setRange(newRange)
    @model.setHeaderRange(newRange)

    insertPoint = after.end
    return insertPoint



  '''
    Starts the process of creating a new commit
  '''
  commit: ->
    #console.log "Commit called"
    # check if anything has changed first
    diff = @isChanged()

    # if it changed create a new commit
    if diff
      @latestCommit = @model.getTextInVariantRange()
      commit = @commitChunk(@model.dateNow()) # chunks the current state so that it can be quickly reloaded

    # if nothing has changed, point to the latest commit
    else
      #console.log "UNCHANGED"
      commit = @commits[@commits.length - 1]

    #@git-utils -- commit
    commit



  commitChunk: (date) ->
    console.log "Starting commit chunk"
    commit = {date: date}
    console.log @
    chunks = @chunk(true)
    commit.text = chunks
    #console.log @currentVersion.commits
    @commits.push commit
    #console.log "commited a version "
    #console.log @currentVersion.commits
    #@git-utils commit
    # return a reference, so that others can find this commit
    return {varID: @model.getVariantID(), verID: @id, commitID: @commits.length - 1}



  '''
    Takes the current variant and chunks into nested variants recusively. For each nested
    variant, it records a commit.
  '''
  chunk: (doCommit, params) ->
    #console.log "commit Chunk called! "+@currentVersion.title
    textPointer = @model.getVariantRange().start.row
    chunks = []
    @sortVariants() # necissary to make sure nested variants are in order

    nested = @nested
    if nested.length > 0
      for nest in nested
        model = nest.getModel()
        marker = model.getMarker()
        range = marker.getBufferRange()

        freeRange = [new Point(textPointer, 0), new Point(range.start.row, 0)]
        freeRange = @model.clipRange(freeRange)
        if not freeRange.isEmpty()
          if chunks.length > 0
            freeText = "\n"+@model.getTextInVariantRange(freeRange)
          else
            freeText = @model.getTextInVariantRange(freeRange)
          chunks.push {text: freeText}

        textPointer = range.start.row
        # Hacky, but the only thing I can get to work now
        if doCommit
          chunkReference = model.commit(params)
        else
          chunkReference = model.recordCurrentState(params)
        chunks.push chunkReference

        textPointer = range.end.row + 1

      #After nested, get any remaining free text
      freeRange = [new Point(textPointer, 0), new Point(@model.getVariantRange().end.row, 100000000)]
      freeRange = @model.clipRange(freeRange)
      if not freeRange.isEmpty()
        #console.log "END free range"
        #console.log freeRange
        freeText = "\n"+@model.getTextInVariantRange(freeRange)
        chunks.push {text: freeText}

    else
      # entire variant
      chunks.push {text: @model.getTextInVariantRange()}

    return chunks




  '''
    Sort variants by their marker location. This is helpful for dealing with things
    like offset at save time.
  '''
  sortVariants: ->
    if @nested.length > 0
      nestList = @nested
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



  setVersionText_Open: (v, offsetRow, lines, lineno) ->
    n_index = 0
    queue = []

    # not super efficient, but first split text into lines
    if lines? == false
      text = v.getText()
      lines = text.split("\n")
      lineno = 0

    while lineno < lines.length
      line = lines[lineno]

      # look for marker start token
      if line.startsWith("#%%^%%")
        # get rid of this annotation, since it was temporary
        @model.deleteVariantRow(offsetRow + lineno, 'skip')
        # now store this start beacon so that we can add the marker later
        v.getNested()[n_index] = @testConvertJSONVariant(v.getNested()[n_index], v)
        n = v.getNested()[n_index]
        #@view.getExplorerElement().refresh()

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
