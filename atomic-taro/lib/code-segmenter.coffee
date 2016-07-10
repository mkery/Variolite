

module.exports =
class CodeSegmenter
  segments: []
  header: null

  constructor: (sourceText) ->
    console.log "recieved source text: "+sourceText
    chunks = sourceText.split "#ʕ•ᴥ•ʔ"
    @header = chunks[0]
    for i in [1...chunks.length-1] by 2
      @segments.push {title: chunks[i], code: chunks[i+1]}
    console.log @segments

  getSegments: ->
    return @segments

  getHeader: ->
    return @header
