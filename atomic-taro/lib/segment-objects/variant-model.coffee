{Point, Range, TextBuffer} = require 'atom'
JsDiff = require 'diff'
crypto = require 'crypto'
GitUtils = require './git-utils'
VariantBranch = require './variant-branch'

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
class VariantModel

  constructor: (@view, @sourceEditor, @marker, title, @undoAgent, @provenanceAgent) ->
    @sourceBuffer = @sourceEditor.getBuffer()  # really Variolite's buffer
    @headerMarker = null # the header div has it's own marker
    @range = null # to hold the last range of markers, in case the markers are destroyed

    @nestedParent = null
    @collapsed = false


    # pendingDestruction is a way to keep variants around (in case the user clicks
    # dissolve then later undo) but prevents this variant from being counted in a
    # save action. Figure out a better way of handling this in the long run!
    @pendingDestruction = false

    # TODO do not need to re-generate id for variant that has one!
    @variantID = crypto.randomBytes(20).toString('hex')

    # Branch objects for each version associated with this variant
    @branches = []
    @currentBranch = null # the currently selected branch

    params = null
    if @marker?
      text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
      date = @dateNow()
      params = {title: title, text: text, date: date}

    @currentBranch = new VariantBranch(@, params)
    @branches.push @currentBranch

    # Global variables to do with comparing multiple versions.
    # ??? TODO Rename to clarify!
    @highlighted = []
    @highlightMarkers = []
    @overlapText = ""
    @prevTitles = []
    @prevVers = []


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
    if  @headerMarker?
      @headerMarker.setBufferRange([newRange.start, new Point(newRange.end.row - 1, newRange.end.column)])


  '''
    Records an output and a commit that generated it
  '''
  registerOutput: (data) ->
    commit = @currentBranch.commit()
    # store provenance information
    @provenanceAgent.store(data, commit)
    commit


  commit: ->
    @currentBranch.commit()


  '''
    Travels to most recent in time commit.
  '''
  backToTheFuture: ->
    @currentBranch.backToTheFuture()


  '''
    Starts process of travel to a commit.
    Changes display to show the user's code as it was at the time of a specific commit
  '''
  travelToCommit: (commitId) ->
    @currentBranch.saveUncomittedState() # SAVE the latest version, not ideal to make a commit every time for this though

    versionID = commitId.verID
    commitID = commitId.commitID

    brach = @findBranch(versionID)
    if versionID != @currentBranch.getID()
      #console.log "Need to switch versions from "+@currentVersion.title+" to "+version.title
      @currentBranch = brach
      @view.switchHeaderToVersion(brach)

    @currentBranch.setActive(true)
    @currentBranch.travelToCommit(commitID)




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
    ??? Who calls this?
  '''
  getActiveVersionIDs: ->
    current = [@currentBranch.getID()]
    if @currentBranch.getNested().length > 0
      nCur = []
      for n in @currentBranch.getNested()
        # assume all nested variants are instantiated
        nCur.push n.getActiveVersionIDs()

      current.push nCur
    current


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
    '''# we don't want a variant to be saved unless we plan to keep it
    if @pendingDestruction == false
      if @marker?
        text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
        @currentVersion.text = text

        # Now, since we can have nested variants that are not in
        # JSON form, put everything in JSON form
        rootVersion: if @rootVersion? then @serializeWalk(@rootVersion) else null
        currentVersion:  @currentVersion.id'''


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


  '''
    For display versions, return if this variant box has more than 1 version.
  '''
  hasVersions: ->
    @branches.length > 0


  '''
    Return if this version is focused on by the user's cursor.
  '''
  highlighted: ->
    @highlighted


  '''
    Toggles whether the contents of the variant are commented out or not.
  '''
  toggleActive: (params) =>
    textSelection =  @marker.getBufferRange()
    selections = @sourceEditor.getSelections()
    #console.log selections
    selections[0].setBufferRange(textSelection)
    selections[0].toggleLineComments()
    @clearHighlights()
    if params?.undoSkip? == false
      @undoAgent.pushChange({data: {undoSkip: true}, callback: @toggleActive})


  '''
    TODO rename. What is this?? I think it's for selecting multiple versions
    to compare or linked edit them.
  '''
  isHighlighted: (v) ->
    for h in @highlighted
      if h.id == v.id
        return true
    false

  '''
    TODO rename. What is this?? I think it's for selecting multiple versions
    to compare or linked edit them.
  '''
  clearHighlights: ->
    @highlighted = []
    @overlapText = ""
    for h in @highlightMarkers
      h.destroy()

  '''
    Returns true if the given version has the same ID as @currentVersion, false otherwise.
  '''
  isCurrent: (v) ->
    #console.log "current version is "+@currentVersion.title+", compared to "+v.title
    if v.getID() == @currentBranch.getID()
      return true
    else
      return false


  '''
    Creates a new version of this variant box, a new branch in the commit tree.
  '''
  newVersion: ->
    # new text has clean text before we add marker placeholders
    newText = @getTextInVariantRange()
    @currentBranch.close()
    # currentVersion has text after we add marker placeholders
    @currentBranch.setText(@getTextInVariantRange())

    # now, set the text for the new version we're switching to
    @setTextInVariantRange(newText, 'skip')

    subtitle = @currentBranch.getSubtitle()
    index = @currentBranch.getTitle() + "-" + (subtitle + 1)
    newBranch = new VariantBranch(@,{title: index, text: newText, date: @dateNow()})

    @currentBranch.addBranch newBranch
    @currentBranch = newBranch
    @clearHighlights()
    @currentBranch


  '''
    Switches to a new version. Instantiates that version if it has nested variant boxes
    that have never been opened and built before in this session.
  '''
  switchToVersion: (newBranch, params) =>
    newBranch.setActive(true)
    @prevVers.push(@currentBranch)
    text = newBranch.getText()
    @currentBranch.close()
    @currentBranch.setText(@getTextInVariantRange())
    @setTextInVariantRange(newBranch.getText(), 'skip')
    newBranch.open()

    @currentBranch = newBranch
    @clearHighlights()
    if params?.undoSkip? == false
      @undoAgent.pushChange({data: {undoSkip: true}, callback: @getPrevVersion})


  '''
    A helper for undo-ing @switchToVersion
  '''
  getPrevVersion: =>
    v = @prevVers.pop()
    @.getView().switchToVersion(v)






  compareToVersion: (v) ->
    # first, switch to the new version
    compareFrom = @currentBranch
    text = v.text
    @currentBranch.setText(@getTextInVariantRange())
    @setTextInBufferRange(v.text, false)
    @currentBranch = v

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
    @currentBranch.getNested()


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
      n.destroyHeaderMarkerDecoration()
      n.destroyFooterMarkerDecoration()
      n.getModel().hideInsides()


  showInsides: ->
    for n in @currentBranch.getNested()
      hdec = @sourceEditor.decorateMarker(n.getModel().getHeaderMarker(), {type: 'block', position: 'before', item: n.getHeader()})
      n.setHeaderMarkerDecoration(hdec)
      fdec = @sourceEditor.decorateMarker(n.getMarker(), {type: 'block', position: 'after', item: n.getFooter()})
      n.setFooterMarkerDecoration(fdec)
      n.getModel().showInsides()
