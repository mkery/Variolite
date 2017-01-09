{Point, Range, TextBuffer} = require 'atom'
{CompositeDisposable} = require 'atom'
JsDiff = require 'diff'


module.exports =
class DiffPanels

  constructor: (@variantView, @variantModel, width) ->
    @addDiffPanels(width) # initialize commit line
    @highlightMarkers = []
    @diffVers = []


  isShowing: ->
    $(@diffPanelElem).is(":visible")


  isActive: ->
    @currentBuffer != null


  getV1: ->
    @diffVers[0]


  close: ->
    if $(@diffPanelElem).is(":visible")
        for v in @diffVers
          v.setMultiSelected(false)

        $(@diffPanelElem).hide()

        for marker in @highlightMarkers
          marker.destroy()
        @rightEditor.getBuffer().setText("")
        @leftEditor.getBuffer().setText("")


  getVariantView: ->
    @variantView


  getModel: ->
    @variantModel


  getElement: ->
    @diffPanelElem


  addClass: ->
    $(@diffPanelElem).addClass('historical')


  removeClass: ->
    $(@diffPanelElem).removeClass('historical')


  updateWidth: (width) ->
    $(@diffPanelElem).width(width)
    borderWidth = $(@leftPanel).outerWidth() - $(@leftPanel).innerWidth()
    $(@leftPanel).width(width/2 - borderWidth)
    $(@rightPanel).width(width/2 - borderWidth)



  addDiffPanels: (width) ->
    @diffPanelElem = document.createElement('table')
    @diffPanelElem.classList.add('atomic-taro_diff-panel')
    $(@diffPanelElem).width(width)

    row = document.createElement('tr')

    @leftPanel = document.createElement('td')
    @leftPanel.classList.add('atomic-taro_diff-side-panel')
    @leftLabel = document.createElement('th')
    @leftLabel.classList.add('atomic-taro_diff-label')
    $(@leftLabel).html("Left")
    @leftPanel.appendChild(@leftLabel)

    sourceCode = ""
    @leftEditor = atom.workspace.buildTextEditor(buffer: new TextBuffer({text: sourceCode}), grammar: atom.grammars.selectGrammar("file.py"))
    atom.textEditors.add(@leftEditor)
    @leftPanel.appendChild(@leftEditor.getElement())

    @rightPanel = document.createElement('td')
    @rightPanel.classList.add('atomic-taro_diff-side-panel')
    @rightLabel = document.createElement('th')
    @rightLabel.classList.add('atomic-taro_diff-label')
    $(@rightLabel).html("Right")
    @rightPanel.appendChild(@rightLabel)

    sourceCode = ""
    @rightEditor = atom.workspace.buildTextEditor(buffer: new TextBuffer({text: sourceCode}), grammar: atom.grammars.selectGrammar("file.py"))
    atom.textEditors.add(@rightEditor)
    @rightPanel.appendChild(@rightEditor.getElement())

    row.appendChild(@leftPanel)
    row.appendChild(@rightPanel)
    @diffPanelElem.appendChild(row)
    $(@diffPanelElem).hide()



  diffVersions: (v1, v2) ->
    @diffVers.push v1
    @diffVers.push v2
    v1.setMultiSelected(true)
    v2.setMultiSelected(true)
    $(@diffPanelElem).show()
    #console.log "diffing "
    #console.log v1
    #console.log v2
    $(@rightLabel).html(v1.getTitle())
    $(@leftLabel).html(v2.getTitle())

    v2.close()

    @setText(v1, @rightEditor, @rightEditor.getBuffer())
    @setText(v2, @leftEditor, @leftEditor.getBuffer())
    textA = @rightEditor.getBuffer().getText()
    textB = @leftEditor.getBuffer().getText()
    @getModel().hideInsides()
    @getModel().clearTextInRange()
    @decorateDiffLines(textA, textB)


  setText: (v, editor, buffer) ->
    textList = v.getText()
    #console.log v.getCurrentState()
    for item in textList
      if not item.branchID?
        buffer.append(item.text)
      else
        range = buffer.append(item.text[0].text)
        # marker = buffer.markRange(range)
        # headerElement = document.createElement("div")
        # headerElement.classList.add('atomic-taro_diff-header-box')
        # $(headerElement).html("nested")
        # hRange = [range.start, new Point(range.end.row - 1, range.end.column)]
        # hm = buffer.markRange(hRange, reversed: true)
        # hdec = editor.decorateMarker(hm, {type: 'block', position: 'before', item: headerElement})
        # @highlightMarkers.push hm


  decorateDiffLines: (textA, textB) ->
    diff = JsDiff.diffLines(textA, textB)
    range = @getModel().getVariantRange()
    startR = new Point(0,0)
    startL = new Point(0,0)

    #console.log diff

    for line in diff
      text = line.value
      lines = text.split("\n")
      #console.log "Lines"
      #console.log lines
      rows = lines.length - 1
      cols = lines[lines.length - 1].length
      #console.log text + "has r " +rows + " c " + cols

      if line.removed
        # then text is in both versions
        #console.log "marking remove"
        end = new Point(startR.row + rows, startR.column + cols)
        #console.log "start: " + startR + ", end: " + end
        mark = @rightEditor.markBufferRange([startR, end])
        dec = @rightEditor.decorateMarker(mark, type: 'highlight', class: 'highlight-red')
        @highlightMarkers.push mark
        startR = new Point(end.row, end.col)

      else if line.added
        # then text is in both versions
        #console.log "marking add"
        end = new Point(startL.row + rows, startL.column + cols)
        #console.log "start: " + startL + ", end: " + end
        mark = @leftEditor.markBufferRange([startL, end])
        dec = @leftEditor.decorateMarker(mark, type: 'highlight', class: 'highlight-green')
        @highlightMarkers.push mark
        startL = new Point(end.row, end.col)

      else
        endL = new Point(startL.row + rows, startL.column + cols)
        endR = new Point(startR.row + rows, startR.column + cols)
        startL = new Point(endL.row, endL.col)
        startR = new Point(endR.row, endR.col)
