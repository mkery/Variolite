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
    @variantsDiv = null

    # div that contains variant display
    @variantBox_forward = null
    @myVariantBox = null
    @variantBox_back = null
    @addVariantsDiv()

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
    #container for header + above
    @variantsDiv = document.createElement('div')
    @variantsDiv.classList.add('atomic-taro_editor-exploratory-variants')
    #---------variants upper region
    @addVariantsDiv_Back()
    @addVariantsDiv_Forward()
    @variantsDiv.appendChild(@variantBox_forward)
    #--------- add all the segments
    @myVariantBox = document.createElement('div')
    @myVariantBox.appendChild(@myVariant.getHeader())
    @variantsDiv.appendChild(@myVariantBox)

    @footerDiv = document.createElement('div')
    @footerDiv.appendChild(@myVariant.getFooter())
    @footerDiv.appendChild(@variantBox_back)

  addVariantHeaderDiv: (headerContainer) ->
    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')
    boxHeader = document.createElement("div")
    boxHeader.classList.add('atomic-taro_editor-header-name')
    $(boxHeader).text("variant x")
    nameContainer.appendChild(boxHeader)
    #add placeholder for data
    dateHeader = document.createElement("div")
    $(dateHeader).text("created 7/14/19 5:04pm")
    dateHeader.classList.add('atomic-taro_editor-header-date.variant')
    nameContainer.appendChild(dateHeader)
    headerContainer.appendChild(nameContainer)

  addVariantsDiv_Forward: ->
    @variantBox_forward = document.createElement("div")
    @variantBox_forward.classList.add('variants-container-forward')
    $(@variantBox_forward).hide()

  addVariantsDiv_Back: ->
    @variantBox_back = document.createElement("div")
    @variantBox_back.classList.add('variants-container-back')

    varHeader = document.createElement("div")
    varHeader.classList.add('variants-header-box')
    @addVariantHeaderDiv(varHeader)
    #@addOutputButton(varHeader)
    @variantBox_back.appendChild(varHeader)

    varHeader1 = document.createElement("div")
    varHeader1.classList.add('variants-header-box', 'inactive')
    @addVariantHeaderDiv(varHeader1)
    #@addOutputButton(varHeader1)
    @variantBox_back.appendChild(varHeader1)

    varHeader2 = document.createElement("div")
    varHeader2.classList.add('variants-header-box')
    @addVariantHeaderDiv(varHeader2)
    #@addOutputButton(varHeader2)
    @variantBox_back.appendChild(varHeader2)
    $(@variantBox_back).hide()
