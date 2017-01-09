crypto = require 'crypto'

module.exports =
class Output

  constructor: (command, data) ->
    @command = command
    @data = data
    @commit = null
    @element = null
    @key = crypto.randomBytes(20).toString('hex')

  getCommand: ->
    @command

  getData: ->
    @data

  setCommit: (comm) ->
    @commit = comm

  getCommit: ->
    @commit

  getID: ->
    @key
