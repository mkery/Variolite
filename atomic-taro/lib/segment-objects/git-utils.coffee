{Point, Range, TextBuffer} = require 'atom'
JsDiff = require 'diff'


module.exports =
class GitUtils

  getLatestCommit: (varID, verID) ->
    console.log "latest commit?"
