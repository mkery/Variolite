{Point, Range, TextBuffer} = require 'atom'
VariantsManager = require '../variants-manager'
Variant = require '../segment-objects/variant'
VariantView = require '../segment-objects/variant-view'



module.exports =
class ExplorerVariantElement

  constructor: (@variant, @version, @parentDiv, @parentElement) ->
    @nestChildrenDivs = []
    @childDivs = []
    @myContainer = null
    @myLabel = null
    @nestedTree = null

    @initialize()
    @parentDiv.appendChild(@myContainer)


  initialize: ->
    ExplorerGroupElement = require './explorer-group-element'
    # if nested, create a div with a tree structure
    if @version.nested.length > 0
      @liWithNested(@variant, @version)

      for nest in @version.nested
        if nest.rootVersion? # uninitialized json-form variant
          elem = new ExplorerGroupElement(null, nest.rootVersion, @nestedTree, @)
        else # initialized VariantView variant
          elem = new ExplorerGroupElement(nest, nest.getModel().getRootVersion(), @nestedTree, @)
        @nestChildrenDivs.push elem

    # if no nested, create a div without a tree structure
    else
      @liPlain(@variant, @version)

    # finally, add child nodes
    for child in @version.children
      @childDivs.push new ExplorerVariantElement(@variant, child, @parentDiv, @parentElement)


  refresh: ->
    # make sure label is refreshed
    #$(@myLabel).html(@version.title)

    nested = @version.nested
    # now, make sure nested elemes are correct
    for nelem, index in @nestChildrenDivs
      nelem.setVariant(nested[index])
      nelem.refresh()


  collapse: ->
    $(@nestedTree).slideToggle('fast')


  select: ->
    $(@myContainer).addClass('selected')


  '''
  Necissary for any variants that are not initialized until they are used
  '''
  setVariant: (v) ->
    @variant = v


  liPlain: (variant, version) ->
    @myContainer = document.createElement('li')
    @myContainer.classList.add('list-item')
    @myContainer.classList.add('atomic-taro_explore_version')

    @myLabel = document.createElement('span')
    @myLabel.classList.add('atomic-taro_explore_version-label')
    @myLabel.classList.add('icon-git-commit')
    $(@myLabel).data('variantElem', @)
    if version.title == variant?.getModel().getCurrentVersion().title
      @myLabel.classList.add('focused')
    $(@myLabel).html(version.title)
    @myContainer.appendChild(@myLabel)


  liWithNested: (variant, version) ->
    @myContainer = document.createElement('li')
    @myContainer.classList.add('list-nested-item')
    @myContainer.classList.add('atomic-taro_explore_version')

    ver = document.createElement('div')
    ver.classList.add('list-item')
    ver.classList.add('atomic-taro_explore_group_label')
    $(ver).data('variantElem', @)

    @myLabel = document.createElement('span')
    @myLabel.classList.add('atomic-taro_explore_version-label')
    $(@myLabel).data('variantElem', @)
    @myLabel.classList.add('icon-git-commit')
    if version.title == variant?.getModel().getCurrentVersion().title
      @myLabel.classList.add('focused')
    $(@myLabel).html(version.title)
    ver.appendChild(@myLabel)
    @myContainer.appendChild(ver)

    @nestedTree = document.createElement('ul')
    @nestedTree.classList.add('list-tree')
    @myContainer.appendChild(@nestedTree)


  switchToVersion: () ->
    if @variant == null # an uninitialized nested variant
      @parentElement.switchToVersion()
      if @variant == null
        @parentElement.refresh()

    @variant.switchToVersion(@version)
    @focus()

  focus: ->
    if @parentElement?
      @parentElement?.focus()
    else
      #at highest label, get rid of the previous highlighted version
      $(@myContainer).find('.atomic-taro_explore_version-label').removeClass('focused')

    $(@myLabel).addClass('focused')
