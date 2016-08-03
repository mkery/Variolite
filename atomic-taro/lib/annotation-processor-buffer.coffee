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
    variants = @variantView.getVariants()
    if @subBuffer?
      @subBuffer.setText(@getText())
    else
      @subBuffer = new TextBuffer(text: @getText())

    for v in variants
      marker = v.getModel().getMarker()
      range = marker.getBufferRange()
      title = v.getModel().getTitle()
      console.log "found title! "+title

      @subBuffer.insert(range.start, "#ʕ•ᴥ•ʔ#"+title+"\n", {undo: false})
      footerEnd = new Point(range.end.row + 1, range.end.col)
      @subBuffer.insert(footerEnd, "##ʕ•ᴥ•ʔ"+"\n", {undo: false})

    @subBuffer.getText()
