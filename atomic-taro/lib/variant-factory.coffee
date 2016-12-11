{TextEditor} = require 'atom'
{Point, Range} = require 'atom'
Variant = require './segment-objects/variant-model'
VariantView = require './segment-objects/variant-view'
MainHeaderMenu = require './main-header-menu'


module.exports =
class VariantFactory


  # {sourceEditor: editor, marker: marker, title: @fileName, taroView: @taroView, undoAgent: @undoAgent, provAgent: @provenanceAgent})
  constructor: (@filePath, @taroView, @undoAgent, @provenanceAgent) ->
    # nothin much


  '''
    When the user selects to 'travel' to an earlier commit, this starts the process
    of adjusting the whole UI to reflect that past or future state of the code.
  '''
  wrapNewVariant: (editor, masterVariant) ->
    # first, get range
    clickRange = editor.getSelectedBufferRange()
    range = [new Point(clickRange.start.row, 0), new Point(clickRange.end.row, 100000000000)]
    range = editor.getBuffer().clipRange(range)
    start = range.start
    end = range.end

    # now, see if there are any preexisting variants that overlap
    overlap_start = editor.findMarkers(containsBufferPosition: range.start)
    overlap_end = editor.findMarkers(containsBufferPosition: range.end)
    selected = editor.findMarkers(containsBufferRange: range)
    #console.log "found N markers: start "+overlap_start.length+", end: "+overlap_end.length+", "+selected.length

    # cannot allow new variants that partially intersect other variants
    if overlap_start.length == overlap_end.length == selected.length
        nest_Parent = null
        for marker in selected
          p = marker.getProperties().myVariant
          if p?
            nest_Parent = [p.getModel().getCurrentVersion(),p]

        # now initialize everything
        marker = editor.markBufferRange(range, invalidate: 'never')
        #editor.decorateMarker(marker, {type: 'highlight', class: 'highlight-green'})

        #finally, make the new variant!
        variant = @buildVariant(start, end, editor, marker, "v0")
        variant.buildVariantDiv()

        # Either add as a neted variant to a parent, or add as a top-level variant
        if nest_Parent != null
          nest_Parent[1].addedNestedVariant(variant, nest_Parent[0])  #nest_Parent is an array - second item is the VariantView
        else
          console.log "adding variant to manager"
          masterVariant.addedNestedVariant(variant, masterVariant.getModel().getCurrentVersion())




  '''
    Starting with a plain code file, adds existing variant boxes to display.
    Existing variant boxes are indicated by annotations in the code.
  '''
  initVariants: (editor, masterVariant) ->
    # Get the location of all variant annotaions in the file.
    beacons = @findMarkers(editor)
    list_offset = @addAllVariants(editor, beacons, 0, [])

    # Fix range for the master variant. Since we've just deleted a bunch of
    # rows that only contained variant annotations, the length of the file
    # has changed.
    wholeFile = [new Point(0,0), new Point(10000000, 10000000)]
    range = editor.getBuffer().clipRange(wholeFile)
    masterVariant.getModel().getMarker().setBufferRange(range)

    # Now, make all variant boxes in the file nested children of the master
    # file-level variant.
    curr = masterVariant.getModel().getCurrentVersion()
    masterVariant.addedNestedVariant(v, curr) for v in list_offset.list



  buildMasterVariant: (editor, masterVariant) ->
    # First, wrap the entire file in a variant by default
    wholeFile = [new Point(0,0), new Point(10000000, 10000000)]
    range = editor.getBuffer().clipRange(wholeFile)
    marker = editor.markBufferRange(range, invalidate: 'never')
    
    masterVariant = @buildVariant(range.start, range.end, editor, marker,  @fileName)
    masterVariant


  '''
    Search file for variant box annotations and match nested pairs of annotations to
    get the boundaries of each variant box, even if they are nested.
  '''
  findMarkers: (editor) ->
    beacons = []
    sourceBuffer = editor.buffer
    lineArray = sourceBuffer.getLines()
    prevStart = null
    endStack = []
    for line, index in lineArray
      if line.includes("#%%^%%")

        if ((prevStart != null) and (prevStart.end == null))
          b = {start: new Point(index, 0), end: null, nested: []}
          prevStart.nested.push(b)
          endStack.push(b)
          prevStart = b
        else
          beacons.push({start: new Point(index, 0), end: null, nested: []})
          prevStart = beacons[beacons.length - 1]
          endStack.push(prevStart)

      else if line.includes("#^^%^^")
        endStack.pop().end = new Point(index , 0)
    #return beacons
    beacons



  '''
    For each start/end pair of annotaions in 'beacons', replace them with a variant box in the
    code. As we delete the annotations to replace them with GUI, keep the rowDeletedOffset
    updated.
  '''
  addAllVariants: (editor, beacons, rowDeletedOffset) ->
    variantList = []
    for b in beacons
      priorRow = rowDeletedOffset

      # First, recursively add any nested variant boxes of this variant box
      nested = b.nested
      grandchildren = []
      if nested.length > 0
        #cancel out end marker offset, since we are inside the range of that marker
        nestedOffset = rowDeletedOffset
        list_offset = @addAllVariants(editor, nested, nestedOffset)
        grandchildren = list_offset.list # list of new VariantViews
        rowDeletedOffset = list_offset.offset

      # Now, create this variant box
      v_offset = @addVariant(editor, b, priorRow, rowDeletedOffset)
      variant = v_offset.variant
      variantList.push variant
      rowDeletedOffset = v_offset.offset # update rowDeletedOffset
      for g in grandchildren # If there where nested, now add these to the current Variant
        variant.addedNestedVariant(g, variant.getModel().getCurrentVersion())

    #return
    {list: variantList, offset: rowDeletedOffset}




  debugMarkers: (marker, editor) ->
     dec = editor.decorateMarker(marker, type: 'highlight', class: 'highlight-pink')



  '''
    Build a single Variant.
  '''
  addVariant: (editor, b, rowDeletedOffset, endDeleteOffset, title) ->
    if endDeleteOffset? == false
      endDeleteOffset = rowDeletedOffset

    editorBuffer = editor.getBuffer()

    # Get start and end annotation Point of beacon
    range = [b.start, b.end]
    start = new Point(range[0].row - rowDeletedOffset, 0) # substract rowDeletedOffset
    end = new Point(range[1].row - endDeleteOffset - 1, range[1].column)
    range = [start, new Point(end.row, 100000000000)]
    range = editorBuffer.clipRange(range) # This is important! To end at the end of the last line.

    # create a marker for this range so that we can keep track
    marker = editor.markBufferRange(range, invalidate: 'never')


    # get title from start annnotation
    rowStart = b.start.row
    if not title?
      title = editorBuffer.lineForRow(rowStart - rowDeletedOffset)
      title = title.trim().substring(6)
    rowEnd = b.end.row

    # now, delete annotation rows
    editorBuffer.deleteRow(rowStart - rowDeletedOffset)
    endDeleteOffset += 1
    editorBuffer.deleteRow(rowEnd - endDeleteOffset)
    endDeleteOffset += 1


    #finally, make the new variant!
    variant = @buildVariant(start, end, editor, marker, title)

    return {variant: variant, offset: endDeleteOffset}




  buildVariant: (start, end, editor, marker, title, altHeader) ->
    # create variant
    variant = new VariantView({sourceEditor: editor, marker: marker, altHeader: altHeader, title: title, taroView: @taroView, undoAgent: @undoAgent, provAgent: @provenanceAgent})
    marker.setProperties(myVariant: variant)

    # mark header
    headerElement = variant.getHeader()
    hRange = [start, new Point(end.row - 1, end.column)]
    hm = editor.markBufferRange(hRange, invalidate: 'never', reversed: true)
    #editor.decorateMarker(hm, type: 'highlight', class: 'highlight-pink')
    hm.setProperties(myVariant: variant)

    # make header decoration
    hdec = editor.decorateMarker(hm, {type: 'block', position: 'before', item: headerElement})
    variant.setHeaderMarker(hm)
    variant.setHeaderMarkerDecoration(hdec)

    # mark footer
    footerElement = variant.getFooter()

    # make footer decoration
    fdec = editor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})
    variant.setFooterMarkerDecoration(fdec)

    return variant
