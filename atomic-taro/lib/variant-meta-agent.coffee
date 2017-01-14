{TextEditor} = require 'atom'
{Point, Range} = require 'atom'
Variant = require './segment-objects/variant-model'
VariantView = require './segment-objects/variant-view'
MainMenuHeader = require './segment-objects/main-menu-header'
fs = require 'fs'


module.exports =
class VariantMetaAgent

  constructor: (@taroView, @undoAgent, @metaFolder, @travelAgent, @editor) ->
    # nothing


  buildMasterVariant: ->
    # First, wrap the entire file in a variant by default
    wholeFile = [new Point(0,0), new Point(10000000, 10000000)]
    range = @editor.getBuffer().clipRange(wholeFile)
    marker = @editor.markBufferRange(range, invalidate: 'never')

    fileName = @taroView.getFileName()
    altHeader = new MainMenuHeader()
    altHeader.setTaroView(@taroView)
    altFooter = document.createElement('div')
    variant = new VariantView({id: 0, sourceEditor: @editor, marker: marker, altHeader: altHeader, altFooter: altFooter, title: fileName, taroView: @taroView, undoAgent: @undoAgent, metaFolder: @metaFolder, travelAgent: @travelAgent})
    masterVariant = @buildVariant(range.start, range.end, marker, fileName, variant)
    masterVariant



  buildVariant: (start, end, marker, title, variant) ->
    # create variant
    if not variant?
        variant = new VariantView({sourceEditor: @editor, marker: marker, title: title, taroView: @taroView, undoAgent: @undoAgent, metaFolder: @metaFolder, travelAgent: @travelAgent})
    marker.setProperties(myVariant: variant)

    # mark header
    headerElement = variant.getHeader()
    if end.row != start.row
      hRange = [start, new Point(end.row - 1, end.column)]
    else
      hRange = [start, end]
    hm = @editor.markBufferRange(hRange, invalidate: 'never', reversed: true)
    #editor.decorateMarker(hm, type: 'highlight', class: 'highlight-pink')
    hm.setProperties(myVariant: variant)
    variant.getModel().setHeaderMarker(hm)

    # make header decoration
    hdec = @editor.decorateMarker(hm, {type: 'block', position: 'before', item: headerElement})
    variant.setHeaderMarker(hm)
    variant.setHeaderMarkerDecoration(hdec)

    # mark footer
    footerElement = variant.getFooter()

    # make footer decoration
    fdec = @editor.decorateMarker(marker, {type: 'block', position: 'after', item: footerElement})
    variant.setFooterMarkerDecoration(fdec)

    return variant


  unpackMetaData: (variant, metaData) ->
    insertPoint = variant.getModel().getVariantRange().start # the top of the file initially
    variant.getModel().clearTextInRange() # clear all text. Fix in the future, this will wreck out of tool changes
    @unravelInit(variant, insertPoint, metaData.text) # write all code from the metadata


  unravelInit: (variant, insertPoint, text) ->
    start = insertPoint # top of the file initially
    model = variant.getModel()

    for item in text
      if item.varID? # OK, this is a nested variant, so let's go look for its data file
        insertPoint = @loadVariantBox(variant, item, insertPoint)

      else # plain text, so just insert it.
        range = model.insertTextInRange(insertPoint, item.text, 'skip')
        insertPoint = range.end

    after = model.insertTextInRange(insertPoint, " ", 'skip')
    newRange = [start, new Point(insertPoint.row - 1, Number.MAX_SAFE_INTEGER)]
    newRange = model.clipRange(newRange)

    #console.log "New range for "+model.getCurrentVersion().title+" is "
    #console.log newRange

    if not model.getMarker()? # no marker set up yet.
      marker = @editor.markBufferRange(newRange, invalidate: 'never')
      model.setMarker(marker)
      @buildVariant(newRange.start, newRange.end, marker, "title", variant)
    else
      # Now update this variant's range, since we've just changed its internal text
      model.setRange(newRange)
      model.setHeaderRange(newRange)

    insertPoint = after.end
    return insertPoint # where we should next start writing this file



  loadVariantBox: (parentVariant, metaData, insertPoint) ->
    varID = metaData.varID
    branchID = metaData.branchID
    commitID = metaData.commitID

    # 1. make a new variant box
    babyVariant = parentVariant.buildBabyFromDir(metaData)
    parentVariant.getModel().addNested(babyVariant)

    # 3. load the commit
    commitFile = @metaFolder+"/"+varID.substring(0, 11)+"/"+branchID+"/"+commitID+".json"
    contents = []
    try
      data = fs.readFileSync(commitFile, 'utf8')
      contents = JSON.parse(data)
      #console.log "SUCESS: meta data found for nested variant", contents
    catch err
      console.log "No meta data found for nested variant!", err

    curBranch = babyVariant.getModel().getCurrentVersion()
    curBranch.addAndSetCommit(commitID, contents)

    # 4. add this variant's contents into the editor
    insertPoint = @unravelInit(babyVariant, insertPoint, contents.text)

    return insertPoint



  wrapNewVariant: (editor, masterVariant) ->
    # first, get range
    clickRange = editor.getSelectedBufferRange()
    console.log "click range was ", clickRange
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
        #@editor.decorateMarker(marker, {type: 'highlight', class: 'highlight-green'})

        #finally, make the new variant!
        variant = @buildVariant(start, end, marker, "v0")
        variant.buildVariantDiv()

        # Either add as a neted variant to a parent, or add as a top-level variant
        if nest_Parent != null
          nest_Parent[1].addedNestedVariant(variant, nest_Parent[0])  #nest_Parent is an array - second item is the VariantView
        else
          #console.log "adding variant to manager"
          masterVariant.addedNestedVariant(variant, masterVariant.getModel().getCurrentVersion())
