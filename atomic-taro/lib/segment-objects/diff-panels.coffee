{Point, Range, TextBuffer} = require 'atom'
{CompositeDisposable} = require 'atom'


module.exports =
class DiffPanels

  constructor: (@variantView, @variantModel) ->
    @addDiffPanels() # initialize commit line
    @subscriptions = new CompositeDisposable()


  isShowing: ->
    $(@diffPanelElem).is(":visible")


  close: ->
    $(@diffPanelElem).hide()


  getVariantView: ->
    @variantView

  getModel: ->
    @variantModel

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
    console.log "diffing "
    console.log v1
    console.log v2
    $(@rightLabel).html(v1.getTitle())
    $(@leftLabel).html(v2.getTitle())
    @rightEditor.getBuffer().setText(v1.getText())
    @leftEditor.getBuffer().setText(v2.getText())
    v2.close()
    @getModel().hideInsides()
    @getModel().clearTextInRange()



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
