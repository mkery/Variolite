{Point, Range, TextBuffer} = require 'atom'
JsDiff = require 'diff'
crypto = require 'crypto'
GitUtils = require './git-utils'
VariantBranch = require './variant-branch'
fs = require 'fs'

'''
Represents a single variant of exploratory code.
'''

'''
  TODO:
        - compare multiple
        - travel to different versions and commits
        - How to deal with variant boxes that were dissolved but existed in the past?
'''

module.exports =
class VariantModel
  PRESENT : -1

  constructor: (params) ->
    @view = params.taroView
    @sourceEditor = params.sourceEditor
    @sourceBuffer = @sourceEditor.getBuffer()  # really Variolite's buffer

    @undoAgent = params.undoAgent
    #@provenanceAgent = params.provAgent

    @headerMarker = null # the header div has it's own marker
    @marker = params.marker
    @range = null # to hold the last range of markers, in case the markers are destroyed

    @nestedParent = null
    @collapsed = false

    # Branch objects for each version associated with this variant
    @branches = []
    @currentBranch = null # the currently selected branch

    # pendingDestruction is a way to keep variants around (in case the user clicks
    # dissolve then later undo) but prevents this variant from being counted in a
    # save action. Figure out a better way of handling this in the long run!
    @pendingDestruction = false

    if params.metaData?
      @unpackMetaData(params.metaData, params.metaFolder)
    else
      @freshNewRevisionTree(params)

    @prevTitles = [] # TODO for help with undo?
    @prevVers = [] # TODO for help with undo?



  freshNewRevisionTree: (params) ->
    @variantID = params.id
    if not @variantID?
        @variantID = crypto.randomBytes(20).toString('hex')
        @variantFolder = params.metaFolder + "/" + @variantID.substring(0, 11)
    else
      @variantFolder = params.metaFolder + "/" + @variantID
    console.log "Trying to make a folder at: ",@variantFolder
    @mkdirSync(@variantFolder) # If folder does not exist, creates a new folder

    title = params.title
    title ?= "v0"
    params = null
    if @marker?
      text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
      date = @dateNow()
      params = {title: title, text: text, date: date, id: 0}

    @currentBranch = new VariantBranch(@, params)
    branchFolder = @variantFolder + "/" + @currentBranch.getID()
    @mkdirSync(branchFolder) # If folder does not exist, creates a new folder
    @currentBranch.setFolder(branchFolder)
    @branches.push @currentBranch



  unpackMetaData: (item, metaFolder) ->
    @variantID = item.varID
    @variantFolder = metaFolder + "/" + @variantID

    branchID = item.branchID
    date = item.date
    title = "b0" #TODO
    @currentBranch = new VariantBranch(@, {title: title, date: date, id: branchID})
    branchFolder = @variantFolder + "/" + @currentBranch.getID()
    @currentBranch.setFolder(branchFolder)
    @branches.push @currentBranch



  '''
    Returns the VariantView associated with this Variant.
  '''
  getView: ->
    @view


  '''
    Returns the text currently in range of this Variant
  '''
  getTextInVariantRange: (range) ->
    if range?
      @sourceEditor.getTextInBufferRange(range)
    else
     @sourceEditor.getTextInBufferRange(@marker.getBufferRange())


  '''
    Removes the text currently in range of this Variant
  '''
  clearTextInRange: ->
    @sourceBuffer.setTextInRange(@marker.getBufferRange(), "", undo: 'skip')


  '''
    Insert text in range of this Variant
  '''
  insertTextInRange: (point, text, undo) ->
    @sourceBuffer.insert(point, text, undo: undo)


  '''
    Completely replace the text in this variant with the given text
  '''
  setTextInVariantRange: (text, undo) ->
    @sourceBuffer.setTextInRange(@marker.getBufferRange(), text, undo: undo)


  '''
    Clip a range in this Variant to the exact start and end points of the
    text in there.
  '''
  clipRange: (range) ->
    @sourceBuffer.clipRange(range)


  deleteVariantRow: (row, undo) ->
    @sourceBuffer.deleteRow(row, undo: undo)


  '''
    Returns the range of this Variant
  '''
  getVariantRange: ->
    @marker.getBufferRange()


  '''
    Sets the range of this variant
  '''
  setRange: (newRange) ->
    @marker.setBufferRange(newRange)


  '''
    Sets the range of the header marker of this variant
  '''
  setHeaderRange: (newRange) ->
    if @headerMarker?
      @headerMarker.setBufferRange([newRange.start, new Point(newRange.end.row - 1, newRange.end.column)])


  '''
    Records an output and a commit that generated it
  '''
  registerOutput: (output) ->
    @view.getCommitLine().redraw()
    commit = @currentBranch.commit(output)
    commit


  commit: (output) ->
    commit = @currentBranch.commit(output)
    @view.getCommitLine().redraw()
    commit


  '''
    Starts process of travel to a commit.
    Changes display to show the user's code as it was at the time of a specific commit
  '''
  travelToCommit: (commitData, insertPoint) ->
    console.log @currentBranch.title+" traveling to commit"
    branchID = commitData.branchID
    commitID = commitData.commitID

    #   are we traveling between 2 past points?
    #   if no branch is declared, assume the current branch
    if branchID? and branchID != @currentBranch.getID()
      branch = @findBranch(branchID)
      branch.setActive(true)
      @currentBranch = branch
      @view.switchHeaderOnly(branch)


    # Check direction of travel:
    #   are we in tha past traveling to the present?
    if commitID == @PRESENT or !commitID?
      console.log @getTitle(), " BACK TO THE FUTURE, ", commitID, ", ", @PRESENT
      return @currentBranch.backToTheFuture(insertPoint)
    #   are we in the present traveling back?
    else
      if @currentBranch.getCurrentCommit() == @currentBranch.NO_COMMIT
        console.log "FROM PRESENT TO PAST"
        @currentBranch.recordCurrentState(commitID)

      return @currentBranch.travelToCommit(commitData, insertPoint)


  '''
    Returns the variant box that this variant box is a nested child of.
  '''
  getNestedParent: ->
    @nestedParent


  '''
    Used when a variant is created, to add the pointer to its nested parent.
  '''
  setNestedParent: (p) ->
    @nestedParent = p


  '''
    Returns a string to display the variant's header div as being nested.
  '''
  generateNestLabel: ->
    if @nestedParent?
      [version, variant] = @nestedParent
      if variant?.getModel().getNestedParent()?
        text = @recurseNestLabel(@nestedParent, "")
        text


  '''
    Recursive helper for generateNestLabel
  '''
  recurseNestLabel: (n, text) ->
    [version, variant] = n
    text = version.title + ": " + text
    grandParent = variant.getModel().getNestedParent()

    if grandParent? and grandParent[1]?.getModel().getNestedParent()?
      text = @recurseNestLabel(grandParent, text)
    text


  '''
    Helper function to display the current data and time. Returns a formatted
    String.
  '''
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


  '''
    Saves the state of this variant so that if can be loaded later when the
    tool is closed and opened.
  '''
  serialize: ->
    # if @pendingDestruction == false
    #   if @marker?
    #     text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    #     @currentVersion.text = text
    #
    #     # Now, since we can have nested variants that are not in
    #     # JSON form, put everything in JSON form
    #     rootVersion: if @rootVersion? then @serializeWalk(@rootVersion) else null
    #     currentVersion:  @currentVersion.id


  '''
    Recursive helper for @serialize
  '''
  serializeWalk: (version) ->
    '''
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
    copy = {active: version.active, id: version.id, title: version.title, subtitle: version.subtitle, text: version.text, date: version.date, branches: branches, commits: version.commits, latestCommit: version.latestCommit, nested: nested}
    copy'''


  '''
    Takes serialized JSON record of state and initilizes this variant with the
    saved data.
  '''
  deserialize: (state) ->
    '''
    currentID = state.currentVersion
    @rootVersion = state.rootVersion
    @deserializeWalk(@rootVersion, currentID)
    #console.log "loaded in variant "
    #console.log @rootVersion
    '''


  '''
    Recursive helper for @deserialize
  '''
  deserializeWalk: (version, currentVerID) ->
    '''
    # If this is the current version, initialize all of it's nested
    if version.id == currentVerID
      #console.log "Already current version?"
      #console.log @currentVersion
      for n, index in @currentVersion.nested
        #console.log n
        #console.log v.nested[index]
        n.deserialize(version.nested[index])
        version.nested[index] = n
      @currentVersion = version

    # Continue to deserialize all the branches of version
    for branch in version.branches
      @deserializeWalk(branch, currentVerID)
    '''


  '''
    Removes variant box from code and flattens whatever is currently in the variant
    box into the file.
  '''
  dissolve: =>
    @range = @marker.getBufferRange()
    @marker.destroy()
    @headerMarker.destroy()
    @pendingDestruction = true


  '''
    If a variant box was dissolved in this session, re-adds it to the code and re-adds
    the VariantView header elements.
  '''
  reinstate: =>
    console.log "Re-instate range is ", @range
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
    if @pendingDestruction
      @pendingDestruction = false


  '''
    ??? Not used?
  '''
  archiveCurrentVerion: ->
    @currentBranch.setActive(false)


  '''
    Helper function. Returns if this variant is 'pending destruction', meaning the user
    chose to dissolve it. If they did, then this variant shuld not be saved with the file.
  '''
  isAlive: ->
    !@pendingDestruction


  '''
    Returns the marker associated with this variant.
  '''
  getMarker: ->
    @marker


  '''
    Sets this variant's main marker. This is useful in cases where the marker needs to
    be destroyed and re-added later.
  '''
  setMarker: (m) ->
    @marker = m


  '''
    Sets this variant's header marker. This is useful in cases where the marker needs to
    be destroyed and re-added later.
  '''
  setHeaderMarker: (hm) ->
    @headerMarker = hm


  '''
    Return this variant's header marker, which is simply a second marker to place the
    header div of the variant, for implementation reasons of how editor decorations work in Atom
  '''
  getHeaderMarker: ->
    @headerMarker



  '''
    Returns the root version of this variant box. The root version is simply the first
    version that existed in the commit tree.
  '''
  getRootVersion: ->
    @branches[0]


  '''
    Returns this variant box's ID. The variant box ID is simple the root version's ID
  '''
  getVariantID: ->
    @variantID


  '''
    Given an ID, find the version in this variant box's commit tree that matches.
  '''
  findBranch: (id, node) ->
    if not node?
      node = @branches[0]
    if node.getID() == id
      return node

    for child in node.getBranches()
      if child.getID() == id
        return child

    for child in node.getBranches()
        c = @findBranch(id, child)
        if c?
          return c


  '''
    Return whatever version is currently showing in the editor.
  '''
  getCurrentVersion: ->
    @currentBranch


  deselectCurrentVersion: ->
    @currentBranch = null


  '''
    For display versions, return if this variant box has more than 1 version.
  '''
  hasVersions: ->
    @branches.length > 0 and @branches[0].getBranches().length > 0



  '''
    Toggles whether the contents of the variant are commented out or not.
  '''
  toggleActive: (params) =>
    textSelection =  @marker.getBufferRange()
    selections = @sourceEditor.getSelections()
    #console.log selections
    selections[0].setBufferRange(textSelection)
    selections[0].toggleLineComments()
    if params?.undoSkip? == false
      @undoAgent.pushChange({data: {undoSkip: true}, callback: @toggleActive})


  '''
    TODO rename. What is this?? I think it's for selecting multiple versions
    to compare or linked edit them.
  '''
  isMultiSelected: (v) ->
    v.isMultiSelected()



  '''
    Returns true if the given version has the same ID as @currentVersion, false otherwise.
  '''
  isCurrent: (v) ->
    #console.log "current version is "+@currentVersion.title+", compared to "+v.title
    if @currentBranch != null and (v.getID() == @currentBranch.getID())
      return true
    else
      return false


  mkdirSync: (path) ->
    try
      fs.mkdirSync(path);
    catch e
      if e.code != 'EEXIST'
        #throw e
        console.log "Failed to create directory.", e


  '''
    Creates a new version of this variant box, a new branch in the commit tree.
  '''
  newBranch: ->
    # new text has clean text before we add marker placeholders
    newText = @getTextInVariantRange()
    @currentBranch.close()
    # currentVersion has text after we add marker placeholders
    #@currentBranch.setText(@getTextInVariantRange())

    # now, set the text for the new version we're switching to
    @setTextInVariantRange(newText, 'skip')

    subtitle = @currentBranch.getBranches().length
    index = @currentBranch.getTitle() + "-" + (subtitle + 1)
    newBranch = new VariantBranch(@,{title: index, text: newText, date: @dateNow()})

    branchFolder = @variantFolder + "/" + newBranch.getID()
    @mkdirSync(branchFolder) # If folder does not exist, creates a new folder
    newBranch.setFolder(branchFolder)

    @currentBranch.addBranch newBranch
    @currentBranch = newBranch
    @currentBranch


  '''
    Switches to a new version. Instantiates that version if it has nested variant boxes
    that have never been opened and built before in this session.
  '''
  switchToVersion: (newBranch, params) =>
    newBranch.setActive(true)
    @prevVers.push(@currentBranch)
    @currentBranch?.close()
    @currentBranch = newBranch
    newBranch.open()

    if params?.undoSkip? == false
      @undoAgent.pushChange({data: {undoSkip: true}, callback: @getPrevVersion})


  '''
    A helper for undo-ing @switchToVersion
  '''
  getPrevVersion: =>
    v = @prevVers.pop()
    @.getView().switchToVersion(v)


  findNested: (varID) ->
    if @currentBranch?
      @currentBranch.findNested(varID)
    else
      null


  getNested: ->
    if @currentBranch?
      @currentBranch.getNested()
    else
      []


  addNested: (n) ->
    @currentBranch.addNested(n)


  getTitle: ->
    @currentBranch.getTitle()


  setTitle: (title, version, params) ->
    @prevTitles.push(version.getTitle())
    version.setTitle(title)
    if params?.undoSkip? == false
      @undoAgent.pushChange({data: {undoSkip: true}, callback: @getPrevTitle})

  getPrevTitle: =>
    prevTitle = @prevTitles.pop()
    @view.setTitle(prevTitle, @currentBranch)

  getDate: ->
    @currentBranch.getDate()


  getText: ->
    @currentBranch.getText()



  setText: (text) ->
    @currentBranch.setText(text)


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
    for n in @currentBranch.getNested()
      #console.log "Closing insides "+n
      n.destroyHeaderMarkerDecoration()
      n.destroyFooterMarkerDecoration()
      n.getModel().hideInsides()


  showInsides: ->
    for n in @currentBranch.getNested()
      #console.log "Showing insides "+n
      hdec = @sourceEditor.decorateMarker(n.getModel().getHeaderMarker(), {type: 'block', position: 'before', item: n.getHeader()})
      n.setHeaderMarkerDecoration(hdec)
      fdec = @sourceEditor.decorateMarker(n.getMarker(), {type: 'block', position: 'after', item: n.getFooter()})
      n.setFooterMarkerDecoration(fdec)
      n.getModel().showInsides()
