{Point, Range, TextBuffer} = require 'atom'
ExploratorySegment = require './exploratory-segment'

'''
Segment view represents the visual appearance of a Segment, and contains a
Segment object.
'''
module.exports =
class ExploratorySegmentView

  constructor: (editor, marker, segmentTitle, segmentWidth) ->
    @model = new ExploratorySegment(@, editor, marker, segmentTitle, segmentWidth)
    @currentVariant = @model.getCurrentVariant()
    # divs
    @variantsDiv = null
    # pinned
    @pinned = false # in general is the pin button active
    @pinnedToTop = false
    @pinnedToBottom = false
    # div that contains variant display
    @variantBox_forward = null
    @currentVariantBox = null
    @variantBox_back = null
    @addVariantsDiv()

  serialize: ->
    #todo
    @model.serialize()

  deserialize: (state) ->
    '''currentVariant = state.currentVariant
    title = currentVariant.title
    @title = title
    @currentVariant.setTitle(title)
    console.log "title is "+@title'''

  getModel: ->
    @model

  getRootTitle: ->
    @model.getRootTitle()

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

  newVariant: ->
    newVariant = @model.newVariant()
    newVarDiv = newVariant.getHeader()
    newVariant.setVariantsShowing(true)
    $(newVarDiv).hide()
    #add to above box and make sure variantBox_forward is showing
    @currentVariantBox.appendChild(newVarDiv)
    #$(@variantBox_forward).show()
    @openVariantsDiv()

    # give the new variant the styling of 'current variant'
    $(newVarDiv).addClass('variant')
    $(newVariant.getHeader()).addClass('activeVariant')

    # now transition the current variant to the style of a non-current variant
    # and slide in the new variant
    c_div = @currentVariant.getHeader()
    $(@variantBox_back).prepend($(c_div))
    $(c_div).removeClass('variant')
    $(c_div).addClass 'inactive_variant', complete: =>
      @currentVariant.makeNonCurrentVariant()
      $(newVarDiv).slideToggle 'slow'
      # finally, make new variant the current variant
      @currentVariant = newVariant


  addVariantsDiv: ->
    #container for header + above
    @variantsDiv = document.createElement('div')
    @variantsDiv.classList.add('atomic-taro_editor-exploratory-variants')
    #---------variants upper region
    @addVariantsDiv_Back()
    @addVariantsDiv_Forward()
    @variantsDiv.appendChild(@variantBox_forward)
    #--------- add all the segments
    @currentVariantBox = document.createElement('div')
    @currentVariantBox.appendChild(@currentVariant.getHeader())
    @variantsDiv.appendChild(@currentVariantBox)

    @footerDiv = document.createElement('div')
    @footerDiv.appendChild(@currentVariant.getFooter())
    @footerDiv.appendChild(@variantBox_back)

  addVariantHeaderDiv: (headerContainer) ->
    nameContainer = document.createElement("div")
    nameContainer.classList.add('atomic-taro_editor-header-name-container')
    boxHeader = document.createElement("div")
    boxHeader.classList.add('atomic-taro_editor-header-name')
    $(boxHeader).text(@getRootTitle()+": \"variant x\"")
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
