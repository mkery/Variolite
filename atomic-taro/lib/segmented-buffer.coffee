{TextBuffer} = require 'atom'
'''
What we want is a buffer that can be split into multiple child buffers,
representing different segments of the exploratory program. Each child buffer
only has knowlege of itself, but also must contain a 'shared code' buffer
for when there are functions ect shared between buffers

Clues, if we
TextBuffer.setTextViaDiff (text)
setTextInRange: (range, newText, options)
'''
module.exports =
class CodeSegmenter extends TextBuffer
