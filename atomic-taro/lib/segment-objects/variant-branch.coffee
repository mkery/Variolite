{Point, Range, TextBuffer} = require 'atom'
JsDiff = require 'diff'
crypto = require 'crypto'
GitUtils = require './git-utils'

'''
Represents a single variant of exploratory code.
'''

'''
  TODO: - compare multiple
        - travel to different versions and commits
        - output data is not recorded with commits
        - Is currentVersion maintained when traveling in commits?
        - How to deal with variant boxes that were dissolved but existed in the past?
'''

module.exports =
class VariantBranch

  # {active: true, id: id, title: title, subtitle: 0, text: text, date: date, branches: [], commits: [], nested: []}
  constructor: (@model, params) ->
    @id = crypto.randomBytes(20).toString('hex')
    @title = params?.title
    @subtitle = 0
    @text = params?.text
    @date = params?.date
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


  getText: ->
    @text


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


  isCurrent: ->
    @model.getCurrentVersion().getID() == @id


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
    #console.log "Opening "+@title
    @backToTheFuture()
    @model.showInsides()


  switchToVersion: ->
    @model.getView().switchToVersion(@)

  archive: ->
    return @model.getView().archive()

  activateVersion: ->
    @active = true
    @model.getView().addVersionBookmark(@, false, null)

  '''
    Closes this branch and stores its contents for easy access in the future
  '''
  close: ->
    @recordCurrentState()
    @model.hideInsides()



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
  backToTheFuture: (insertPoint) ->
    #console.log "Back to the future "+@title
    #console.log @currentState
    if not insertPoint? # meaning the first outermost variant
      @model.clearTextInRange()
    if @currentState?
      #console.log "Unraveling "+@title
      @unravelCommitText(@currentState.text, insertPoint, false)
    else
      @travelToCommit(@commits.length - 1)



  '''
    Starts process of travel to a commit.
    Changes display to show the user's code as it was at the time of a specific commit
  '''
  travelToCommit: (commitData, insertPoint) ->
    if not insertPoint?
      @model.clearTextInRange()
      #console.log "CLEARED TEXT"
    @travel(commitData, insertPoint)


  '''
    Changes display to show the user's code as it was at the time of a specific commit.
    Recursively loads in commits from chunked text.
  '''
  travel: (commitId, insertPoint) ->
    #console.log "Commits of "+@title+":  "+@commits.length
    #console.log commitId
    commit = @commits[commitId]
    #console.log "commit is:"
    #console.log commit
    #console.log @commits
    text = commit.text
    return @unravelCommitText(text, insertPoint, true)


  '''
    save the current state, that may not be committed yet, so that we can return to it.
  '''
  recordCurrentState: ->
    #console.log "The state of text for "+@title
    #console.log @model.getTextInVariantRange()
    @currentState = null # erase what current state was there previosly
    @currentState = {varID: @model.getVariantID(), branchID: @id, text: @chunk(false)}
    @text = @currentState.text[0].text
    #console.log "Recorded state for "+@title
    #console.log @currentState
    @currentState


  '''
    Given a chunked formatted text of a commit, parses this back into code that
    goes outside variant boxes, variant boxes and their nested boxes.
  '''
  unravelCommitText: (text, insertPoint, commitTravel) ->
    if not insertPoint?
      insertPoint = @model.getVariantRange().start
      #console.log "Beginning insert at "+insertPoint

    start = insertPoint

    subCommits = []

    for item in text
      if item.varID? #commitID?
        # then this item is a nested variant
        for nest in @nested
          nestID = item.varID
          if nest.getModel().getVariantID() == nestID
            if commitTravel == true
              insertPoint = nest.getModel().travelToCommit(item, insertPoint)
            else
              insertPoint = nest.getModel().backToTheFuture(insertPoint, item.branchID)
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
    # console.log "Commit called"
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

    #console.log "Returning commit!"
    #console.log commit
    #@git-utils -- commit
    return commit



  commitChunk: (date) ->
    #console.log "Starting commit chunk "+@title
    chunks = @chunk(true)
    #console.log "Chunked "+@title+":"
    #console.log chunks
    #console.log "commited a version "
    #console.log @currentVersion.commits
    #@git-utils commit
    # return a reference, so that others can find this commit
    commit = {date: date, text: chunks, varID: @model.getVariantID(), branchID: @id, commitID: @commits.length}
    @commits.push commit
    #console.log "Done commit:"
    #console.log commit
    return commit



  '''
    Takes the current variant and chunks into nested variants recusively. For each nested
    variant, it records a commit.
  '''
  chunk: (doCommit, params) ->
    #console.log "chunk: "+@title
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
          #console.log "Doing a commit of "+model.getCurrentVersion().getTitle()
          chunkReference = model.commit(params)
          #console.log "Chunk reference returned"
          #console.log chunkReference
        else
          chunkReference = model.getCurrentVersion().recordCurrentState(params)
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



  testConvertJSONVariant: (v, nestParent) ->
    variantView = v
    root = v.rootVersion
    if root?
      variantView = @view.makeNewFromJson(v)
      variantView.buildVariantDiv()
      if nestParent?
        variantView.getModel().setNestedParent([nestParent, @view])
    variantView
