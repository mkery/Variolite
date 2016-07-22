SegmentedBuffer = require './segmented-buffer'
{Point, Range, TextBuffer} = require 'atom'

module.exports =
class CodeSegmenter
  sourceEditor: null
  sourceBuffer: null
  segments: []
  header: null
  splitString: "#ʕ•ᴥ•ʔ"
  splitSize: 6

  constructor: (sourceEditor) ->
    @segments = [] # for some reason this prevents duplicate blocks
    @sourceEditor = sourceEditor
    @sourceBuffer = sourceEditor.getBuffer()

    sourceEditor.scan new RegExp(@splitString+'(.*(\n)*)+?'+@splitString, 'g'), @scanIterator

  scanIterator: (match) =>
    #console.log "matched! "+match.matchText
    # create a marker for this range so that we can keep track
    range = match.range
    marker = @sourceEditor.markBufferRange(range: range)
    # if segments is empty, this is the first match,
    # also capture the header
    if @segments.length <= 0
      header_range = new Range(new Point(0,0), range.start)
      header_marker = @sourceEditor.markBufferRange(range: header_range)
      header_text = @sourceEditor.getTextInBufferRange(header_range)
      console.log "header text! "+header_text+" and range "+header_range.start+"  old"+range.start
      header_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: header_text), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
      header_buffer = header_editor.getBuffer()
      @addMiniBufferChangeListener(header_buffer, @sourceBuffer)
      @header = {marker: header_marker, buffer: header_buffer, editor: header_editor}
    # now, substring of text we will show
    segmentText = match.matchText.substring(6, match.matchText.length - 6)
    #console.log "segments "+segmentText
    chunks = segmentText.split "ʔ"
    #console.log "chuncks "+chunks
    #for each segment, create a new mini code editor
    model_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: chunks[1]), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
    #get a text buffer for that segment
    text_buffer = model_editor.getBuffer()
    #add all segments to a dictionary for later access
    @segments.push {title: chunks[0], code: model_editor}
    #now, while we're setting up the mini code editors,
    #we want to add some listeners to enable linked editing
    @addMiniBufferChangeListener(text_buffer, @sourceBuffer)

  getSegments: ->
    return @segments

  getHeader: ->
    return @header

  # Tear down any state and detach
  destroy: ->
    @segments = []
    @header = null

  addMiniBufferChangeListener: (mini_buffer, source_buffer) ->
    mini_buffer.onDidChange (e) =>
      console.log "modified! --"+ e.oldText+"   ++"+ e.newText+" range: "+e.oldRange+" "+e.newRange
      range = e.oldRange

      if(e.newText)
        console.log "attempting to link edit"
        source_buffer.insert(e.oldRange.start, e.newText)
      else if(e.oldText)
        console.log "attempting to link delete"
        source_buffer.delete(new Range(e.oldRange.start, new Point(e.oldRange.end.row, e.oldRange.end.column + 1)))
