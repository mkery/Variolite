{TextEditor} = require 'atom'
{Point, Range} = require 'atom'

module.exports =
class LinkGutter

  constructor: (@editor) ->
    @decorations = []
    @gutter = @editor.addGutter(name: 'taro-link-gutter', priority: 3)

  decorateGutter: (marker) ->
    @decorations.push @gutter.decorateMarker(marker, type: 'gutter', class: 'taro-connect')
    console.log "DECORATED!"
    console.log @decorations
