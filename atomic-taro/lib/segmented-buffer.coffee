{TextBuffer} = require 'atom'

module.exports =
class CodeSegmenter extends TextBuffer
  getText: ->
    console.log("get text called")
    "lololo"
    '''if @cachedText?
      @cachedText
    else
    text = ''
    for row in [0..2]
      text += (@lineForRow(row) + @lineEndingForRow(row))
    @cachedText = text'''

  getTextInRange: (range) ->
    "lololo"
    '''text = ''
    for row in [0..2]
      text += (@lineForRow(row) + @lineEndingForRow(row))
    @cachedText = text'''
