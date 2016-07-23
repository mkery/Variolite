Segment = require './segment'
SharedFunctionSegment = require './shared-function-segment'
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
    marker = @sourceEditor.markBufferRange(range)

    # ---------------------------------------------
    #if segments is empty, this is the first match,
    # also capture the header
    if @segments.length <= 0
      header_range = new Range(new Point(0,0), range.start)
      @addHeaderSegment(header_range)
    # ---------------------------------------------

    # now, substring of text we will show
    segmentText = match.matchText.substring(6, match.matchText.length - 6)
    #console.log "segments "+segmentText
    chunks = segmentText.split "ʔ"
    segmentTitle = chunks[0]
    #console.log "chuncks "+chunks
    #for each segment, create a new mini code editor
    model_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: chunks[1]), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
    #add all segments to a dictionary for later access
    if segmentTitle.startsWith("%Shared")# todo, a way to recognize a shared function
      segmentTitle = segmentTitle.substring(1)
      segment = new SharedFunctionSegment(model_editor, marker, segmentTitle)
    else
      segment = new Segment(model_editor, marker, segmentTitle)
    @segments.push segment
    #now, while we're setting up the mini code editors,
    #we want to add some listeners to enable linked editing
    segment.addChangeListeners(@sourceBuffer)

  #Add header segment
  addHeaderSegment: (header_range) ->
    header_marker = @sourceEditor.markBufferRange(range: header_range)
    header_text = @sourceEditor.getTextInBufferRange(header_range)
    header_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: header_text), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
    @header = new Segment(header_editor, header_marker, "")
    @header.addChangeListeners(@sourceBuffer)

  getSegments: ->
    return @segments

  getHeader: ->
    return @header

  # Tear down any state and detach
  destroy: ->
    @segments = []
    @header = null


  saveSegments: (e) ->
    console.log "saving segments!"
    @sourceBuffer.save()
