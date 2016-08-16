{Point, Range, TextBuffer, DisplayMarker, TextEditor} = require 'atom'

module.exports =
class AnnotationProcessorBuffer extends TextBuffer

  constructor: (params) ->
    @variantView = params.variantView
    @subBuffer = null
    super(params)

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
    @subBuffer.insert(start, "#ʕ•ᴥ•ʔ#"+title+"\n", {undo: false})
    insertOffset += 1

    for n in v.getModel().getNested()
      insertOffset = @annotateVersion(n, insertOffset)

    insertOffset += 1
    footerEnd = new Point(range.end.row + insertOffset, range.end.col)
    @subBuffer.insert(footerEnd, "##ʕ•ᴥ•ʔ"+"\n", {undo: false})

    insertOffset
