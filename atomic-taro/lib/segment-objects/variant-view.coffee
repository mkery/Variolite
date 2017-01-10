{Point, Range, TextBuffer} = require 'atom'
Variant = require './variant-model'
CommitLine = require './commit-line'
BranchMap = require './branch-map'
DiffPanels = require './diff-panels'
HeaderElement = require './header-element'

'''
variant view represents the visual appearance of a variant, and contains a
variant object.
'''
'''
  TODO
    - deactivate
    - serialize UI state?
'''
module.exports =
class VariantView


  constructor: (params) ->
    @sourceEditor = params.sourceEditor
    @root = params.taroView
    @undoAgent = params.undoAgent
    #@provenanceAgent = params.provAgent
    @travelAgent = params.travelAgent

    params['taroView'] = @
    @model = new Variant(params)

    @footerBar = params.altFooter
    if not @footerBar?
        @footerBar = document.createElement('div')
        @footerBar.classList.add('atomic-taro_editor-footer-box')

    @headerElement = params.altHeader
    if not @headerElement?
        @headerElement = new HeaderElement()
    @commitLine = null
    @branchMap = null
    @diffPanels = null


  '''
    Alternative constructor. Used in the senario where variant box has an unitialized
    nested variant box in a version that was not loaded at startup. Meaning, it wasn't
    showing annotations in the code, since it wasn't the current version at startup, so
    it's not built until later. Returns a new variant box given save data and the current
    parent variant box view @.
  '''
  makeNewFromJson: (json) ->
    variantView = new VariantView({sourceEditor: @sourceEditor, taroView: @root, undoAgent: @undoAgent})
    variantView.getModel().deserialize(json)
    variantView


  '''
    Shared by both constructors, sets up global div variables but does not build all
    components until later when the save data is loaded.
  '''
  initialize:  ->
    #footer bar that simply marks the end
    # @footerBar = document.createElement('div')
    # @footerBar.classList.add('atomic-taro_editor-footer-box')
    #
    # @headerElement = new HeaderElement(@model, @)
    # @commitLine = null
    # @branchMap = null
    # @diffPanels = null


  getCommitLine: ->
    @commitLine


  getBranchMap: ->
    @branchMap


  getHeaderElement: ->
    @headerElement


  getTravelAgent: ->
    @travelAgent


  '''
    TODO used?
  '''
  deactivate: ->
    @model.getMarker().destroy()


  '''
    Dissolves the variant box, returning whatever is currently in the box down to plain
    code sitting flat in the file. Removes all variant box divs.
  '''
  dissolve: () => # re-add when you can safely undo!
    @headerMarkDecoration.destroy()
    @footerMarkDecoration.destroy()
    @model.dissolve()
    for n in @model.getNested()
      n.dissolve()

    @undoAgent.pushChange({data: {undoSkip: true}, callback: @reinstate})


  '''
    Reverse of @dissolve. A way to undo a dissolve action on this variant box.
  '''
  reinstate: =>
    @model.reinstate()
    for n in @model.getNested()
      n.reinstate()


  '''
    TODO. Removes the currenty active version of this variant box from the header bar.
    This means that version still exists in the commit tree but cannot be interacted with.
  '''
  archive: ->
    c = @model.getCurrentVersion()
    v = @headerElement.getNextVisibleVersion(c)
    # If just 1 don't bother switching to a another verison
    if v.getID() == c.getID()
      return false

    # make the current version inactive so it's not
    # re-drawn on the version bookmark bar
    @model.archiveCurrentVerion()
    @switchToVersion(v)
    return true



  '''
    Saves the state of the variant box into a json format so that it can be reactivated
    when the tool is closed and opened again later.
  '''
  serialize: ->
    #TODO add ui?
    @model.serialize()


  '''
    Takes JSON formatted save data and updates the variant box to reflect that saved state
  '''
  deserialize: (state) ->
    @model.deserialize(state)
    #TODO


  '''
    Get the model associated with this view; the data associated with the divs of this
    variant box.
  '''
  getModel: ->
    @model


  '''
    Returns the text editor marker that marks the range in the editor controlled by
    this variant box.
  '''
  getMarker: ->
    @model.getMarker()


  '''
    Returns the title of the currently viewed version of this variant box.
  '''
  getTitle: ->
    @model.getTitle()


  '''
    Returns the div element for the footer
  '''
  getFooter: ->
    @footerBar


  '''
    Returns the div element that displays the header of this variant box
  '''
  getHeader: ->
    @headerElement.getElement()



  travelStyle: (commit) ->
    @headerElement.travelStyle(commit)
    @commitLine.addClass('historical')
    @branchMap.addClass('historical')
    $(@footerBar).addClass('historical')
    for nested in @model.getNested()
      nested.travelStyle()



  removeTravelStyle: ->
    @headerElement.removeTravelStyle()
    @commitLine.removeClass('historical')
    @branchMap.removeClass('historical')
    $(@footerBar).removeClass('historical')
    for nested in @model.getNested()
      nested.removeTravelStyle()



  '''
    From the GUI the user can change the title of this version. Sends the new title
    back to the model to change this in the data. Also updates the display.
  '''
  setTitle: (title, version) ->
    @model.setTitle(title, version)
    @headerElement.update()


  '''
    Sets the text editor marker associated with the header div. Needed for
    initialization and for re-adding variant boxes.
  '''
  setHeaderMarker: (hm) ->
    @model.setHeaderMarker(hm)


  '''
    Returns the text editor marker associated with the header div.
  '''
  getHeaderMarker: ->
    @model.getHeaderMarker()


  '''
    A Decoration is an Atom object that attatches a particular text editor
    display to a given marker. We store the decoration here that decorates the
    text in the variant box range with the variant header div.
  '''
  setHeaderMarkerDecoration: (decoration) ->
    @headerMarkDecoration = decoration


  '''
    Remove the decoration from the code. Used for removing and adding variant boxes.
    Removes the div of the header.
  '''
  destroyHeaderMarkerDecoration: ->
    @headerMarkDecoration.destroy()


  '''
    A Decoration is an Atom object that attatches a particular text editor
    display to a given marker. We store the decoration here that decorates the
    text in the variant box range with the variant footer div.
  '''
  setFooterMarkerDecoration: (decoration) ->
    @footerMarkDecoration = decoration


  '''
    Remove the decoration from the code. Used for removing and adding variant boxes.
    Removes the div of the footer.
  '''
  destroyFooterMarkerDecoration: ->
    @footerMarkDecoration.destroy()


  '''
    The user has placed their cursor in the range of this variant box, so update the
    display to highlight the UI as active.
  '''
  focus: () ->
    @focused = true
    @hover()


  '''
    The user has removed their cursor from the range of this variant box, so update the
    display to not-highlight the UI.
  '''
  unFocus: ->
    @focused = false
    for n in @model.getNested()
      n.unFocus()
    @unHover()


  '''
    Returns if the UI state is focused, meaning the cursor is in the range of this box.
  '''
  isFocused: ->
    @focused


  '''
    Set UI to highlighted active.
  '''
  hover: ->
    @headerElement.focus()
    $(@footerBar).addClass('active')



  '''
    Set UI to not-highlighted inactive.
  '''
  unHover: ->
    if @focused
      return
    @headerElement.blur()
    $(@footerBar).removeClass('active')



  '''
    When the user's code is run, associate the output with a commit of this variant box.
  '''
  registerOutput: (data) ->
    @model.registerOutput(data)


  updateWidth: ->
    @commitLine.redraw()


  '''
    Attatches a new nested variant to this parent variant box.
  '''
  addedNestedVariant: (v, version) ->
    @model.addNested(v)
    v.getModel().setNestedParent([version, @])


  '''
    Adds a new version to this variant box.
  '''
  newBranch: ->
    if @diffPanels.isShowing()
      @switchToVersion(@diffPanels.getV1())
    v = @model.newBranch()
    @headerElement.update()


  '''
    Toggles the code as commented or uncommented.
  '''
  toggleActive: (v) ->
    @model.toggleActive(v)


  '''
    Switch between versions.
  '''
  switchToVersion: (v, same) ->
    @diffPanels.close()
    same = @model.isCurrent(v) #and same

    np = @model.getNestedParent()
    # switch the highest level first
    if np?
      [p_version, p_variant] = np
      #console.log "look up parent "
      #console.log p_variant
      p_variant.switchToVersion(p_version, same)

    if same == true
      return

    @model.switchToVersion(v)
    @headerElement.switchToVersion(v)
    @branchMap.redraw()
    @commitLine.redraw()


  switchHeaderOnly: (v) ->
    @diffPanels.close()
    @headerElement.switchToVersion(v)
    @branchMap.redraw()
    @commitLine.redraw()



  '''
    Selecting multiple versions.
  '''
  highlightMultipleVersions: (v) ->
    if v.getID() != @model.getCurrentVersion().getID()
      @diffPanels.diffVersions(v, @model.getCurrentVersion())
      @model.deselectCurrentVersion()
      @headerElement.update()


  getDiffPanels: ->
    @diffPanels


  '''
    On initialization, once all saved data in loaded into the model, finally build the
    UI for this variant box.
  '''
  buildVariantDiv: (width) ->
    $(@footerBar).width(width)
    #console.log "sourceEditor ", @sourceEditor.id
    @headerElement.setEditorID(@sourceEditor.id)
    @headerElement.setView(@)
    @headerElement.setModel(@model)
    @headerElement.buildHeader(width)
    # commit line
    @commitLine = new CommitLine(@, @model, width)
    @headerElement.appendDiv(@commitLine.getElement())
    # branch map
    @branchMap = new BranchMap(@, @model, width)
    @headerElement.appendDiv(@branchMap.getElement())
    # variants panel
    @diffPanels = new DiffPanels(@, @model, width)
    @headerElement.appendDiv(@diffPanels.getElement())

    @headerElement.buildButtons()
    #$(@footerBar).css('margin-left', $(@nestLabelContainer).width() + 20)

    if @model.getNested().length > 0
      for n in @model.getNested()
        if n.rootVersion? == false
          n.buildVariantDiv(width)
