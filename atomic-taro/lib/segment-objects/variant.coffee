{Point, Range, TextBuffer} = require 'atom'

'''
Represents a single variant of exploratory code.
'''
module.exports =
class Variant


  constructor: (@sourceEditor, @marker, title, @elder = null, @children = []) ->
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



  getVersions: ->
    @versions



  getCurrentVersion: ->
    @currentVersion



  newVersion: ->
    text = @sourceEditor.getTextInBufferRange(@marker.getBufferRange())
    newVersion = {title: "V"+@versions.length, text: text, date: @dateNow()}
    @versions.push newVersion
    @currentVersion = newVersion



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
