
VariantView = require './variant-view'
{Point, Range, TextBuffer, DisplayMarker, TextEditor} = require 'atom'

'''
The one job of code partition is to take an original code file and split it into
segments readable by our tool.
'''
module.exports =
class VariantPartition
  startString: "#ʕ•ᴥ•ʔ#"
  endString: "##ʕ•ᴥ•ʔ"
  splitSize: 7
  variants: []
  sourceBuffer: null
  sourceEditor: null

  constructor: (sourceEditor, sourceBuffer) ->
    @sourceEditor = sourceEditor
    @sourceBuffer = sourceBuffer
    @variants = []

  getStartAnnotation: ->
    @startString

  getEndAnnotation: ->
    @endString

  getVariants: ->
    @variants

  partition: ->
    startBeacon = []
    @sourceEditor.scan new RegExp('#ʕ•ᴥ•ʔ#', 'g'), (match) =>
      startBeacon.push(match)

    endBeacon = []
    @sourceEditor.scan new RegExp('##ʕ•ᴥ•ʔ', 'g'), (match) =>
      endBeacon.push(match)
      #console.log "found ##ʕ•ᴥ•ʔ!"

    @addSegments(startBeacon, endBeacon)


  addSegments: (startBeacon, endBeacon) ->
    length = Math.min(startBeacon.length, endBeacon.length)
    rowDeletedOffset = 0

    variantWidth = @sourceEditor.getElement().getWidth()

    for i in [0...length]
      sb = startBeacon[i]
      eb = endBeacon[i]

      # create a marker for this range so that we can keep track
      #range = new Range(new Point(sb.range.start.row - rowDeletedOffset, sb.range.start.col), new Point(eb.range.end.row - rowDeletedOffset, eb.range.end.col))
      range = [sb.range.start, eb.range.end]
      marker = @sourceEditor.markBufferRange(range, invalidate: 'never')
      '''
      below, useful for debug!!!
      dec = @sourceEditor.decorateMarker(marker, type: 'highlight', class: 'highlight-green')
      '''

      start = range[0]
      end = range[1]

      variant = new VariantView(@sourceEditor, marker, "", variantWidth)
      @variants.push(variant)


      headerElement = variant.getHeader()
      hm = @sourceEditor.markScreenPosition([start.row - 1, start.col], invalidate: 'never')
      @sourceEditor.decorateMarker(hm, {type: 'block', position: 'after', item: headerElement})

      footerElement = variant.getFooter()
      fm = @sourceEditor.markScreenPosition(end)
      @sourceEditor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})

      # now, trim annotations
      rowStart = sb.range.start.row
      rowEnd = eb.range.end.row
      @sourceBuffer.deleteRow(rowStart - rowDeletedOffset)
      rowDeletedOffset += 1
      @sourceBuffer.deleteRow(rowEnd - rowDeletedOffset)
      rowDeletedOffset += 1
