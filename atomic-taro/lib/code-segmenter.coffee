SegmentedBuffer = require './segmented-buffer'

module.exports =
class CodeSegmenter
  segments: []
  header: null

  constructor: (sourceEditor) ->
    @segments = [] # for some reason this prevents duplicate blocks

    sourceText = sourceEditor.getText()
    sourceBuffer = sourceEditor.getBuffer()

    chunks = sourceText.split "#ʕ•ᴥ•ʔ"
    @header = chunks[0]
    for i in [1...chunks.length-1] by 2
      model_editor = atom.workspace.buildTextEditor(buffer: new SegmentedBuffer(text: chunks[i+1]), grammar: atom.grammars.selectGrammar("file.py"))
      text_buffer = model_editor.getBuffer()
      @segments.push {title: chunks[i], code: model_editor}
      text_buffer.onDidChange (e) =>
        console.log "modified! --"+ e.oldText+"   ++"+ e.newText+" range: "+e.oldRange+" "+e.newRange
        if(e.newText)
          console.log "attempting to link edit"
          sourceBuffer.insert(e.oldRange.start, e.newText)
    console.log @segments

  getSegments: ->
    return @segments

  getHeader: ->
    return @header

  # Tear down any state and detach
  destroy: ->
    @segments = []
    @header = null
