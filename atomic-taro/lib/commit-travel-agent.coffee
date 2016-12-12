{Point, Range, TextBuffer} = require 'atom'


module.exports =
class CommitTravelAgent

  constructor: (@masterVariant, @atomicTaroView) ->
    @mainMenuHeader = @masterVariant.getHeaderElement()


  travelToCommit: (commit) ->
    # check if we are in the current state or in the past
    # update the main menu to show the new commit
    # make sure the editor is not editable
    # travel text of master variant and set all nested variants back
    # style all variants so it's clear we're in the past
    # update all commit lines to show which commit we're on
    # update all branch maps to show which branch each variant is on
    # show a lock icon that makes it clear that you cannot editor
    # have the option to show this past whatever into an editable branch
    # compare/diff
    @mainMenuHeader.showAlertPane()

  localTravel: (commit) ->
    # if travel only in a local variant, don't change the whole filePath
    # but make the output from that commit available and
    # also somehow give the user the ability to go back to the entire
    # file that created (those)that output at this commit
