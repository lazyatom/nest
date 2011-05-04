require 'nest_3'
require 'nest_3/gui/gl_architecture_displayer'
require 'nest_3/gui/buffers'

module Nest3
  module GUI
    class GLUTViewer2
      WindowName = "Architecture Viewer"

      attr_reader :currentRuleID, :displayer, :loadFilename

      def initialize
        @displayer = GLArchitectureDisplayer.new

        @bufferList = []
        @currentBuffer = 0
        @loadFilename = "untitled"

        setupParameters
        initGLUT
      end

      def setupParameters
        @width, @height = 850, 850

        @lineHeight = 15

        @animate = true

        @displayer.drawEmpty = false
        @displayer.drawNil = false
        @displayer.drawCursor = true

        @animate = false
        @animateDelay = 100
        @animateZ = true
        @animateX = true

        @simulationDelay = 100
      end

      def initGLUT
        GLUT.Init
        GLUT.InitDisplayMode(GLUT::RGB|GLUT::DOUBLE|GLUT::DEPTH)
        GLUT.InitWindowSize(@width,@height)
        GLUT.FullScreen
        win = GLUT.CreateWindow(WindowName)
        GLUT.DisplayFunc(method(:display).to_proc)
        GLUT.ReshapeFunc(method(:reshape).to_proc)
        GLUT.KeyboardFunc(method(:keys).to_proc)
        GLUT.SpecialFunc(method(:specialKeys).to_proc)

        GLUT.TimerFunc(@animateDelay, method(:animate).to_proc, 1)

        @displayer.init
        @displayer.setArchitecture(nil)
      end

      # GLUT Callback Functions
      def display
        @displayer.drawScene
        displayInfo
        GLUT.SwapBuffers
      end

      def reshape(w, h)
        @width = w
        @height = h
        @displayer.reshape(w, h)
      end

      def setOrthographicProjection
        # switch to projection mode
        GL.MatrixMode(GL::PROJECTION)
        # save previous matrix which contains the
        # settings for the perspective projection
        GL.PushMatrix
        # reset matrix
        GL.LoadIdentity
        # set a 2D orthographic projection
        GLU.Ortho2D(0, @width, 0, @height)
        # invert the y axis, down is positive
        GL.Scale(1, -1, 1)
        # mover the origin from the bottom left corner
        # to the upper left corner
        GL.Translate(0, -@height, 0)
        GL.MatrixMode(GL::MODELVIEW)
      end

      def resetPerspectiveProjection
        GL.MatrixMode(GL::PROJECTION)
        GL.PopMatrix
        GL.MatrixMode(GL::MODELVIEW)
      end

      def drawBox(x,y,w,h)
        GL.Material(GL::FRONT, GL::AMBIENT, @displayer.lineMaterial)
        GL.Material(GL::FRONT, GL::DIFFUSE, @displayer.lineMaterial)
        GL.LineWidth(1)
        GL.Begin(GL::LINE_LOOP)
          GL.Vertex(x,y,0)
          GL.Vertex(x+w,y,0)
          GL.Vertex(x+w,y+h,0)
          GL.Vertex(x,y+h,0)
        GL.End

        GL.Material(GL::FRONT, GL::AMBIENT, [0.5,0.5,0.5,0.5])
        GL.Material(GL::FRONT, GL::DIFFUSE, [0.5,0.5,0.5,0.5])
        GL.Begin(GL::POLYGON)
          GL.Vertex(x,y,0)
          GL.Vertex(x+w,y,0)
          GL.Vertex(x+w,y+h,0)
          GL.Vertex(x,y+h,0)
        GL.End
      end

      def displayCellInfo
        setOrthographicProjection
        GL.PushMatrix
          GL.LoadIdentity
          GL.Material(GL::FRONT, GL::AMBIENT, [1,1,1,1])
          GL.Material(GL::FRONT, GL::DIFFUSE, [1,1,1,1])
        GL.PopMatrix
        resetPerspectiveProjection
      end


      def displayInfo
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
                     getArchInfo + "\n" +
                     displayModeString)
        displayLeft(@height-45, lastMessage + "\n" +
                        lastMessage2 + "\n" + bufferString + " / " +
                        lastMessage3)

        # cell info
        if (@displayer.cursor != nil)
        displayRight(@height-115,
                    "Cell: " + @displayer.cursor.id.to_s + "\n" +
                    "Value: " + @displayer.cursor.value.to_s + "\n" +
                    "Order: " + @displayer.cursor.order.to_s + "\n" +
                    "RuleID: " + @displayer.cursor.ruleID.to_s)
        end

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
          GLUT.BitmapCharacter(GLUT::BITMAP_8_BY_13, string[i])
        end
      end

      def currentFile
        if buffer != nil
          buffer.filename.to_s
        else
          "nothing"
        end
      end

      def getArchInfo
        if buffer.architecture != nil
          return "#{buffer.architecture.numBricks} bricks, " +
                 "#{buffer.architecture.numStates} states"
        else
          return "nothing"
        end
      end

      def lastMessage2
        return @message2.to_s
      end

      def lastMessage3
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
        else
          displayType = "unknown"
        end
        return displayType
      end

      def bufferString
        result = @currentBuffer.to_s + ". [" + buffer.class.to_s[0..3] + "]"
      end

      def lastMessage
        return @lastMessage.to_s
      end

      def setMessage(msg)
        @lastMessage = msg
      end

      def animate(i)
        #puts "animating"
        multiplier = 1
        if @animate
          if @displayer.highlightRules
            nextRule
            multiplier = 5
          else
            @displayer.rotateView("FORWARD", 3) if @animateX
            @displayer.rotateView("UP", 0.5) if @animateZ
          end
          GLUT.PostRedisplay
        end
        GLUT.TimerFunc(@animateDelay*multiplier, method(:animate).to_proc, 1)
      end

      def keys(key, i, j)
        #debug "key was: #{key}"
        if @mode == :quit
          quitModeKeys(key, i, j)
        elsif @mode == :load || @mode == :save || @mode == :saveAs
          fileModeKeys(key, i, j)
        elsif @mode == :new
          newModeKeys(key, i, j)
        elsif ReservedKeys.include?(key)
          reservedKeys(key, i, j)
        else
          buffer.keys(key, i, j)
        end
        GLUT.PostRedisplay
      end

      def setMode(m)
        @previousMode = @mode
        @mode = m
        setMessage3("Mode: " + @mode.to_s)
      end

      def cancelMode
        tmp = @mode
        @mode = @previousMode
        @previousMode = tmp
        setMessage3("Mode: " + @mode.to_s)
        setMessage3("") if @mode == nil
      end

      def quitModeKeys(key, i, j)
        case key
        when 121 # "y"
          quit
        else
          cancelMode
          setMessage("Quit cancelled.")
        end
      end

      def newModeKeys(key, i, j)
        case key
        when 97 # 'a'
          newBuffer(ArchitectureBuffer.new)
          setMessage("New architecture buffer")
          cancelMode
        when 114 # 'r'
          newBuffer(RuleCollectionBuffer.new)
          setMessage("New rule collection buffer")
          cancelMode
        when 115 # 's'
          newBuffer(SimulationBuffer.new)
          setMessage("New simulation buffer")
          cancelMode
        else
          cancelMode
          setMessage("New buffer cancelled.")
        end
      end

      def fileModeKeys(key, i, j)
        case key
        when 13
          if @mode == :load
            result = loadBuffer(@loadFilename)
            cancelMode
            if result
                setMessage("Load succeeded.")
            else
                setMessage("Couldn't load '" + @loadFilename + "'");
            end
          elsif @mode == :saveAs
            result = buffer.save(@loadFilename)
            cancelMode
            setMessage("Saved as `" + @loadFilename + "'")
          end
        when 127 # backspace
          @loadFilename.slice!(@loadFilename.length-1)
        when 27 # esc
          cancelMode
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

      ReservedKeys = [GLUT::KEY_UP, GLUT::KEY_DOWN, GLUT::KEY_LEFT,
                      GLUT::KEY_RIGHT, GLUT::KEY_PAGE_UP, GLUT::KEY_PAGE_DOWN,
                      GLUT::KEY_HOME, GLUT::KEY_END, 48, 49, 50, 51, 52, 53, 54,
                      55, 39, 47, 17, 113, 15, 101, 110, 121, 117, 105, 111, 112,
                      65, 122, 120, 44, 46, 14]

      def reservedKeys(key, i, j)
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

        when 65 # 'shift+A'
          @animate = !@animate
          setMessage("Animation is " + ((@animate)?("ON"):("OFF")))
        when 122 # 'z'
          @animateZ = !@animateZ
        when 120 # 'x'
          @animateX = !@animateX

        ####### RESERVED MODE KEYS ########
        when 17 # 'ctrl-q'
          quit
        when 113 # 'q'
          setMode(:quit)
          setMessage("Quit? [y/n] _")
        when 15 # 'ctrl+o'
          setMode(:load)
          @loadFilename = ""
          setMessage("Loading: _")
        when 14 # 'ctrl+n'
          setMode(:new)
          setMessage("[A]rchitecture, [R]ule set, or [S]imulation? _")

        ####### BUFFER CHANGE ########
        when 44 # '<' - change to previous buffer
          previousBuffer
        when 46 # '>' - change to the next buffer
          nextBuffer

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

      #### BUFFER MANAGEMENT #####
      def buffer
        @bufferList[@currentBuffer]
      end

      def previousBuffer
        storeBuffer
        @currentBuffer -= 1
        @currentBuffer = [@bufferList.length-1,0].max if @currentBuffer < 0
        restoreBuffer
      end

      def nextBuffer
        storeBuffer
        @currentBuffer += 1
        @currentBuffer = 0 if @currentBuffer >= @bufferList.length
        restoreBuffer
      end

      def restoreBuffer
        @displayer.setArchitecture(buffer.architecture)
        @displayer.setViewPosition(buffer.position, buffer.rotation)
        @displayer.drawType = buffer.displayType
      end

      def storeBuffer
        buffer.saveDisplayInfo(@displayer.getViewPosition,
                               @displayer.getViewRotation,
                               @displayer.drawType) if buffer != nil
      end

      def newBuffer(b)
        @bufferList.insert(@currentBuffer+1, b)
        b.setGUI(self)
        nextBuffer
      end

      def quit
        Kernel.exit
      end

      def run(arg=nil)
        if arg != nil
          while true
            GLUT.CheckLoop
            yield self
            #sleep(1)
          end
        else
          GLUT.MainLoop
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
          newBuffer(ArchitectureBuffer.new)
        else
          newBuffer(NestBuffer.load(ARGV[0]))
        end

        run
      end
    end
  end
end