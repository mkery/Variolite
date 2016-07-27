{Point, Range, TextBuffer} = require 'atom'
Segment = require './segment'

'''
Represents model for a single shared function block.
'''
module.exports =
class SharedFunctionSegment extends Segment
