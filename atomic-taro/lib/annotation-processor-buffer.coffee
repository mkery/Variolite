{Point, Range, TextBuffer, DisplayMarker, TextEditor} = require 'atom'

module.exports =
class AnnotationProcessorBuffer extends TextBuffer

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
      @file.writeSync(@getText())
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


  '''
    addSaveListener: ->
      @sourceBuffer.onDidSave =>
        for block in @variants
          marker = block.getModel().getMarker()
          range = marker.getBufferRange()

          @sourceBuffer.insert(range.start, @partition.getStartAnnotation()+"\n", {undo: false})
          footerEnd = new Point(range.end.row + 1, range.end.col)
          @sourceBuffer.insert(footerEnd, @partition.getEndAnnotation()+"\n", {undo: false})
        for block in @variants
          marker = block.getModel().getMarker()
          range = marker.getBufferRange()

          @sourceBuffer.delete(range.start, {undo: false})
          footerEnd = new Point(range.end.row + 1, range.end.col)
          @sourceBuffer.delete(footerEnd, {undo: false})
  '''
