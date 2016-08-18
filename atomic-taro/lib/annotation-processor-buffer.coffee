{Point, Range, TextBuffer, DisplayMarker, TextEditor} = require 'atom'

module.exports =
class AnnotationProcessorBuffer extends TextBuffer

  constructor: (params) ->
    @variantView = params.variantView
    @subBuffer = null
    @undoAgent = params.undoAgent
    @undoAgent.setBuffer(@)
    super(params)


  # Public: Undo the last operation. If a transaction is in progress, aborts it.
  undo: ->
    if @undoAgent.undoNow()
      @undoAgent.revertChange()
      console.log "undo TARO!"
      #true
    else
      console.log "undo buffer"
      if pop = @history.popUndoStack()
        @applyChange(change) for change in pop.patch.getChanges()
        @restoreFromMarkerSnapshot(pop.snapshot)
        @emitMarkerChangeEvents(pop.snapshot)
        @emitDidChangeTextEvent(pop.patch)
        true
      else
        false
    false

  # Public: Redo the last operation
  redo: ->
    if pop = @history.popRedoStack()
      @applyChange(change) for change in pop.patch.getChanges()
      @restoreFromMarkerSnapshot(pop.snapshot)
      @emitMarkerChangeEvents(pop.snapshot)
      @emitDidChangeTextEvent(pop.patch)
      true
    else
      false



  # Public: Save the buffer at a specific path.
  #
  # * `filePath` The path to save at.
  saveAs: (filePath, options) ->
    unless filePath then throw new Error("Can't save buffer with no file path")

    @emitter.emit 'will-save', {path: filePath}
    @setPath(filePath)

    if options?.backup
      backupFile = @backUpFileContentsBeforeWriting()

    try
      @file.writeSync(@annotateTextWithVariants(@getText()))
      if backupFile?
        backupFile.safeRemoveSync()
    catch error
      if backupFile?
        @file.writeSync(backupFile.readSync())
      throw error

    @cachedDiskContents = @getText()
    @conflict = false
    @emitModifiedStatusChanged(false)
    @emitter.emit 'did-save', {path: filePath}


  annotateTextWithVariants: (text) ->
    console.log "attempting save!!!"
    @variantView.sortVariants() #important!
    variants = @variantView.getVariants()
    console.log "sorted???"
    console.log variants
    if @subBuffer?
      @subBuffer.setText(@getText())
    else
      @subBuffer = new TextBuffer(text: @getText())

    insertOffset = 0
    for v in variants
      insertOffset = @annotateVersion(v, insertOffset)

    @subBuffer.getText()

  '''
  We need a recursive process to account for nested variants
  '''
  annotateVersion: (v, insertOffset) ->
    marker = v.getModel().getMarker()
    range = marker.getBufferRange()
    title = v.getModel().getTitle()
    #console.log "found title! "+title+", with range "+range.start
    #console.log "offset "+insertOffset

    start = [range.start.row + insertOffset, range.start.col]
    @subBuffer.insert(start, "#%%^%%"+title+"\n", {undo: false})
    insertOffset += 1

    for n in v.getModel().getNested()
      insertOffset = @annotateVersion(n, insertOffset)

    insertOffset += 1
    footerEnd = new Point(range.end.row + insertOffset, range.end.col)
    @subBuffer.insert(footerEnd, "#^^%^^"+"\n", {undo: false})

    insertOffset
