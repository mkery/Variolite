SegmentView = require './segment-objects/segment-view'
SharedFunctionSegmentView = require './segment-objects/shared-function-segment-view'
HeaderSegmentView = require './segment-objects/header-segment-view'
{Point, Range, TextBuffer} = require 'atom'

'''
The one job of code partition is to take an original code file and split it into
segments readable by our tool.
'''
module.exports =
class CodePartition
  splitString: "#ʕ•ᴥ•ʔ"
  splitSize: 6
  header: null
  segments: null
  sourceBuffer: null
  sourceEditor: null

  constructor: (sourceEditor, sourceBuffer, header, segments) ->
    @sourceEditor = sourceEditor
    @sourceBuffer = sourceBuffer
    @header = header
    @segments = segments

  getSegments: ->
    @segments

  getHeader: ->
    @header

  partition: () ->
    @sourceEditor.scan new RegExp(@splitString+'(.*(\n)*)+?'+@splitString, 'g'), (match) =>
      # create a marker for this range so that we can keep track
      range = match.range
      marker = @sourceEditor.markBufferRange(range)

      # ---------------------------------------------
      #if segments is empty, this is the first match,
      # also capture the header
      if @segments.length <= 0
        header_range = new Range(new Point(0,0), range.start)
        header_marker = @sourceEditor.markBufferRange(range: header_range)
        header_text = @sourceEditor.getTextInBufferRange(header_range)
        header_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: header_text), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
        @header = new HeaderSegmentView(header_editor, header_marker, "")
        @header.getModel().addChangeListeners(sourceBuffer)
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
        segment = new SharedFunctionSegmentView(model_editor, marker, segmentTitle)
      else
        segment = new SegmentView(model_editor, marker, segmentTitle)
      #now, while we're setting up the mini code editors,
      #we want to add some listeners to enable linked editing
      segment.getModel().addChangeListeners(@sourceBuffer)
      @segments.push segment
