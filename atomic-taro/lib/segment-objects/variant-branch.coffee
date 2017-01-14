{Point, Range, TextBuffer} = require 'atom'
JsDiff = require 'diff'
crypto = require 'crypto'
GitUtils = require './git-utils'
fs = require 'fs'

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
  NO_COMMIT : -1

  # {active: true, id: id, title: title, subtitle: 0, text: text, date: date, branches: [], commits: [], nested: []}
  constructor: (@model, params) ->
    @branchFolder = null
    @id = params.id
    if not @id?
        @id = crypto.randomBytes(20).toString('hex')
    @title = params?.title
    @subtitle = 0
    @text = params?.text
    @date = params?.date
    @commits = []
    @currentCommit = @NO_COMMIT
    @branches = []
    @nested = []
    @active = true
    @multiSelected = false

    @currentState = null # a place to store the current state while traveling to past commits

    @latestCommit = "" #TODO for now just plaintext of last commit


  setFolder: (folder) ->
    @branchFolder = folder


  getFolder: ->
    @branchFolder


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


  getNested:  ->
    @nested


  findNested: (varID) ->
    for nest in @nested
      nestModel = nest.getModel()
      if nestModel.getVariantID() == varID
        return nest
    return null


  addAndSetCommit: (commitID, commit) ->
    @commits[commitID] = commit
    @currentCommit = commitID


  getCurrentCommit: ->
    @currentCommit


  getCurrentCommitObject: ->
    @commits[@currentCommit]


  isMultiSelected: ->
    @multiSelected


  setMultiSelected: (b) ->
    @multiSelected = b


  addNested: (n) ->
    @nested.push n
    @nested = @nested.sort (a, b) ->
      rangeA = a.getModel().getMarker().getBufferRange()
      startA = rangeA.start.row
      rangeB = b.getModel().getMarker().getBufferRange()
      startB = rangeB.start.row
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


  getCurrentState: ->
    @currentState


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
    @switchToVersion()


  findOrAddNested: (varID) ->
    for nest in @nested
      nestModel = nest.getModel()
      if nestModel.getVariantID() == varID
        return nest


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
    Look at currently active nested variants. If any of these are NOT in the
    past commit, deactivate them.
    Look at nested variants in the commitData. If any of these do NOT exist in
    our current state, schedule them to be activated once we travel back.
    Assume we are already on the correct branch for this commit.
  '''
  roleCall: (commitData) ->
    toAdd = []
    #console.log "ROLE CALL on ", commitData

    for nested in @getNested()
      cleared = false
      for item in commitData.text
        if item.varID and item.varID == nested.getModel().getVariantID()
          cleared = true
          break
      if not cleared
        console.log "clearing "+nested.getModel().getTitle()
        nested.dissolve()

    for item in commitData.text
      if item.varID
        varID = item.varID
        # check if variant is instantiated
        variant = @findOrAddNested(varID)

        # check if variant is active, schedule if not
        if variant.getModel().pendingDestruction == true
          toAdd.push variant

    return toAdd


  '''
    Travels to most recent in time commit.
  '''
  backToTheFuture: (insertPoint) ->
    #console.log "Back to the future "+@title
    #console.log @currentState
    # Mark that we are in the present
    if @currentState? # close all unneeded variants before the text is cleared
      nestedToActivate = @roleCall(@currentState)

    @currentCommit = @NO_COMMIT
    if not insertPoint? # meaning the first outermost variant
      #console.log "No insert point"
      #console.log @model.getTitle()
      @model.clearTextInRange()
    if @currentState?
      #console.log "Unraveling current state "+@title
      @model.getView().getCommitLine().slideToPresent()
      # make sure we have the correct set of nested variants
      #nestedToActivate = @roleCall(@currentState)
      return @unravelCommitText(@currentState.text, insertPoint)
    else
      #console.log "traveling to commit "
      return @travelToCommit(@commits.length - 1, insertPoint)



  setToMetaData: (metaData) ->
    console.log "Setting to meta data ", metaData.text
    @model.clearTextInRange()
    @unravelCommitText(metaData.text)


  '''
    Starts process of travel to a commit.
    Changes display to show the user's code as it was at the time of a specific commit
  '''
  travelToCommit: (commitData, insertPoint) ->
    commitID = commitData.commitID
    @currentCommit = commitID
    if not insertPoint?
      #console.log "No insert point"
      @model.clearTextInRange()
      #console.log "CLEARED TEXT"
    # make sure we have the correct set of nested variants
    nestedToActivate = @roleCall(commitData)
    console.log "Traveling to commit ", commitData
    @travel(commitID, insertPoint)


  '''
    Changes display to show the user's code as it was at the time of a specific commit.
    Recursively loads in commits from chunked text.
  '''
  travel: (commitID, insertPoint) ->
    #console.log "Commits of "+@title+":  "+@commits.length
    #console.log commitID
    commit = @commits[commitID]
    console.log "commit is:"
    console.log commit
    #console.log @commits
    @model.getView().getCommitLine().manualSet(commitID)
    text = commit.text
    console.log "text is:"
    console.log text
    return @unravelCommitText(text, insertPoint)


  '''
    save the current state, that may not be committed yet, so that we can return to it.
  '''
  recordCurrentState: (destinationCommit) ->
    #console.log "The state of text for "+@title
    #console.log @model.getTextInVariantRange()
    if destinationCommit?
      @currentCommit = destinationCommit

    @currentState = null # erase what current state was there previosly
    @currentState = {varID: @model.getVariantID(), branchID: @id, text: @chunk(false, destinationCommit)}
    @text = @currentState.text
    #console.log "Recorded state for "+@title
    #console.log @currentState
    @currentState


  '''
    Given a chunked formatted text of a commit, parses this back into code that
    goes outside variant boxes, variant boxes and their nested boxes.
  '''
  unravelCommitText: (text, insertPoint) ->
    if not insertPoint?
      insertPoint = @model.getVariantRange().start
      console.log "Beginning insert at "+insertPoint

    start = insertPoint

    subCommits = []

    for item in text
      if item.varID? #commitID?
        nestID = item.varID
        # then this item is a nested variant
        found = false
        for nest in @nested
          nestModel = nest.getModel()
          if nestModel.getVariantID() == nestID
            found = true
            insertPoint = nestModel.travelToCommit(item, insertPoint)
            if nestModel.pendingDestruction == true # temporarily re-instantiate
              console.log "Reinstating "+nestModel.getTitle()
              nest.reinstate()
            break
        # if not found, this variant hasn't been instantiated, retrieve from file :O
        if not found
          console.log "WARNING: MUST INSTANTIATE" #TODO
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
  commit: (output) ->
    #console.log "Commit called"
    # check if anything has changed first
    diff = @isChanged()
    # if @commits.length == 0
    #   @currentCommit = 0

    # if it changed create a new commit
    if diff
      @latestCommit = @model.getTextInVariantRange()
      commit = @commitChunk(@model.dateNow(), output) # chunks the current state so that it can be quickly reloaded
      @writeCommitToFile(commit)

    # if nothing has changed, point to the latest commit
    else
      #console.log "UNCHANGED"
      commit = @commits[@commits.length - 1]
      commit['output'].push output
    #console.log "Returning commit!"
    #console.log commit
    #@git-utils -- commit
    return commit


  writeCommitToFile: (commit) ->
    fs.writeFile (@branchFolder+"/"+commit.commitID+".json"), JSON.stringify(commit), (error) ->
      console.error("Error writing file", error) if error


  commitChunk: (date, output) ->
    #console.log "Starting commit chunk "+@title
    chunks = @chunk(true, output)
    #console.log "Chunked "+@title+":"
    #console.log chunks
    #console.log "commited a version "
    #console.log @currentVersion.commits
    #@git-utils commit
    # return a reference, so that others can find this commit
    commit = {date: date, text: chunks, varID: @model.getVariantID(), branchID: @id, commitID: @commits.length, output: []}
    commit.output.push output.key
    @commits.push commit
    #console.log "Done commit for ", @title, ":"
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

        if model.pendingDestruction
              # take full range as text
              freeRange = [new Point(textPointer, 0), new Point(range.end.row, Number.MAX_VALUE)]
              @addFreeRange(freeRange, chunks)
              textPointer = range.end.row + 1
        else
            freeRange = [new Point(textPointer, 0), new Point(range.start.row, 0)]
            @addFreeRange(freeRange, chunks)

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
      freeRange = [new Point(textPointer, 0), new Point(@model.getVariantRange().end.row, Number.MAX_VALUE)]
      @addFreeRange(freeRange, chunks)

    else
      # entire variant
      chunks.push {text: @model.getTextInVariantRange()}

    return chunks


  '''
    Helper method to chunk
  '''
  addFreeRange: (freeRange, chunks) ->
    freeRange = @model.clipRange(freeRange)
    if not freeRange.isEmpty()
      if chunks.length > 0
        freeText = "\n"+@model.getTextInVariantRange(freeRange)
      else
        freeText = @model.getTextInVariantRange(freeRange)
      chunks.push {text: freeText}




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
