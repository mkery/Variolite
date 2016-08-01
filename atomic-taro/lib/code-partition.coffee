ExploratorySegmentView = require './segment-objects/exploratory-segment-view'
SharedFunctionSegmentView = require './segment-objects/shared-function-segment-view'
HeaderSegmentView = require './segment-objects/header-segment-view'
{Point, Range, TextBuffer} = require 'atom'

'''
The one job of code partition is to take an original code file and split it into
segments readable by our tool.
'''
module.exports =
class CodePartition
  startString: "#ʕ•ᴥ•ʔ#"
  endString: "##ʕ•ᴥ•ʔ"
  splitSize: 7
  segments: []
  sourceBuffer: null
  sourceEditor: null

  constructor: (sourceEditor, sourceBuffer, segments) ->
    @sourceEditor = sourceEditor
    @sourceBuffer = sourceBuffer
    @segments = segments

  getSegments: ->
    @segments

  partition: ->
    console.log "starting partition!"
    startBeacon = []
    @sourceEditor.scan new RegExp('#ʕ•ᴥ•ʔ#', 'g'), (match) =>
      #console.log "found #ʕ•ᴥ•ʔ#!"
      startBeacon.push match

    endBeacon = []
    @sourceEditor.scan new RegExp('##ʕ•ᴥ•ʔ', 'g'), (match) =>
      endBeacon.push match
      #console.log "found ##ʕ•ᴥ•ʔ!"

    if startBeacon.length == 0
      header_marker = null
      header_text = @sourceBuffer.getText()
      header_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: header_text), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
      header = new HeaderSegmentView(null, header_editor, header_marker, "")
      @segments.push header
      #@header.getModel().addChangeListeners(sourceBuffer)

    else
      @addSegments(startBeacon, endBeacon)

    console.log "end partition"

  addSegments: (startBeacon, endBeacon) ->
    length = Math.min(startBeacon.length, endBeacon.length)
    prev = new Point(0,0)
    for i in [0...length]
      sb = startBeacon[i]
      eb = endBeacon[i]

      # create a marker for this range so that we can keep track
      range = new Range(sb.range.start, eb.range.end)
      marker = @sourceEditor.markBufferRange(range)

      # ---------------------------------------------
      #if segments is empty, this is the first match,
      # also capture the header
      if (range.start.row - prev.row) > 1 or (range.start.col - prev.col) > 1
        @addNormalCodeSegment(prev, range.start)
      # ---------------------------------------------

      # now, substring of text we will show
      segmentText = @sourceEditor.getTextInBufferRange(range)
      #console.log "segments "+segmentText
      segmentTitle = ""
      segmentCode = segmentText.substring(7, segmentText.length - 7)
      chunks = segmentCode.split "ʔ"
      if chunks.length > 1
        segmentTitle = chunks[0]
        segmentCode = chunks[1]
      #console.log "chuncks "+chunks
      #for each segment, create a new mini code editor
      model_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: segmentCode), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
      #add all segments to a dictionary for later access
      if segmentTitle.startsWith("%Shared")# todo, a way to recognize a shared function
        segmentTitle = segmentTitle.substring(1)
        segment = new SharedFunctionSegmentView(null, model_editor, marker, segmentTitle)
      else
        segment = new ExploratorySegmentView(model_editor, @sourceBuffer, marker, segmentTitle)

      @segments.push segment
      prev = range.end

    endPoint = @sourceBuffer.getEndPosition()
    if (endPoint.row - prev.row) > 1 or (endPoint.col - prev.col) > 1
      @addNormalCodeSegment(prev, endPoint)

  addNormalCodeSegment: (startPoint, endPoint) ->
    header_range = new Range(startPoint, endPoint)
    header_marker = @sourceEditor.markBufferRange(range: header_range)
    header_text = @sourceEditor.getTextInBufferRange(header_range)
    header_editor = atom.workspace.buildTextEditor(buffer: new TextBuffer(text: header_text), grammar: atom.grammars.selectGrammar("file.py"),  scrollPastEnd: false)
    header = new HeaderSegmentView(null, header_editor, header_marker, "")
    header.getModel().addChangeListeners(sourceBuffer)
    @segments.push header
