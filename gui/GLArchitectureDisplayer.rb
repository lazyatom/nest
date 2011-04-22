require 'opengl'
require 'glut'
require 'Nest3'

class GLArchitectureDisplayer
  #
  # Architecture Drawing Information
  #

  @@lightPosition = [50.0, 50.0, 50.0, 1.0]
  @@lightAmbient  = [ 0.1,  0.1, 0.1, 1.0]
  @@lightDiffuse  = [ 0.9,  0.9, 0.9, 1.0]

  DRAW_FILLED = 0
  DRAW_VALUES = 1
  DRAW_IDS = 2
  DRAW_ORDER = 3
  DRAW_ORDER_VALUE = 4

  #
  # Instance methods
  #

  attr_accessor :cursor, :drawType, :drawEmpty, :drawNil, :drawCursor, :xRot, :yRot, :drawAgents, :uniformBricks
  attr_accessor :readOnly, :gui, :numBricksToDisplay, :currentRuleID
  attr_reader :architecture, :highlightRules

  attr_reader :viewX, :viewY, :viewZ, :rotX, :rotY, :rotZ

  def init(arch=nil)
    setArchitecture(arch)

    @clearColour = @@white

    @lastOrderNumber = 0
    @drawType = DRAW_FILLED
    @drawEmpty = false
    @drawNil = false
    @drawCursor = true
    @drawAgents = true
    @readOnly = false
    @uniformBricks = false
    @numBricksToDisplay = nil

    @highlightRules = false

    initGLStuff()

    setView(0,0,-20,-30,0,0)
  end

  def initGLStuff()
    GL.Enable(GL::DEPTH_TEST)

    GL.ClearColor(@clearColour[0], @clearColour[1],
                    @clearColour[2], @clearColour[3])

    GL.Clear(GL::COLOR_BUFFER_BIT|GL::DEPTH_BUFFER_BIT)

    GL.ShadeModel(GL::SMOOTH)

    GL.Enable(GL::LINE_SMOOTH)
    GL.Hint(GL::LINE_SMOOTH_HINT, GL::NICEST)
    GL.Enable(GL::POINT_SMOOTH)
    GL.Hint(GL::POINT_SMOOTH_HINT, GL::NICEST)

    GL.Enable(GL::BLEND)
    GL.BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA)

    GL.Light(GL::LIGHT0, GL::POSITION, @@lightPosition)
    GL.Light(GL::LIGHT0, GL::AMBIENT, @@lightAmbient)
    GL.Light(GL::LIGHT0, GL::DIFFUSE, @@lightDiffuse)
    GL.Enable(GL::LIGHT0)
    GL.Enable(GL::LIGHTING)

    load("gui/GLHexagons.rb")

    createOutlineList()
    createCellList()
    createArrowList()
  end

  def setDrawStyle(style)
    @drawType = style
  end

  def findLastOrderNumber()
    @lastOrderNumber = 0
    @architecture.eachBrick do |b|
        @lastOrderNumber = b.order() if b.order() > @lastOrderNumber
    end
  end

  def setArchitecture(arch)
    @architecture = arch
    #puts "viewer architecture is now: #{@architecture}"
    findLastOrderNumber() if @architecture != nil
    resetCursor()
    @numBricksToDisplay = 10000 #@architecture.numBricks
    #drawScene()
    #puts "updating limitspinner"
  end

  def setSimulation(s)
    @simulation = s
  end

  @@moveStep = 1
  @@rotateStep = 5

  def rotateView(dir, inc=@@rotateStep)
    case dir
      when "FORWARD"
        @rotZ -= inc
      when "BACKWARD"
        @rotZ += inc
      when "LEFT"
        @rotY += inc
      when "RIGHT"
        @rotY -= inc
      when "UP"
        @rotX += inc
      when "DOWN"
        @rotX -= inc
    end
  end

  def moveView(dir, inc=@@moveStep)
    case dir
      when "FORWARD"
        @viewY -= inc
      when "BACKWARD"
        @viewY += inc
      when "LEFT"
        @viewX += inc
      when "RIGHT"
        @viewX -= inc
      when "UP"
        @viewZ += inc
      when "DOWN"
        @viewZ -= inc
    end
  end

  def setViewPosition(location, rotation)
    @viewX, @viewY, @viewZ = location
    @rotX, @rotY, @rotZ = rotation
  end

  def getViewPosition()
    return [@viewX, @viewY, @viewZ]
  end

  def getViewRotation()
    return [@rotX, @rotY, @rotZ]
  end

  def reshape(width, height)
    height = 1 if height == 0
    aspect = width/height

    GL.Viewport(0, 0, width, height)

    GL.MatrixMode(GL::PROJECTION)
    GL.LoadIdentity()
    GLU.Perspective(45, aspect, 1.0, 1000)

    moveGLView()
  end

  def setView(vx, vy, vz, rx, ry, rz)
    @viewX, @viewY, @viewZ = vx, vy, vz
    @rotX, @rotY, @rotZ = rx, ry, rz
  end

  def moveGLView
    GL.MatrixMode(GL::MODELVIEW)
    GL.LoadIdentity()

    GL.Translate(@viewX, @viewY, @viewZ)
    GL.Rotate(@rotX, 1, 0, 0)
    GL.Rotate(@rotY, 0, 1, 0)
    GL.Rotate(@rotZ, 0, 0, 1)
  end

  def drawScene()
    moveGLView()

    GL.Clear(GL::COLOR_BUFFER_BIT|GL::DEPTH_BUFFER_BIT)
    if @architecture != nil
      drawArchitecture(@architecture.centreCell)
      drawCursor() if @drawCursor && !@highlightRules
      @drawProc.call(self) if @drawProc != nil
      drawSimulationStuff() if @drawAgents
    else
      drawNilArchitecture("Nothing Loaded.")
    end
  end

  def toggleMode()
    @highlightRules = !@highlightRules
  end

  def drawArchitecture(rootCell)
    allCells = @architecture.to_a.sort { |x,y| x.order <=> y.order }
    allCells[0..@numBricksToDisplay].each do |cell|
      #puts cell.coords.to_s
      puts "DRAWARCHITECTURE: CELL == NIL!!" if cell == nil
      #puts "drawing cell #{cell}"
      x = cell.getX()
      y = cell.getY()
      z = cell.getZ()

      drawCell(y, x, z, cell)
    end
  end

  def drawSimulationStuff
    return if @simulation == nil
    @simulation.agents.each do |agent|
      #puts "drawing agent #{agent.id} at #{loc.getX()}, #{loc.getY()}, #{loc.getZ()}"
      if (rand(2) > 0)
        drawBee3(agent)
      else
        drawBee2(agent)
      end
    end
  end

  def drawBee3(agent)
    loc = agent.location
    GL.PushMatrix()

      colour2 = [0.1,0.1,0.1,1]
      colour1 = @@agentMaterial

      GL.Translate(loc.getY()*2,loc.getX()*2,(loc.getZ()*2)-0.5)

      GL.Rotate(rand(180),rand(2),rand(2),rand(2))

      GL.Scale(R-0.01, R-0.01, R-0.01)
      GL.Material(GL::FRONT, GL::AMBIENT, colour1)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour1)
      GLUT.SolidSphere(0.4,8,8)

      GL.Translate(0.05,0,0)
      GL.Material(GL::FRONT, GL::AMBIENT, colour2)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour2)
      GLUT.SolidSphere(0.4,8,8)

      GL.Translate(0.1,0,0)
      GL.Material(GL::FRONT, GL::AMBIENT, colour1)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour1)
      GLUT.SolidSphere(0.4,8,8)

      GL.Translate(0.1,0,0)
      GL.Material(GL::FRONT, GL::AMBIENT, colour2)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour2)
      GLUT.SolidSphere(0.4,8,8)

      # wings
      GL.PushMatrix()
        GL.Translate(0,0,0.3) # move up a little bit
        GL.Material(GL::FRONT, GL::AMBIENT, [0.9,0.9,0.9,0.5])
        GL.Material(GL::FRONT, GL::DIFFUSE, [0.9,0.9,0.9,0.5])
        GL.Rotate(30,1,0,0)
        GL.Begin(GL::TRIANGLE_FAN);
          10.times do |i|
              angle = i*Math::PI*2 / 10
              GL.Vertex(0.4*Math.cos(angle), 0.4*Math.sin(angle));
          end
        GL.End()
        GL.Rotate(-60,1,0,0)
        GL.Begin(GL::TRIANGLE_FAN);
          10.times do |i|
              angle = i*Math::PI*2 / 10
              GL.Vertex(0.4*Math.cos(angle), 0.4*Math.sin(angle));
          end
        GL.End()
      GL.PopMatrix()

      GL.Translate(0.1,0,0)
      GL.Material(GL::FRONT, GL::AMBIENT, colour1)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour1)
      GLUT.SolidSphere(0.4,8,8)

      GL.Translate(0.1,0,0)
      GL.Material(GL::FRONT, GL::AMBIENT, colour2)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour2)
      GLUT.SolidSphere(0.4,8,8)

      GL.Translate(0.1,0,0)
      GL.Material(GL::FRONT, GL::AMBIENT, colour1)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour1)
      GLUT.SolidSphere(0.4,8,8)

      # eyes
      GL.Material(GL::FRONT, GL::AMBIENT, [0.1,0.1,0.1,1])
      GL.Material(GL::FRONT, GL::DIFFUSE, [0.1,0.1,0.1,1])
      GL.Translate(0.25, -0.1, 0.2)
      GLUT.SolidSphere(0.15,8,8)
      GL.Translate(0, 0.2, 0)
      GLUT.SolidSphere(0.15,8,8)

    GL.PopMatrix()
  end

  def drawBee2(agent)
    loc = agent.location
    GL.PushMatrix()

      colour2 = [0.1,0.1,0.1,1]
      colour1 = @@agentMaterial


      GL.Translate(loc.getY()*2,loc.getX()*2,(loc.getZ()*2)-0.5)

      GL.Rotate(rand(180),rand(2),rand(2),rand(2))

      GL.Scale(R-0.01, R-0.01, R-0.01)
      GL.Material(GL::FRONT, GL::AMBIENT, colour1)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour1)
      GLUT.SolidSphere(0.4,8,8)

      GL.Translate(0.05,0,0)
      GL.Material(GL::FRONT, GL::AMBIENT, colour2)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour2)
      GLUT.SolidSphere(0.4,8,8)

      GL.Translate(0.1,0,0)
      GL.Material(GL::FRONT, GL::AMBIENT, colour1)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour1)
      GLUT.SolidSphere(0.4,8,8)

      # wings
      GL.PushMatrix()
        GL.Translate(0,0,0.3) # move up a little bit
        GL.Material(GL::FRONT, GL::AMBIENT, [0.9,0.9,0.9,0.5])
        GL.Material(GL::FRONT, GL::DIFFUSE, [0.9,0.9,0.9,0.5])
        GL.Rotate(30,1,0,0)
        GL.Begin(GL::TRIANGLE_FAN);
          10.times do |i|
              angle = i*Math::PI*2 / 10
              GL.Vertex(0.4*Math.cos(angle), 0.4*Math.sin(angle));
          end
        GL.End()
        GL.Rotate(-60,1,0,0)
        GL.Begin(GL::TRIANGLE_FAN);
          10.times do |i|
              angle = i*Math::PI*2 / 10
              GL.Vertex(0.4*Math.cos(angle), 0.4*Math.sin(angle));
          end
        GL.End()
      GL.PopMatrix()

      GL.Translate(0.1,0,0)
      GL.Material(GL::FRONT, GL::AMBIENT, colour2)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour2)
      GLUT.SolidSphere(0.4,8,8)

      GL.Translate(0.1,0,0)
      GL.Material(GL::FRONT, GL::AMBIENT, colour1)
      GL.Material(GL::FRONT, GL::DIFFUSE, colour1)
      GLUT.SolidSphere(0.4,8,8)

      # eyes
      GL.Material(GL::FRONT, GL::AMBIENT, [0.1,0.1,0.1,1])
      GL.Material(GL::FRONT, GL::DIFFUSE, [0.1,0.1,0.1,1])
      GL.Translate(0.25, -0.1, 0.2)
      GLUT.SolidSphere(0.15,8,8)
      GL.Translate(0, 0.2, 0)
      GLUT.SolidSphere(0.15,8,8)

    GL.PopMatrix()
  end


  #
  # Cursor manipulation methods
  #

  @@cursorMaterial = [0.0, 1.0, 0.0, 0.5]
  @@readonlycursorMaterial = [1.0, 0.0, 1.0, 0.5]

  def moveCursor(dir)
    return if @architecture == nil
    newcell = @cursor.get(dir)
    if newcell != nil
      @cursor = newcell
      @cursor.setValue(CELL_EMPTY) if @cursor.value() == CELL_NIL
    else
      # there is nothing there....
      if !@readOnly
        #p "creating a new cell from #{@cursor.id} in dir #{dir}"
        if @cursor.set(dir, CELL_EMPTY) != nil # we haven't reached the boundary
          #@architecture.setSurroundingCellCoords(@cursor) # just do this one cell
          @cursor = @cursor.get(dir)
        end
      end
    end
  end

  def resetCursor()
    if @architecture != nil
      @cursor = @architecture.centreCell
    end
  end

  def flipCellAtCursor(inc=1)
    if !@readOnly && @architecture != nil
      @cursor.setValue((@cursor.value()+inc)) # to skip CELL_EMPTY
    end
  end

  def nextCellAtCursor(inc=1)
    if !@readOnly && @architecture != nil
      inc = 2 if (@cursor.value == CELL_EMPTY)
      @cursor.setValue((@cursor.value()+inc)) # to skip CELL_EMPTY
      orderNextCellAtCursor()
    end
  end

  def addCellAtCursor()
    if !@readOnly && @architecture != nil
      @cursor.setValue(CELL_RED) if @cursor.isEmpty()
    end
  end

  def deleteCellAtCursor()
    if !@readOnly && @architecture != nil
      @cursor.setValue(CELL_EMPTY) if !@cursor.isEmpty()
    end
  end

  def orderNextCellAtCursor()
    @cursor.setOrder((@lastOrderNumber += 1)) if @architecture != nil
  end

  def flipOrderAtCursor(inc = 1)
    if (@cursor.order() < @architecture.numBricks && inc > 0) ||
      (@cursor.order() > 1 && inc < 0)
      currentOrder = @cursor.order()
      bricks = @architecture.to_brick_a
      i = 0
      while bricks[i].order() != (currentOrder+inc) do
        i+= 1
      end
      @cursor.setOrder(bricks[i].order())
      bricks[i].setOrder(currentOrder)
    end
  end

  def createEmptyVolumeAtCursor()
    @cursor.expandSpaceAround() if @architecture != nil
  end

  #
  #  Utility HexCell/Cursor/Architecture drawing methods
  #

  def drawCell(x,y,z,cell)
    #puts "\tdrawing cell #{cell.id} [#{cell.getX},#{cell.getY},#{cell.getZ}]"
    return if cell == nil

    activeCellLineWidth = @@lineWidth

    if @highlightRules
      #puts "highlighting rules (#{@currentRuleID.to_s})"
      #puts cell.neighbourhoodArray.compact.collect { |c| c.id() }.inspect
      trans = 0.1
      if (cell.neighbourhoodArray.compact.collect{ |c| c.order() }.include?(@currentRuleID) &&
        cell.order() <= @currentRuleID)
        trans = 0.5
        #puts "highlighting neighbour cell #{cell.order().to_s}"
      end
      if cell.order() == @currentRuleID
        trans = 1.0
        activeCellLineWidth *= 4;
        @cursor = cell # move the cursor
        #puts "highlighting rule cell #{cell.order().to_s}"
      end
    else
      trans = 1.0
    end

    if (cell.value() == CELL_NIL)
      return if !@drawNil
      drawCellOutline(x, y, z, transparent(emptyCellLineMaterial(),trans), @@lineWidth/2, true)
    elsif (cell.value() == CELL_EMPTY)
      #puts "not drawing empty cell #{cell.cellId}"
      return if !@drawEmpty
      drawCellOutline(x, y, z, transparent(emptyCellLineMaterial(),trans), @@lineWidth)
    else
      case @drawType
      when DRAW_FILLED
        if (cell.value() != CELL_EMPTY)
            mat = @@materials[cell.value()]
            mat = @@materials[CELL_WHITE] if mat == nil
            mat = @@materials[CELL_RED] if @uniformBricks
            drawFilledCell(x, y, z, transparent(mat,trans))
        end
      when DRAW_VALUES
        mat = @@materials[cell.value()]
        mat = @@materials[CELL_WHITE] if mat == nil
        drawCellInfo(x, y, z, cell.value().to_s, transparent(mat,trans))
      when DRAW_IDS
        mat = @@materials[cell.value()]
        mat = @@materials[CELL_WHITE] if mat == nil
        drawCellInfo(x, y, z, cell.id().to_s, transparent(mat,trans))
      when DRAW_ORDER
        mat = @@materials[cell.value()]
        mat = @@materials[CELL_WHITE] if mat == nil
        drawCellInfo(x, y, z, cell.order().to_s, transparent(mat,trans))
      when DRAW_ORDER_VALUE
        mat = @@materials[cell.value()]
        mat = @@materials[CELL_WHITE] if mat == nil
        drawCellInfo(x, y, z, "#{cell.order()}/#{cell.value()}", mat)
      end
      drawCellOutline(x, y, z, transparent(lineMaterial(),trans), activeCellLineWidth)
    end
  end

  def drawCellInfo(x, y, z, text, mat)
    #puts "writing #{id} at #{x},#{y},#{z}"
    GL.PushMatrix()
      GL.Material(GL::FRONT, GL::AMBIENT, mat)
      GL.Material(GL::FRONT, GL::DIFFUSE, mat)
      GL.Translate(x*2,y*2,z*2)
      GL.RasterPos3d(((text.length/2)*8)*-0.02,0,-0.5)
      #GL.Scale((R*0.02)-0.01, (R*0.02)-0.01, (R*0.02)-0.01)

      drawString(text)
    GL.PopMatrix()
  end

  def drawString(text)
    text.to_s.length.times do |i|
      GLUT.BitmapCharacter(GLUT::BITMAP_8_BY_13, text.to_s[i])
    end
  end

  def createAgentList()
    @agentListID = GL.GenLists(1)
    GL.NewList(@agentListID, GL::COMPILE)

    GL.Begin(GL::QUAD_STRIP)
      GL.Vertex(0,0,0)
      GL.Vertex(1,0,0)
      GL.Vertex()
    GL.End()
    GL.EndList()
  end

  def drawFilledCell(xold, yold, zold, mat, scale=0)
    GL.PushMatrix()
      GL.Translate(xold*2,yold*2,zold*2)
      #GL.Scale(R-0.01+scale, R-0.01+scale, R-0.01+scale)

      GL.Material(GL::FRONT, GL::AMBIENT, mat)
      GL.Material(GL::FRONT, GL::DIFFUSE, mat)

      GL.CallList(@cellListID)
    GL.PopMatrix()
  end

  def drawCellOutline(x, y, z, mat, width, stipple = false)
    GL.PushMatrix()
      GL.Translate(x*2,y*2,z*2)
      #GL.Scale(R-0.01, R-0.01, R-0.01)

      #outlines
      GL.Material(GL::FRONT, GL::AMBIENT, mat)
      GL.Material(GL::FRONT, GL::DIFFUSE, mat)
      GL.LineWidth(width)

      if (stipple)
        GL.LineStipple(4, 0xAAAA)
        GL.Enable(GL::LINE_STIPPLE)
      end

      GL.CallList(@outlineListID)

      if (stipple)
        GL.Disable(GL::LINE_STIPPLE)
      end
    GL.PopMatrix()
  end


  def drawCursor()
    if @cursor != nil
      drawCellOutline(@cursor.getY, @cursor.getX, @cursor.getZ,
                      (@readOnly ? @@readonlycursorMaterial : @@cursorMaterial), @@lineWidth*3)

      # draw a NORTH indicator
      GL.PushMatrix()
        GL.Translate(@cursor.getY*2,@cursor.getX*2,@cursor.getZ*2)
        #GL.Scale(R-0.01, R-0.01, R-0.01)

        #outlines
        if @readOnly
          GL.Material(GL::FRONT, GL::AMBIENT, @@readonlycursorMaterial)
          GL.Material(GL::FRONT, GL::DIFFUSE, @@readonlycursorMaterial)
        else
          GL.Material(GL::FRONT, GL::AMBIENT, @@cursorMaterial)
          GL.Material(GL::FRONT, GL::DIFFUSE, @@cursorMaterial)
        end
        GL.LineWidth(@@lineWidth*5)

        GL.CallList(@arrowListID)

      GL.PopMatrix()
    end
  end

  def drawNilArchitecture(string)
    GL.PushMatrix()
      GL.Material(GL::FRONT, GL::AMBIENT, @@black)
      GL.Material(GL::FRONT, GL::DIFFUSE, @@black)
      GL.Translate(0,0,0)
      GL.RasterPos3d(0,0,0)

      drawString(string)
    GL.PopMatrix()
  end

  def lineMaterial()
    if @clearColour == @@black
      return [1,1,1,0.7]
    else
      return [0,0,0,0.7]
    end
  end

  def emptyCellLineMaterial()
    return @@materials[CELL_GREY]
  end

  def flipClearColour()
    if @clearColour == @@white
      @clearColour = @@black
    else
      @clearColour = @@white
    end
  end


  #
  # Material/Colour constants
  #

#    CELL_WHITE = 10
#    CELL_GREY = 11
#    CELL_LIGHTGREY = 12

  def transparent(mat, amount=0.3)
    newmat = mat.dup
    newmat[3] = amount
    return newmat
  end

  @@materials = []
  @@materials[CELL_WHITE] =           [1.00,1.00,1.00,1.0]
  @@materials[CELL_RED] =             [1.00,0.00,0.00,1.0]
  @@materials[CELL_GREEN] =           [0.00,1.00,0.00,1.0]
  @@materials[CELL_BLUE] =            [0.00,0.00,1.00,1.0]
  @@materials[CELL_GREY] =            [0.50,0.50,0.50,1.0]
  @@materials[CELL_CYAN] =            [0.00,1.00,1.00,1.0]
  @@materials[CELL_MAGENTA] =         [1.00,0.00,1.00,1.0]
  @@materials[CELL_YELLOW] =          [1.00,1.00,0.00,1.0]
  @@materials[CELL_ORANGE] =          [1.00,0.50,0.00,1.0]
  @@materials[CELL_DARK_RED] =        [0.50,0.00,0.00,1.0]
  @@materials[CELL_DARK_GREEN] =      [0.00,0.50,0.00,1.0]
  @@materials[CELL_DARK_BLUE] =       [0.00,0.00,0.50,1.0]
  @@materials[CELL_DARK_GREY] =       [0.25,0.25,0.25,1.0]
  @@materials[CELL_DARK_CYAN] =       [0.00,0.50,0.50,1.0]
  @@materials[CELL_DARK_MAGENTA] =    [0.50,0.00,0.50,1.0]
  @@materials[CELL_DARK_YELLOW] =     [0.50,0.50,0.00,1.0]
  @@materials[CELL_DARK_ORANGE] =     [0.50,0.25,0.00,1.0]
  @@materials[CELL_LIGHT_RED] =       [1.00,0.50,0.50,1.0]
  @@materials[CELL_LIGHT_GREEN] =     [0.50,1.00,0.50,1.0]
  @@materials[CELL_LIGHT_BLUE] =      [0.50,0.50,1.00,1.0]
  @@materials[CELL_LIGHT_GREY] =      [0.75,0.75,0.75,1.0]
  @@materials[CELL_LIGHT_CYAN] =      [0.50,1.00,1.00,1.0]
  @@materials[CELL_LIGHT_MAGENTA] =   [1.00,0.50,1.00,1.0]
  @@materials[CELL_LIGHT_YELLOW] =    [1.00,1.00,0.50,1.0]
  @@materials[CELL_LIGHT_ORANGE] =    [1.00,0.75,0.50,1.0]

  @@white = [1,1,1,1]
  @@black = [0,0,0,1]

  @@lineWidth = 2.0

  @@agentMaterial = [1.00,0.75,0.00,1.0]
end