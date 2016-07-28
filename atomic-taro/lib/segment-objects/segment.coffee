{Point, Range, TextBuffer} = require 'atom'

'''
Represents a single segment of exploratory code.
'''
module.exports =
class Segment

  constructor: (@editor, @marker, @title, @elder = null, @children = []) ->
    @buffer = @editor.getBuffer()
    @mirroring = false
    @linkedEditing = false

  serialize: ->
    title: @title

  variantSerialize: ->#todo capture elders
    title : @title
    text : @buffer.getText()
    #elder: if @elder then @fullySerialize(@elder) else null
    #console.log "I am "
    #console.log @
    #console.log @children
    #console.log "grandkids"
    #if (@children.length > 0) then console.log(@children[0].getChildren())
    children: if (@children.length > 0) then (child.variantSerialize() for child in @children) else null

  fullySerialize: (segment) ->
    console.log segment
    title : segment.getTitle()
    text : segment.getBuffer().getText()

  getEditor: ->
    @editor

  getBuffer: ->
    @buffer

  getMarker: ->
    @marker

  getTitle: ->
    @title

  setTitle: (title) ->
    @title = title

  setElder: (parent) ->
    @elder = parent

  addChild: (child) ->
    console.log @title+" am getting a new child"
    @children.push child

  getChildren: ->
    console.log @title+" have N children "+@children.length
    @children

  setLinkedEditing: (bool) ->
    @linkedEditing

  #Add change listeners to the segment buffers
  addChangeListeners: (source_buffer) ->
    @segmentBufferChanged(source_buffer)
    #@originalBufferChanged(source_buffer)


  #Add change listeners to the segment buffers
  segmentBufferChanged: (source_buffer) ->
    @buffer.onDidChange (e) =>
      if @linkedEditing
        if @mirroring == true
          @mirroring = false
        else
          @mirroring = true
          #console.log "modified! --"+ e.oldText+"   ++"+ e.newText+" range: "+e.oldRange+" "+e.newRange
          '''
          Here, we are offsetting the range in our mini-editor for this segment, by where
          that segment starts in the original buffer. Once we have the correct range for the
          original buffer, we can update the original buffer
          '''
          range_start = e.oldRange.start
          range_end = e.oldRange.end
          marker_start = @marker.getStartBufferPosition()
          range = new Range(new Point(marker_start.row + range_start.row, marker_start.column + range_start.column), new Point(marker_start.row + range_end.row, marker_start.column + range_end.column))
          #console.log "started at: "+marker_start+" doctors range "+range
          if(e.newText)
            #console.log "attempting to link edit"
            source_buffer.insert(range.start, e.newText)
          else if(e.oldText)
            #console.log "attempting to link delete"
            source_buffer.delete(new Range(range.start, range.end))

  #Add change listeners to the segment buffers
  originalBufferChanged: (source_buffer) ->
    source_buffer.onDidStopChanging (e) =>
      if @linkedEditing
        if @mirroring == true
          @mirroring = false
        else
          @mirroring = true
          #console.log "modified! --"+ e.oldText+"   ++"+ e.newText+" range: "+e.oldRange+" "+e.newRange
          '''
          Here, we are offsetting the range in our mini-editor for this segment, by where
          that segment starts in the original buffer. Once we have the correct range for the
          original buffer, we can update the original buffer
          '''
          range_start = e.oldRange.start
          range_end = e.oldRange.end
          marker_start = @marker.getStartBufferPosition()
          range = new Range(new Point(marker_start.row - range_start.row, marker_start.column - range_start.column), new Point(marker_start.row - range_end.row, marker_start.column - range_end.column))
          #console.log "started at: "+marker_start+" doctors range "+range
          if(e.newText)
            #console.log "attempting to link edit"
            @buffer.insert(range.start, e.newText)
          else if(e.oldText)
            #console.log "attempting to link delete"
            @buffer.delete(new Range(range.start, range.end))
