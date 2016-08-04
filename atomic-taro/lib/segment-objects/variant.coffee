{Point, Range, TextBuffer} = require 'atom'

'''
Represents a single variant of exploratory code.
'''
module.exports =
class Variant


  constructor: (@sourceEditor, @marker, title, @elder = null, @children = []) ->
    #the header div has it's own marker that must follow around the top of the main marker
    @headerMarker = null

    @copied = false

    text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    date = @dateNow()
    @currentVersion = {title: title, text: text, date: date}
    @versions = []
    @versions.push @currentVersion



  dateNow: ->
    date = new Date()
    hour = date.getHours()
    sign = "am"
    if hour > 12
      sign = "pm"
      hour = hour%12

    minute = date.getMinutes();
    if minute < 10
      minute = "0"+minute
    $.datepicker.formatDate('mm/dd/yy', date)+" "+hour+":"+minute+sign



  serialize: ->
    currentVersion: @currentVersion
    versions: @versions

  deserialize: (state) ->
    #state_currentVersion = state.currentVersion
    #@currentVersion.date = state_currentVersion.date
    #TODO resolve if doesn't match text
    @versions = []
    state_versions = state.versions
    for v in state_versions
      stored_ver = {title: v.title, text: v.text, date: v.date}
      @versions.push stored_ver
      if v.title == @currentVersion.title
        @currentVersion = stored_ver

  getMarker: ->
    @marker


  setHeaderMarker: (hm) ->
    @headerMarker = hm
    @marker.onDidChange (ev) =>
      if ev.newTailBufferPosition != ev.oldTailBufferPosition
        console.log "backspace!!"
        @headerMarker.setHeadBufferPosition(ev.newTailBufferPosition)


  getVersions: ->
    @versions



  getCurrentVersion: ->
    @currentVersion



  newVersion: ->
    text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    newVersion = {title: "V"+@versions.length, text: text, date: @dateNow()}
    @versions.push newVersion
    @currentVersion = newVersion

  toggleActive: (v) ->
    textSelection =  @marker.getBufferRange()
    selections = @sourceEditor.getSelections()
    selections[0].setBufferRange(textSelection)
    console.log selections
    selections[0].toggleLineComments()
    #console.log textSelection
    #ideas - somehow create a selection and use the API to toggle comments. Problem with
    #this is I don't know how to create a selection and looking at the docs, it doesn't appear
    # you can just call a constructor on it
    #idea 2 - use reg expression to append comments to the beginning of lines
    #problem is how would we know to un-toggle those comments and not already existing
    #comments?
  switchToVersion: (v) ->
    text = v.text
    @currentVersion.text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    @sourceEditor.setTextInBufferRange(@marker.getBufferRange(), v.text, undo: false)
    @currentVersion = v



  getTitle: ->
    @currentVersion.title



  setTitle: (title) ->
    @currentVersion.title = title



  getDate: ->
    @currentVersion.date


  getText: ->
    @currentVersion.text



  setText: (text) ->
    @currentVersion.text = text



  getCopied: ->
    @copied



  setCopied: (bool) ->
    @copied = bool



  collapse: ->
    console.log "collaping variant"
    @sourceEditor.setSelectedBufferRange(@marker.getBufferRange())
    @sourceEditor.foldSelectedLines()
