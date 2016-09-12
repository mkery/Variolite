{Point, Range, TextBuffer, DisplayMarker, TextEditor} = require 'atom'
{spawn} = require 'child_process'

module.exports =
class ProgramProcessor

  constructor: (@file, @atomicTaroView) ->
    # nothin

  run: ->
    console.log "RUN! "+@file
    py = spawn 'python', [@file]
    # receive all output and process
    py.stdout.on 'data', (data) =>
      console.log data.toString().trim()
      @atomicTaroView.registerOutput(data)
    # receive error messages and process
    py.stderr.on 'data', (data) =>
      console.log data.toString().trim()
