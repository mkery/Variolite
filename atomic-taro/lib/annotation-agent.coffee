{TextEditor} = require 'atom'
{Point, Range} = require 'atom'
Variant = require './segment-objects/variant-model'
fs = require 'fs'
{TextEditor, TextBuffer} = require 'atom'


module.exports =
class AnnotationAgent

  constructor: (@baseFolder, @fileName) ->
    @subBuffer = null
    @masterVariant = null

  '''
    After initialization of the master variant, connect to it.
  '''
  setMasterVariant: (master) ->
    @masterVariant = master


  save: ->
    file = @baseFolder + "/" + @fileName + ".annot.taro"
    text = @annotateWithVariants()
    fs.writeFile file, text, (error) ->
      console.error("Error writing file", error) if error


  load: (callback) ->
    file = @baseFolder + "/" + @fileName + ".annot.taro"
    text = ""
    $.get file, (data) =>
      text = data
      @subBuffer = new TextBuffer(text: text)
      console.log "RETRIEVED TEXT ", text
      callback(text)

    #console.log "RETRIEVED TEXT ", text


  annotateWithVariants: ->
    #console.log "attempting save!!!"
    #@masterVariant.sortVariants() #important!
    # console.log "sorted???"

    if @subBuffer?
      @subBuffer.setText(@masterVariant.getModel().getTextInVariantRange())
    else
      @subBuffer = new TextBuffer(text: @masterVariant.getModel().getTextInVariantRange())

    insertOffset = 0
    children = @masterVariant.getModel().getCurrentVersion().nested
    for child in children
      insertOffset = @annotateVersion(child, insertOffset)

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
