{Point, Range, TextBuffer} = require 'atom'
{CompositeDisposable} = require 'atom'
JsDiff = require 'diff'


module.exports =
class DiffPanels

  constructor: (@variantView, @variantModel) ->
    @addDiffPanels() # initialize commit line
    @highlightMarkers = []


  isShowing: ->
    $(@diffPanelElem).is(":visible")


  close: ->
    $(@diffPanelElem).hide()


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


  addDiffPanels: () ->
    @diffPanelElem = document.createElement('table')
    @diffPanelElem.classList.add('atomic-taro_diff-panel')

    row = document.createElement('tr')

    @leftPanel = document.createElement('td')
    @leftPanel.classList.add('atomic-taro_diff-side-panel')
    @leftLabel = document.createElement('th')
    @leftLabel.classList.add('atomic-taro_diff-label')
    $(@leftLabel).html("Left")
    @leftPanel.appendChild(@leftLabel)

    sourceCode = "I am the text of the left side!"
    @leftEditor = atom.workspace.buildTextEditor(buffer: new TextBuffer({text: sourceCode}), grammar: atom.grammars.selectGrammar("file.py"))
    atom.textEditors.add(@leftEditor)
    @leftPanel.appendChild(@leftEditor.getElement())

    @rightPanel = document.createElement('td')
    @rightPanel.classList.add('atomic-taro_diff-side-panel')
    @rightLabel = document.createElement('th')
    @rightLabel.classList.add('atomic-taro_diff-label')
    $(@rightLabel).html("Right")
    @rightPanel.appendChild(@rightLabel)

    sourceCode = "I am the text of the right side!"
    @rightEditor = atom.workspace.buildTextEditor(buffer: new TextBuffer({text: sourceCode}), grammar: atom.grammars.selectGrammar("file.py"))
    atom.textEditors.add(@rightEditor)
    @rightPanel.appendChild(@rightEditor.getElement())

    row.appendChild(@leftPanel)
    row.appendChild(@rightPanel)
    @diffPanelElem.appendChild(row)
    $(@diffPanelElem).hide()



  diffVersions: (v1, v2) ->
    $(@diffPanelElem).show()
    #console.log "diffing "
    #console.log v1
    #console.log v2
    $(@rightLabel).html(v1.getTitle())
    $(@leftLabel).html(v2.getTitle())

    v2.close()
    textA = v1.getText()
    console.log "v1 text"
    console.log textA
    textB = v2.getText()
    console.log "v2 text"
    console.log textB
    @rightEditor.getBuffer().setText(v1.getText())
    @leftEditor.getBuffer().setText(v2.getText())
    @getModel().hideInsides()
    @getModel().clearTextInRange()
    @decorateDiffLines(v1, v2)



  decorateDiffLines: (v1, v2) ->
    textA = v1.getText()
    #console.log "v1 text"
    #console.log textA
    textB = v2.getText()
    #console.log "v2 text"
    #console.log textB

    diff = JsDiff.diffLines(textA, textB)
    range = @getModel().getVariantRange()
    startR = new Point(0,0)
    startL = new Point(0,0)

    console.log diff

    for line in diff
      text = line.value
      lines = text.split("\n")
      console.log "Lines"
      console.log lines
      rows = lines.length - 1
      cols = lines[lines.length - 1].length
      # console.log text + "has r " +rows + " c " + cols

      if line.removed
        # then text is in both versions
        console.log "marking remove"
        end = new Point(startR.row + rows, startR.column + cols)
        console.log "start: " + startR + ", end: " + end
        mark = @rightEditor.markBufferRange([startR, end])
        dec = @rightEditor.decorateMarker(mark, type: 'highlight', class: 'highlight-red')
        @highlightMarkers.push mark
        startR = new Point(end.row + 1, end.col)

      else if line.added
        # then text is in both versions
        console.log "marking add"
        end = new Point(startL.row + rows, startL.column + cols)
        console.log "start: " + startL + ", end: " + end
        mark = @leftEditor.markBufferRange([startL, end])
        dec = @leftEditor.decorateMarker(mark, type: 'highlight', class: 'highlight-green')
        @highlightMarkers.push mark
        startL = new Point(end.row + 1, end.col)

      else
        endL = new Point(startL.row + rows, startL.column + cols)
        endR = new Point(startR.row + rows, startR.column + cols)
        startL = new Point(endL.row + 1, endL.col + 1)
        startR = new Point(endR.row + 1, endR.col + 1)
