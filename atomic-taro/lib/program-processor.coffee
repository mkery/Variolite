{Point, Range, TextBuffer, DisplayMarker, TextEditor} = require 'atom'
{spawn} = require 'child_process'

module.exports =
class ProgramProcessor

  constructor: (@baseFolder, @file, @fileName, @atomicTaroView) ->
    @commandHistory = null


  getLast: ->
    @commandHistory


  run: (command) ->
    console.log "RUN! "+@file
    if command?
      # do program
      #setFolder = spawn 'pwd'
      @commandHistory = command

      firstSpace = command.indexOf(" ")
      console.log "FIRST SPACE "+firstSpace
      secondSpace = command.indexOf(" ", firstSpace + 1)
      console.log "SECOND SPACE "+secondSpace
      as = command.substring(secondSpace + 1)
      pyFile = command.substring(firstSpace + 1, secondSpace)
      console.log "args "+as

      py = spawn 'python', [pyFile, as], {cwd: @baseFolder}
      console.log "Attempting ", pyFile, " ", as, " ", @baseFolder
    else
      command = "python "+@fileName
      @commandHistory = command
      py = spawn 'python', [@file]
    # receive all output and process
    py.stdout.on 'data', (data) =>
      console.log data.toString().trim()
      @atomicTaroView.registerOutput(command, data)
    # receive error messages and process
    py.stderr.on 'data', (data) =>
      @atomicTaroView.registerErr(command, data)
