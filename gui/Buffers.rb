class NestBuffer

    attr_reader :position, :rotation, :displayType,
                :filename, :architecture, :displayer, :gui
    
    def saveDisplayInfo(p, r, d)
        @position = p
        @rotation = r
        @displayType = d
    end

    def setGUI(gui)
        @gui = gui
        @displayer = @gui.displayer
    end

    def setMessage(s)
        @gui.setMessage(s) if @gui != nil
    end

    def NestBuffer.load(filename)
        if (filename =~ /\s*.arch/) != nil
            return ArchitectureBuffer.load(filename)
        elsif (filename =~ /\s*.rules/) != nil
            return RuleCollectionBuffer.load(filename)
        elsif (filename =~ /\s*.sim/) != nil
            return SimulationBuffer.load(filename)
        else
            puts "unknown filetype"
        end
    end
    
    def save(filename=@filename)
        puts "implement saving!"
    end

end



class ArchitectureBuffer < NestBuffer

    def initialize()
        @position = [0,0,-20]
        @rotation = [-30,0,0]
        @displayType = GLArchitectureDisplayer::DRAW_FILLED
        @architecture = Architecture.new(30)
    end

    

    def keys(key, i, j)
        case key

            ####### CURSOR CELL EDITING ###########
            when 32 # spacebar - insert a new cell at the cursor
                if (@displayer.cursor.neighbourhoodArray.delete_if {|c| emptyCell(c) }.length > 0) ||
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


            when 115 # 's'
                @displayer.architecture.setBricks(CELL_RED)
                setMessage("All bricks set to CELL_RED.")
    
                
            when 99 # 'c'
                @displayer.architecture.clearEmptyCells()
                            
            when 93 # "]'
                @displayer.flipOrderAtCursor()
            when 91 # '['
                @displayer.flipOrderAtCursor(-1)                            


            when 114 # 'r'
                @displayer.architecture.resetCellIDs()
                setMessage("CellIDs reset.")



            when 100 # 'd'
                @displayer.architecture.applyRandomOrder()
                setMessage("Random order applied.")
            when 3 # 'ctrl-c'
                rulesName = @currentFile.slice(0..(@currentFile.length-6)) + ".rules"
                @displayer.architecture.rules(true).save(rulesName)
                setMessage("Saved Rules as `" + rulesName + "'")
                
                
                        
            ######## ARCHITECTURE MANAGEMENT #########
            when 19 # 'ctrl+s'
                save()
            when 20 # 'ctrl+t'
                saveToTempFile()
            when 18 # 'ctrl+r'
                reload()
            when 83 # 'shift-s'
                @gui.setMode(:saveAs)
                #@loadFilename = ""
                setMessage("Save As: " + @gui.loadFilename + "_")                
                

            ####### ALGORITHM ############
            when 1 # 'ctrl+A'
                setMessage("Saving architecture to temp file for processing...")
                saveToTempFile()
                @displayer.architecture.setBricks(CELL_RED)
                setMessage("Running Algorithm... please wait")
                alg = Algorithm.new(@displayer.architecture)
                alg.ISA()
                setMessage "Algorithm run complete: #{alg.states.length} states"
        
        end
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
	
	def ArchitectureBuffer.load(filename)
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

end






class RuleCollectionBuffer < ArchitectureBuffer

    attr_reader :rules



    def initialize()
        @position = [0,0,-10]
        @rotation = [-30,0,0]
        @displayType = GLArchitectureDisplayer::DRAW_FILLED

    end

	def rules(args)
		puts "Loading rules"
		loadArchitectureCollection(args[0])
		run()
	end
    
    
    def keys(key, i, j)
        case key
            
            when 12342
                return
        end
    end

	def RuleCollectionBuffer.load(filename)
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

    def previousRule()
        @currentRuleID = (@currentRuleID - 1)
        @currentRuleID = @architecture.numBricks if @currentRuleID == 0
        @displayer.currentRuleID = @currentRuleID
    end
    
    def nextRule()
        @currentRuleID = (@currentRuleID % @architecture.numBricks) + 1
        @displayer.currentRuleID = @currentRuleID    
    end    
    
end






class SimulationBuffer < NestBuffer

    def SimulationBuffer.load(filename)
        puts "sim load"
    end


    def initialize()
        @position = [0,0,-20]
        @rotation = [-30,0,0]
        @displayType = GLArchitectureDisplayer::DRAW_FILLED
    end

    def keys(key, i, j)
        case key
                
            when 104 # 'h'
                @displayer.toggleMode()
                setMessage("Rule Highlighting: " + ((@displayer.highlightRules)?("ON."):("OFF.")))
                            

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


            
            ######## ARCHITECTURE MANAGEMENT #########
            when 19 # 'ctrl+s'
                save()
            when 20 # 'ctrl+t'
                saveToTempFile()

        end
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

end