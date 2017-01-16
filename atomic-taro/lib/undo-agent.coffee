{TextBuffer} = require 'atom'
{Point, Range} = require 'atom'
Variant = require './segment-objects/variant-model'
VariantView = require './segment-objects/variant-view'
AtomicTaroToolPane = require './right-panel/atomic-taro-tool-pane'



module.exports =
class UndoAgent

  constructor: (maxUndo) ->
    @undoStack = []
    @maxUndoEntries = maxUndo
    @buffer = null

  setBuffer: (b) ->
    @buffer = b

  pushChange: (params) ->
    #checkpointId = @buffer.createCheckpoint()
    #@undoStack.push {params: params, bufferCheck: checkpointId}
    #@enforceUndoStackSizeLimit()


  undoNow: ->
    # change = @undoStack[@undoStack.length - 1] # get top of stack
    # if change?
    #   bufferCheck = change.bufferCheck
    #   sinceThen = @buffer.getChangesSinceCheckpoint(bufferCheck)
    #   console.log sinceThen.length+" operations since then"
    #   if sinceThen.length == 0
    #     console.log "undo taro please"
    #     return true
    # false


  revertChange: () ->
    # change = @undoStack.pop()
    # if change?
    #   data = change.params.data
    #   callback = change.params.callback
    #   console.log "got change revert"
    #   console.log data
    #   console.log callback
    #   callback(data)


  enforceUndoStackSizeLimit: ->
    # if @undoStack.length > @maxUndoEntries
    #   @undoStack.splice(0, @undoStack.length - @maxUndoEntries)
