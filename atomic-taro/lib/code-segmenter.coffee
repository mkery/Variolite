Segment = require './segment'
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
    console.log "matches on "+range
    marker = @sourceEditor.markBufferRange(range)
    console.log "worked?? "+marker.getStartBufferPosition()
    # if segments is empty, this is the first match,
    # also capture the header
    if @segments.length <= 0
      header_range = new Range(new Point(0,0), range.start)
      header_marker = @sourceEditor.markBufferRange(range: header_range)
      header_text = @sourceEditor.getTextInBufferRange(header_range)
      console.log "header text! "+header_text+" and range "+header_range.start+"  old"+range.start
      header_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: header_text), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
      @header = new Segment(header_editor, header_marker, "")
      @addMiniBufferChangeListener(@header, @sourceBuffer)

    # now, substring of text we will show
    segmentText = match.matchText.substring(6, match.matchText.length - 6)
    #console.log "segments "+segmentText
    chunks = segmentText.split "ʔ"
    #console.log "chuncks "+chunks
    #for each segment, create a new mini code editor
    model_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: chunks[1]), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
    #add all segments to a dictionary for later access
    segment = new Segment(model_editor, marker, chunks[0])
    @segments.push segment
    #now, while we're setting up the mini code editors,
    #we want to add some listeners to enable linked editing
    @addMiniBufferChangeListener(segment, @sourceBuffer)

  getSegments: ->
    return @segments

  getHeader: ->
    return @header

  # Tear down any state and detach
  destroy: ->
    @segments = []
    @header = null

  addMiniBufferChangeListener: (segment, source_buffer) ->
    segment.getBuffer().onDidChange (e) =>
      #console.log "modified! --"+ e.oldText+"   ++"+ e.newText+" range: "+e.oldRange+" "+e.newRange
      range_start = e.oldRange.start
      range_end = e.oldRange.end
      marker_start = segment.getMarker().getStartBufferPosition()
      range = new Range(new Point(marker_start.row + range_start.row, marker_start.column + range_start.column), new Point(marker_start.row + range_end.row, marker_start.column + range_end.column))
      #console.log "started at: "+marker_start+" doctors range "+range
      if(e.newText)
        #console.log "attempting to link edit"
        source_buffer.insert(range.start, e.newText)
      else if(e.oldText)
        #console.log "attempting to link delete"
        source_buffer.delete(new Range(range.start, range.end))
