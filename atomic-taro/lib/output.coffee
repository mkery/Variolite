crypto = require 'crypto'

module.exports =
class Output

  constructor: (data) ->
    @data = data
    @commit = null
    @element = null
    @key = crypto.randomBytes(20).toString('hex')

  getData: ->
    @data

  setCommit: (comm) ->
    @commit = comm

  getCommit: ->
    @commit

  getID: ->
    @key
