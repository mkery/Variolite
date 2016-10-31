{Point, Range, TextBuffer} = require 'atom'
{CompositeDisposable} = require 'atom'


module.exports =
class BranchMap

  constructor: (@variantView, @variantModel, width) ->
    @addBranchMap(width) # initialize commit line
    @subscriptions = new CompositeDisposable


  getVariantView: ->
    @variantView

  getModel: ->
    @variantModel

  addBranchMap: (width) ->
    @branchMapElem = document.createElement('div')
    @branchMapElem.classList.add('atomic-taro_branch-map')
    $(@branchMapElem).hide()



  getElement: ->
    @branchMapElem


  addClass: ->
    $(@branchMapElem).addClass('historical')

  removeClass: ->
    $(@branchMapElem).removeClass('historical')


  '''
    Show the branch map to view and travel between branches.
  '''
  toggleBranchMap: ->
    if $(@branchMapElem).is(":visible")
      $(@branchMapElem).hide()
      @subscriptions.dispose()
    else
      $(@branchMapElem).width($(@branchMapElem).parent().width())
      $(@branchMapElem).html("")
      $(@branchMapElem).show()
      squareWidth = 16
      height = @maxSquaresInView(@getModel().getRootVersion(), 4)
      $(@branchMapElem).height(height*(squareWidth + 20))
      @placeSquares(null, 0, 0, squareWidth)


  maxSquaresInView: (root, absoluteMax) ->
    numB = root.getBranches().length
    if numB >= absoluteMax
      return numB
    else
      grandchildren = 0
      for branch in root.getBranches()
        grandchildren += @maxSquaresInView(branch, absoluteMax)
        if grandchildren >= absoluteMax
          return absoluteMax
      return Math.max(grandchildren, numB, 1)



  placeSquares: (root, x, y, squareWidth) ->
    if not root? # then place the first root square
      root = @getModel().getRootVersion()
      mapHeight = $(@branchMapElem).height()
      mapWidth = $(@branchMapElem).width()
      x = 20
      y = (mapHeight*.50) - squareWidth/4
      square = document.createElement('div')
      square.classList.add('atomic-taro_branch-map-square')
      @subscriptions.add atom.tooltips.add(square, {title: root.getTitle(), placement: "bottom"})
      if root.getActive()
        square.classList.add('active')
      if root.isCurrent()
        square.classList.add('current')
      $(square).css('left', x+"px")
      $(square).css('top', y+"px")
      @branchMapElem.appendChild(square)

    branchs = root.getBranches()
    numB = branchs.length
    yb = y + (numB/2 * (-10 - squareWidth/2))
    if numB == 1
      yb = y
    # if yb < yMin
    #   yMin = yb
    # if (-1 * yb) > yMax
    #   yMax = (-1 * yb)
    xb = x + 100
    for branch in branchs
      squareB = document.createElement('div')
      squareB.classList.add('atomic-taro_branch-map-square')
      @subscriptions.add atom.tooltips.add(squareB, {title: branch.getTitle(), placement: "bottom"})
      if branch.getActive()
        squareB.classList.add('active')
      if branch.isCurrent()
        squareB.classList.add('current')
      $(squareB).css('left', xb+"px")
      $(squareB).css('top', yb+"px")
      @branchMapElem.appendChild(squareB)
      line = @createLine(x + squareWidth, y + squareWidth/2, xb, yb + squareWidth/2)
      @branchMapElem.appendChild(line)
      @placeSquares(branch, xb, yb, squareWidth)
      yb = yb + 10+squareWidth





  createLine: (x1, y1, x2, y2) ->
    if (x2 < x1)
      temp = x1
      x1 = x2
      x2 = temp
      temp = y1
      y1 = y2
      y2 = temp

    line = document.createElement("div")
    line.classList.add('atomic-taro_branch-map-line')
    length = Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))
    line.style.width = length + "px"


    angle = Math.atan((y2-y1)/(x2-x1))
    line.style.top = y1 + 0.5*length*Math.sin(angle) + "px"
    line.style.left = x1 - 0.5*length*(1 - Math.cos(angle)) + "px"
    line.style.transform = line.style.MozTransform = line.style.WebkitTransform = line.style.msTransform = line.style.OTransform= "rotate(" + angle + "rad)"

    return line
