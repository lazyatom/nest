#!/usr/local/bin/ruby

require 'opengl'
require 'glut'

require 'Nest3'
require 'gui/GLArchitectureDisplayer'

$debug = false

class GLUTViewer

  WindowName = "Architecture Viewer"

  attr_reader :currentRuleID

  def initialize()
      @width, @height = 850, 850

      @animate = true
      @displayer = GLArchitectureDisplayer.new
      @displayer.drawEmpty = false
      @displayer.drawNil = false
      @displayer.drawCursor = true

      @animate = false
      @animateDelay = 100
      @animateZ = true
      @animateX = true

      @simulationDelay = 100

      #@architectureList = []
  #@currentIndex = -1

  #@currentRuleID = 1

  setMode(:edit)

  @loadFilename = ""

      @lineHeight = 15

  init()

  @displayer.currentRuleID = @currentRuleID

  end

  def init()
      GLUT.Init()
      GLUT.InitDisplayMode(GLUT::RGB|GLUT::DOUBLE|GLUT::DEPTH)
      GLUT.InitWindowSize(@width,@height)
      GLUT.FullScreen()
      win = GLUT.CreateWindow(WindowName)
      GLUT.DisplayFunc(method(:display).to_proc)
      GLUT.ReshapeFunc(method(:reshape).to_proc)
      GLUT.KeyboardFunc(method(:keys).to_proc)
      GLUT.SpecialFunc(method(:specialKeys).to_proc)

      #GLUT.IdleFunc(Proc.new { sleep(0.1) })
      GLUT.TimerFunc(@animateDelay, method(:animate).to_proc, 1)

      #createMenus()
      @displayer.init()
      @displayer.setArchitecture(nil)
  end

  # GLUT Callback Functions
  def display()
      @displayer.drawScene()
      displayInfo()
      GLUT.SwapBuffers()
  end

  def reshape(w, h)
      @width = w
      @height = h
      @displayer.reshape(w, h)
  end


  def keys(key, i, j)
      #debug "key was: #{key}"
      if @mode == :quit
          quitModeKeys(key, i, j)
      elsif @mode == :load || @mode == :save || @mode == :saveAs
          fileModeKeys(key, i, j)
      elsif @mode == :edit
          editModeKeys(key, i, j)
      elsif @mode == :simulation
          simulationModeKeys(key, i, j)
      else
          puts "ARGH! Unknown mode!!"
      end
      GLUT.PostRedisplay
  end


  def cancelMode
      tmp = @mode
      @mode = @previousMode
      @previousMode = tmp
  end

  def setMode(m)
      @previousMode = @mode
      @mode = m
      setMessage3("Mode: " + @mode.to_s)
  end

  def quitModeKeys(key, i, j)
      case key
          when 121 # "y"
              quit()
          else
              cancelMode()
              setMessage("Quit cancelled.")
      end
  end

  def fileModeKeys(key, i, j)
      case key
          when 13
              if @mode == :load
                  result = loadArchitecture(@loadFilename)
                  cancelMode()
                  if result
                      setMessage("Load succeeded.")
                  else
                      setMessage("Couldn't load '" + @loadFilename + "'");
                  end
              elsif @mode == :saveAs
                  result = save(@loadFilename)
                  cancelMode()
                  setMessage("Saved as `" + @loadFilename + "'")
              end
          when 127 # backspace
              @loadFilename.slice!(@loadFilename.length-1)
          when 27 # esc
              cancelMode()
              setMessage("Cancelled.")
          else
              @loadFilename << key
      end
      if @mode == :load
          setMessage("Loading: " + @loadFilename + "_")
      elsif @mode == :save || @mode == :saveAs
          setMessage("Save As: " + @loadFilename + "_")
      end
  end

  def commonModeKeys(key, i, j)
     case key

          ######## CURSOR MOVEMENT #########
          when 48 # move the cursor North
              @displayer.moveCursor(N)
          when 49 # move the cursor North-East
              @displayer.moveCursor(NE)
          when 50 # move the cursor South-East
              @displayer.moveCursor(SE)
          when 51 # move the cursor South
              @displayer.moveCursor(S)
          when 52 # move the cursor South-West
              @displayer.moveCursor(SW)
          when 53 # move the cursor North-West
              @displayer.moveCursor(NW)
          when 54 # move the cursor Up
              @displayer.moveCursor(UP)
          when 55 # move the cursor Down
              @displayer.moveCursor(DOWN)


          ######## VIEW MOVEMENT ############
          when 39 # ' ' ' move the view Up
              @displayer.moveView("UP")
          when 47 # ' / ' move the view Down
              @displayer.moveView("DOWN")



          ####### CURSOR CELL EDITING ###########
          when 32 # spacebar - insert a new cell at the cursor
              if (@displayer.cursor.neighbourhoodArray.delete_if {|c| Nest3.emptyCell(c) }.length > 0) ||
                  (@displayer.architecture.numBricks == 0)
                  @displayer.nextCellAtCursor()
              else
                  setMessage("Must connect to a neighbour!")
              end
          when 43, 61 # +, =
              @displayer.flipCellAtCursor()
          when 45
              @displayer.flipCellAtCursor(-1)
          when 127 # backspace
              @displayer.deleteCellAtCursor()


          ####### CELL DISPLAY #########
          when 101 # 'e'
              @displayer.drawEmpty = !@displayer.drawEmpty
              setMessage(((@displayer.drawEmpty)?("Drawing"):("Hiding")) + " empty cells")
          when 110 # 'n'
              @displayer.drawNil = !@displayer.drawNil
              setMessage(((@displayer.drawNil)?("Drawing"):("Hiding")) + " nil cells")
          when 121 # 'y'
              @displayer.drawType = GLArchitectureDisplayer::DRAW_FILLED
          when 117 # 'u'
              @displayer.drawType = GLArchitectureDisplayer::DRAW_VALUES
          when 105 # 'i'
              @displayer.drawType = GLArchitectureDisplayer::DRAW_IDS
          when 111 # 'o'
              @displayer.drawType = GLArchitectureDisplayer::DRAW_ORDER
          when 112 # 'p'
              @displayer.drawType = GLArchitectureDisplayer::DRAW_ORDER_VALUE

          ####### MISC #############

          when 104 # 'h'
              @displayer.toggleMode()
              setMessage("Rule Highlighting: " + ((@displayer.highlightRules)?("ON."):("OFF.")))
          when 65 # 'shift+A'
              @animate = !@animate
              setMessage("Animation is " + ((@animate)?("ON"):("OFF")))
          when 122 # 'z'
              @animateZ = !@animateZ
          when 120 # 'x'
              @animateX = !@animateX

          when 63 # '?'
                  setMessage2("ctrl: (n)ew (o)pen (s)ave (a)lg. (q)uit")
                  setMessage3("reset-(s)tates, (r)eset-ids, random-or(d)er")

          ####### RULE DISPLAY ########
          when 44 # '<' - change to previous architecture
              previousRule()
          when 46 # '>' - change to the next architecture
              nextRule()


          ######## ARCHITECTURE MANAGEMENT #########
          when 19 # 'ctrl+s'
              save()
          when 20 # 'ctrl+t'
              saveToTempFile()

          when 17 # 'ctrl-q'
              quit()
          when 113 # 'q'
           setMode(:quit)
           setMessage("Quit? [y/n] _")

          when 115 # 's'
              @displayer.architecture.setBricks(CELL_RED)
              setMessage("All bricks set to CELL_RED.")
          when 15 # 'ctrl+o'
              setMode(:load)
              @loadFilename = ""
              setMessage("Loading: _")


          when 99 # 'c'
              @displayer.architecture.clearEmptyCells()




          # pass through any other keys to our controller
          else
              setMessage "unrecognised key: #{key}"
      end
  end

  def editModeKeys(key, i, j)
      case key

          when 9 # tab
              setMode(:simulation)

          when 93 # "]'
              @displayer.flipOrderAtCursor()
          when 91 # '['
              @displayer.flipOrderAtCursor(-1)


          when 114 # 'r'
              @displayer.architecture.resetCellIDs()
              setMessage("CellIDs reset.")

          when 14 # 'ctrl+n'
              newArchitecture()

          when 18 # 'ctrl+r'
              reload()
          when 83 # 'shift-s'
              setMode(:saveAs)
              @loadFilename = ""
              setMessage("Save As: _")
          when 100 # 'd'
              @displayer.architecture.applyRandomOrder()
              setMessage("Random order applied.")
          when 3 # 'ctrl-c'
              rulesName = @currentFile.slice(0..(@currentFile.length-6)) + ".rules"
              @displayer.architecture.rules(true).save(rulesName)
              setMessage("Saved Rules as `" + rulesName + "'")


          ####### ALGORITHM ############
          when 1 # 'ctrl+A'
              setMessage("Saving architecture to temp file for processing...")
              saveToTempFile()
              @displayer.architecture.setBricks(CELL_RED)
              setMessage("Running Algorithm... please wait")
              alg = Algorithm.new(@displayer.architecture)
              alg.ISA()
              setMessage "Algorithm run complete: #{alg.states.length} states"

          else
              commonModeKeys(key, i, j)
      end
  end

  def simulationModeKeys(key, i, j)
      case key
          when 9 # tab
              setMode(:edit)

          when 116 # 't'
              @displayer.drawAgents = !@displayer.drawAgents

          when 98 # 'b'
              @simulation.runCycle()

          when 18 # 'ctrl+r'
              reloadSimulation()

          when 109 # 'm'
              @simulation.rules.each { |rule|
                  if (rule.cc.buildMatches3D(@displayer.cursor)) # SEGFAULT
                      setMessage("\tmatched rule! #{rule.cc.id}")
                      rule.p
                      matched = true
                      break
                      #@location.setValue(rule.cc.value())
                      #@location.setOrder(@simulation.architecture.numBricks)
                      #@location.setRuleID(rule.cc.order())
                      #@location.expandSpaceAround()
                      #break
                  end
                  setMessage("No Rule Match.") if !matched
              }
          else
              commonModeKeys(key, i, j)
      end
  end


  def specialKeys(key, i, j)
      #debug "special key was: #{key}"
      case key
          when GLUT::KEY_UP
              @displayer.moveView("FORWARD")
          when GLUT::KEY_DOWN
              @displayer.moveView("BACKWARD")
          when GLUT::KEY_LEFT
              @displayer.moveView("LEFT")
          when GLUT::KEY_RIGHT
              @displayer.moveView("RIGHT")
          when GLUT::KEY_PAGE_UP
              @displayer.rotateView("UP")
          when GLUT::KEY_PAGE_DOWN
              @displayer.rotateView("DOWN")
          when GLUT::KEY_HOME
              @displayer.rotateView("BACKWARD")
          when GLUT::KEY_END
              @displayer.rotateView("FORWARD")
      end
      GLUT.PostRedisplay
  end

  def setOrthographicProjection()
          # switch to projection mode
          GL.MatrixMode(GL::PROJECTION);
          # save previous matrix which contains the
          # settings for the perspective projection
          GL.PushMatrix();
          # reset matrix
          GL.LoadIdentity();
          # set a 2D orthographic projection
          GLU.Ortho2D(0, @width, 0, @height);
          # invert the y axis, down is positive
          GL.Scale(1, -1, 1);
          # mover the origin from the bottom left corner
          # to the upper left corner
          GL.Translate(0, -@height, 0);
          GL.MatrixMode(GL::MODELVIEW);
  end

  def resetPerspectiveProjection()
          GL.MatrixMode(GL::PROJECTION);
          GL.PopMatrix();
          GL.MatrixMode(GL::MODELVIEW);
  end

  def drawBox(x,y,w,h)
      GL.Material(GL::FRONT, GL::AMBIENT, @displayer.lineMaterial())
      GL.Material(GL::FRONT, GL::DIFFUSE, @displayer.lineMaterial())
      GL.LineWidth(1)
      GL.Begin(GL::LINE_LOOP)
          GL.Vertex(x,y,0)
          GL.Vertex(x+w,y,0)
          GL.Vertex(x+w,y+h,0)
          GL.Vertex(x,y+h,0)
      GL.End()

      GL.Material(GL::FRONT, GL::AMBIENT, [0.5,0.5,0.5,0.5])
      GL.Material(GL::FRONT, GL::DIFFUSE, [0.5,0.5,0.5,0.5])
      GL.Begin(GL::POLYGON)
          GL.Vertex(x,y,0)
          GL.Vertex(x+w,y,0)
          GL.Vertex(x+w,y+h,0)
          GL.Vertex(x,y+h,0)
      GL.End()
  end

  def displayCellInfo()
    setOrthographicProjection
    GL.PushMatrix
    GL.LoadIdentity

    GL.Material(GL::FRONT, GL::AMBIENT, [1,1,1,1])
    GL.Material(GL::FRONT, GL::DIFFUSE, [1,1,1,1])

    GL.PopMatrix
    resetPerspectiveProjection
  end


  def displayInfo()
    setOrthographicProjection
    GL.PushMatrix
    GL.LoadIdentity

    # main tool box
    drawBox(0, @height-50, @width, 50)

    # cell info box
    drawBox(@width-100, @height-120, 100, 70)

    GL.Material(GL::FRONT, GL::AMBIENT, [1,1,1,1])
    GL.Material(GL::FRONT, GL::DIFFUSE, [1,1,1,1])

    # cell info
    displayRight(@height-45, currentFile + "\n" +
                 getArchInfo() + "\n" + displayModeString)
    displayLeft(@height-45, lastMessage + "\n" +
                lastMessage2 + "\n" + lastMessage3)

    # cell info
    displayRight(@height-115,
                 "Cell: " + @displayer.cursor.id.to_s + "\n" +
                 "Value: " + @displayer.cursor.value.to_s + "\n" +
                 "Order: " + @displayer.cursor.order.to_s + "\n" +
                 "RuleID: " + @displayer.cursor.ruleID.to_s);


    GL.PopMatrix
    resetPerspectiveProjection
  end

  def displayLeft(height, string)
    strings = string.split("\n")
    string.each_with_index do |str, i|
      str.chomp!
      renderBitmapString(5,height+(@lineHeight*(i+0.5)),str)
    end
  end

  def displayRight(height, string)
    strings = string.split("\n")
    strings.each_with_index do |str, i|
      str.chomp!
      renderBitmapString((@width-str.length*8)-5,height+(@lineHeight*(i+0.5)),str)
    end
  end

  def renderBitmapString(x,y,string)
    GL.RasterPos3d(x, y, 1)
    string.length.times do |i|
      GLUT.BitmapCharacter(GLUT::BITMAP_8_BY_13, string[i]) # custom function for ruby bindings
    end
  end


  def currentFile()

    if @collection != nil
      return @currentFile + " : rule " + (@currentIndex+1).to_s
    else
          return "no file" if @currentFile == nil
        tmp = @currentFile
        tmp += " : rule " + @currentRuleID.to_s if @displayer.highlightRules
      return tmp
    end
  end

  def getArchInfo()
     return "#{@displayer.architecture.numBricks} bricks, " +
         "#{@displayer.architecture.numStates} states" if @displayer.architecture != nil
  end

  def lastMessage2()
     return @message2.to_s
    end

    def lastMessage3()
        return @message3.to_s
    end

    def setMessage2(m2)
        @message2 = m2
    end

    def setMessage3(m3)
        @message3 = m3
    end

  def displayModeString
    case @displayer.drawType
      when GLArchitectureDisplayer::DRAW_FILLED
        displayType = "Filled  |u|i|o|p"
      when GLArchitectureDisplayer::DRAW_VALUES
        displayType = "y| Values |i|o|p"
      when GLArchitectureDisplayer::DRAW_IDS
        displayType = "y|u| CellID |o|p"
      when GLArchitectureDisplayer::DRAW_ORDER
        displayType = "y|u|i| Order  |p"
      when GLArchitectureDisplayer::DRAW_ORDER_VALUE
        displayType = "y|u|i|o| Ord/Val"
    end
    return displayType
  end

  def lastMessage
     return @lastMessage.to_s
  end

  def setMessage(msg)
     @lastMessage = msg
    end








    def setArchitectureToDisplay(arch)
      @displayer.setArchitecture(arch)
      GLUT.PostRedisplay
    end

    def setSimulation(s)
        setArchitectureToDisplay(s.architecture)
        @displayer.setSimulation(s)
        @simulation = s
    end


    def animate(i)
        #puts "animating"
        multiplier = 1
        if @animate
            if @displayer.highlightRules
                nextRule()
                multiplier = 5
            else
                @displayer.rotateView("FORWARD", 3) if @animateX
                @displayer.rotateView("UP", 0.5) if @animateZ
            end
            GLUT.PostRedisplay
        end
        GLUT.TimerFunc(@animateDelay*multiplier, method(:animate).to_proc, 1)
    end

    def previousRule()
        @currentRuleID = (@currentRuleID - 1)
        @currentRuleID = @architecture.numBricks if @currentRuleID == 0
        @displayer.currentRuleID = @currentRuleID
    end

    def nextRule()
        @currentRuleID = (@currentRuleID % @architecture.numBricks) + 1
        @displayer.currentRuleID = @currentRuleID
    end





  ############### file methods ##################

  def saveToTempFile()
        cfile = @currentFile
        @currentFile = "/tmp/temp.arch"
        save()
        reload()
        @currentFile = cfile
  end

  def reload()
    setMessage("reloading " + @currentFile)
    if @collection == nil
      loadArchitecture(@currentFile)
    else
      loadArchitectureCollection(@currentFile)
    end
  end

  def loadArchitecture(filename)
    puts "Trying to load: \"#{filename}\""

    if !FileTest.exists?(filename)
      if (FileTest.exists?(filename + ".arch"))
          filename << ".arch"
      else
          return false
      end
        end

    @architecture = Architecture.load(filename)
    if @architecture == nil
      puts "\"#{filename}\" doesn't exist..."
      return false
    else
      @collection = nil
      setArchitectureToDisplay(@architecture)
      @currentFile = filename
      return true
    end
  end

  def newArchitecture()
     @architecture = Architecture.new(30)
     @collection = nil
     setArchitectureToDisplay(@architecture)
     @currentFile = "new.arch"
     setMessage("New architecture 'new.arch' created")
  end

  def loadArchitectureCollection(filename)
    @collection = ArchitectureCollection.load(filename)
    if @collection == nil
      puts "\"#{filename}\" doesn't exist..."
      return nil
    else
      @architecture = nil
      @collection.to_a.sort { |x,y| x.cc.order <=> y.cc.order }.each { |arch|
        id = @currentIndex
        puts "adding arch with id #{id} to " + @architectures.inspect
        @architectureList << [id, arch] if @architectureList.assoc(id) == nil
        @currentIndex = @architectureList.length-1
      }
      @currentIndex = 0
      setArchitectureToDisplay(@architectureList[@currentIndex][1])
      @currentFile = filename
    end
  end

  def save(filename=@currentFile)
    if @architecture != nil
      setMessage "Saving architecture as #{filename}"
      @architecture.save(filename)
    elsif @collection != nil
      setMessage "Saving architecture collection as #{filename}"
      @collection.save(filename)
    end
    @currentFile = filename
  end


  def quit()
    Kernel.exit()
  end





    ########## gui running methods ##############


  # display and interact with the given architecture
  def edit(args)
    puts "Editing: #{args.inspect}"

    args.each { |filename|
      if loadArchitecture(filename) == nil
        puts "Creating new architecture: \"#{args}"
        arch = Architecture.new(30)
        arch.resetCellIDs
        arch.save(filename)
        loadArchitecture(filename)
      end
    }
    #puts "loaded #{@architectures.length} architectures"
    run()
  end

  def rules(args)
    puts "Loading rules"
    loadArchitectureCollection(args[0])
    run()
  end

  # to run the simulation
  def simulate(args)
     puts "running simulation from #{ARGV[1]}"
        simulation = Simulation.createFromArgs(ARGV)

        setSimulation(simulation)
        setMode(:simulation)
        @animate = true
        #@displayer.uniformBricks = true

        GLUT.TimerFunc(@simulationDelay, method(:runSimulation).to_proc, 0)

        run()
  end


  def runSimulation(arg)

        if @animate
                @displayer.rotateView("FORWARD", 3) if @animateX
                @displayer.rotateView("UP", 0.5) if @animateZ
        end

        if @simulation.runCycle()
            setMessage2("Simulation Cycle #{@simulation.cycles}: #{@displayer.architecture.numBricks()} bricks")
            GLUT.PostRedisplay
            GLUT.TimerFunc(@simulationDelay, method(:runSimulation).to_proc, 1)
        else
            setMessage2("Simulation Stopped (#{@simulation.cycles} cycles, #{@displayer.architecture.numBricks()} bricks)")
            GLUT.PostRedisplay
        end

  end

  def test(args)
    puts"test, args was: " + args.inspect
  end

    def run(arg=nil)
      if arg != nil
            while true
                GLUT.CheckLoop()
                yield self
                #sleep(1)
            end
        else
            GLUT.MainLoop()
        end
    end

  # this calls the appropriate method within the controller, according to
  # what parameters were passed in the arguments
  def doArgs(args)
    if args.include?("debug")
      $debug = true
      puts "debug mode is on"
      args.delete_if { |a| a == "debug" }
    end

     if args.length == 0

         newArchitecture()
         run()

     else

    if self.respond_to?(args[0])
      self.method(args[0]).call(args[1..args.length])
    else
      # lets default to trying to edit the file
      debug "No action specified - trying to edit: #{args}"
      if args[0][(args[0].length-5)..(args[0].length-1)] == ".arch"
           edit(args)
       elsif args[0][(args[0].length-6)..(args[0].length-1)] == ".rules"
           rules(args)
       else
      puts "Don't know how to \"#{args[0]}\""
      end
    end
        end
  end

end




=begin
    # old glut stuff

    def processMenuEvent(option)
        @displayer.drawType = option
        GLUT.PostRedisplay
    end

    def mouse(button, state, x, y)
        @x0 = x; @y0 = y
        @state = state
    end

    def motion(x, y)
        if @state == GLUT::DOWN then
            GL.Rotate(@x0 - x, 0.0, 1.0, 0.0)
            GL.Rotate(@y0 - y, 1.0, 0.0, 0.0)
            @x0 = x; @y0 = y
            GLUT.PostRedisplay
        end
    end


    def createMenus()
        menu = GLUT.CreateMenu($processMenuEvents)

        GLUT.AddMenuEntry("Draw Filled", GLArchitectureDisplayer::DRAW_FILLED)
        GLUT.AddMenuEntry("Draw Values", GLArchitectureDisplayer::DRAW_VALUES)
        GLUT.AddMenuEntry("Draw IDs", GLArchitectureDisplayer::DRAW_IDS)
        GLUT.AddMenuEntry("Draw Order", GLArchitectureDisplayer::DRAW_ORDER)
        GLUT.AddMenuEntry("Draw Order:Value", GLArchitectureDisplayer::DRAW_ORDER_VALUE)

        GLUT.AttachMenu(GLUT::RIGHT_BUTTON)
    end
=end