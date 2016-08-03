{Point, Range, TextBuffer} = require 'atom'
Variant = require './variant'
VariantView = require './variant-view'

'''
Segment view represents the visual appearance of a Segment, and contains a
Segment object.
'''
module.exports =
class VersionExplorerView

  constructor: (@myVariant) ->
    # divs
    #container for header + above
    #---------variants upper region
    @variantsDiv = document.createElement('div')
    @variantsDiv.classList.add('atomic-taro_editor-exploratory-variants')

    # div that contains variant display
    @variantBox_forward = document.createElement("div")
    @variantBox_forward.classList.add('variants-container-forward')
    @variantsDiv.appendChild(@variantBox_forward)

    @myVariantBox = null

    @variantBox_back = document.createElement("div")
    @variantBox_back.classList.add('variants-container-back')
    @footerDiv = document.createElement('div')


  getHeader: ->
    @variantsDiv

  getFooter: ->
    @footerDiv

  getDiv: ->
    @variantsDiv

  openVariantsDiv: ->
    if $(@variantBox_forward).children().length > 0
      $(@variantBox_forward).slideDown(500)
    if $(@variantBox_back).children().length > 0
      $(@variantBox_back).slideDown(500)

  closeVariantsDiv: ->
    $(@variantBox_forward).slideUp(500)
    $(@variantBox_back).slideUp(500)

  addVariantsDiv: ->
    $(@variantBox_forward).hide()
    $(@variantBox_back).hide()
    #--------- add all the segments
    @myVariantBox = document.createElement('div')
    @myVariantBox.appendChild(@myVariant.getHeader())
    @variantsDiv.appendChild(@myVariantBox)

    for version in @myVariant.getModel().getVersions()
      #console.log "found version "+version.title
      varHeader = @addVariantHeaderDiv(version)
      @variantBox_back.appendChild(varHeader)

    @footerDiv.appendChild(@myVariant.getFooter())
    @footerDiv.appendChild(@variantBox_back)

  addVariantHeaderDiv: (version) ->
    headerContainer = document.createElement("div")
    headerContainer.classList.add('variants-header-box')

    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')
    boxHeader = document.createElement("div")
    boxHeader.classList.add('atomic-taro_editor-header-name')
    $(boxHeader).text(version.title)
    nameContainer.appendChild(boxHeader)
    #add placeholder for data
    dateHeader = document.createElement("div")
    $(dateHeader).text(version.date)
    dateHeader.classList.add('atomic-taro_editor-header-date.variant')
    nameContainer.appendChild(dateHeader)
    headerContainer.appendChild(nameContainer)
    headerContainer
