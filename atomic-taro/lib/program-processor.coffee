{Point, Range, TextBuffer, DisplayMarker, TextEditor} = require 'atom'
{spawn} = require 'child_process'

module.exports =
class ProgramProcessor

  constructor: (@baseFolder, @file, @atomicTaroView) ->
    # nothin

  run: (command) ->
    console.log "RUN! "+@file
    if command?
      # do program
      #setFolder = spawn 'pwd'
      args = command.split(" ")
      py = spawn args[0], args.slice(1), {cwd: @baseFolder}
      console.log "Attempting ", args[0], " ", args.slice(1), " ", @baseFolder
    else
      py = spawn 'python', [@file]
    # receive all output and process
    py.stdout.on 'data', (data) =>
      console.log data.toString().trim()
      @atomicTaroView.registerOutput(data)
    # receive error messages and process
    py.stderr.on 'data', (data) =>
      @atomicTaroView.registerOutput(data)
