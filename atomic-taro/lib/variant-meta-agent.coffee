{TextEditor} = require 'atom'
{Point, Range} = require 'atom'
Variant = require './segment-objects/variant-model'
VariantView = require './segment-objects/variant-view'
MainMenuHeader = require './segment-objects/main-menu-header'


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
    hRange = [start, new Point(end.row - 1, end.column)]
    hm = @editor.markBufferRange(hRange, invalidate: 'never', reversed: true)
    #editor.decorateMarker(hm, type: 'highlight', class: 'highlight-pink')
    hm.setProperties(myVariant: variant)

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
    insertPoint = variant.getModel().getVariantRange().start
    variant.getModel().clearTextInRange()
    unravel(variant, insertPoint, metaData.text)


  unravel: (variant, instertPoint, text) ->
    start = insertPoint

    for item in text
      if item.varID?
        nestID = item.varID
        # then this item is a nested variant
        nested = variant.getModel().findNested(nestID)
        if nested?
          insertPoint = nested.getModel().travelToCommit(item, insertPoint)
          if nestModel.pendingDestruction == true # temporarily re-instantiate
            console.log "Reinstating "+nestModel.getTitle()
            nest.reinstate()
        else
          nested = loadVariantBox(item)

      else
        range = @model.insertTextInRange(insertPoint, item.text, 'skip')
        insertPoint = range.end

    after = @model.insertTextInRange(insertPoint, " ", 'skip')
    newRange = [start, new Point(insertPoint.row, insertPoint.column)]
    newRange = @model.clipRange(newRange)
    #console.log "New range for "+@currentVersion.title+" is "
    #console.log newRange
    @model.setRange(newRange)
    @model.setHeaderRange(newRange)

    insertPoint = after.end
    return insertPoint



  loadVariantBox: (metaData) ->
    varID = metaData.varID
    branchID = metaData.branchID
    commitID = metaData.commitID

    # 1. make a new variant box
    # 2. load the commit
