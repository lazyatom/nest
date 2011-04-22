#!/usr/bin/env ruby

require 'nest_3'

class Agent
  attr_reader :location, :rules, :id

  @@nextId = 0

  def initialize(cell=nil, rules=nil)
    @location = cell
    @rules = rules
    @id = (@@nextId += 1)
    @architecture = nil
    @simulation = nil
  end

  def setRules(r)
    @rules = r
  end

  def setArchitecture(a)
    @architecture  = a
  end

  def setSimulation(s)
    @simulation = s
    @architecture = @simulation.architecture
    @rules = @simulation.rules
    @location = @simulation.findEmptyCell
  end

  def run
    build
    moveRandomly
    #puts "current location: #{@location.id}"
  end

  def build
    @rules.each do |rule|
      if (rule.cc.buildMatches3D(@location)) # SEGFAULT
        puts "\tAgent #{@id} matched rule! #{rule.cc.id}"
        @location.setValue(rule.cc.value)
        @location.setOrder(@simulation.architecture.numBricks)
        @location.setRuleID(rule.cc.order)
        @location.expandSpaceAround
        break
      end
    end
  end

  # move into an unoccupied cell
  def moveRandomly
    directions = @simulation.allowedDirections.dup # need to modify a copy.
    #puts "allowed directions = #{directions.inspect}"
    dir = -1
    until directions.empty?
      dir = directions.delete_at(rand(directions.length))
      newcell = @location.get(dir)
      if newcell != nil
        break if (newcell.value == CELL_EMPTY)
      end
    end

    if directions.length == 0
      # this means we couldn't find anywhere to move
      # --> warp somewhere
      warp
    else
      return if newcell == nil # no location found, probably only 1 empty cell
      #puts "moved in dir #{dir}"
      @location = newcell
    end

    puts "location is nil!" if @location == nil
  end

  def move(dir)
    newcell = @location.get(dir)
    @location = newcell if newcell != nil
  end

  def warp
    @location = @simulation.findEmptyCell
  end

  def to_s
    "agent #{@id} is in cell #{@location.id}"
  end
end

class Simulation
  attr_reader :agents, :rules, :architecture, :dimensions
  attr_accessor :brickLimit, :cycleLimit, :ruleFile, :cycles
  attr_accessor :ignoreBrickLimit

  AllowedDirections2D = [0,1,2,3,4,5]
  AllowedDirections3D = [0,1,2,3,4,5,6,7]

  def initialize(a, r)
    @rules = r.to_a
    @architecture = a
    @agents = []
    @dimensions = 2
    @ignoreBrickLimit = false
    @cycles = 0
  end

  def setRules(r)
    @rules = r
    @agents.each { |a| a.setRules(r) }
  end

  def setDimensions(d)
    @dimensions = d
  end

  def allowedDirections
    if @dimensions == 0
      return []
    elsif @dimensions == 2
      return AllowedDirections2D
    elsif @dimensions == 3
      return AllowedDirections3D
    end
  end

  def findEmptyCell
    cell = nil
    emptyCells = @architecture.to_empty_a
    if @dimensions == 3
      return emptyCells[rand(emptyCells.length)]
    elsif @dimensions == 2 || @dimensions == 0
      #puts "warping!\n\t#{emptyCells.inspect}"
      until emptyCells.empty?
        cell = emptyCells.delete_at(rand(emptyCells.length))
        if (cell.value == CELL_EMPTY) # && (cell.get(UP) != nil) && (cell.get(DOWN) != nil)
          return cell
        end
      end
    end
    puts "findEmptyCell PANIC: either wrong dimensions or no 2D cell could be found [#{@dimensions}]"
  end

  def addAgent(a=nil)
    a = Agent.new if a == nil
    @agents << a
    a.setSimulation(self)
  end

  def checkNumBricks
    return false if @ignoreBrickLimit
    if @architecture.numBricks >= @brickLimit
      debug "Brick limit of #{@brickLimit} reached, stop?"
      return true
    end
  end

  def runCycle
    #puts "running simulation cycle #{cycle}"
    @agents.each do |agent|
      agent.run
    end
    @cycles += 1
    if checkNumBricks || (@cycles >= @cycleLimit)
      return false
    end
    return true
  end

  def run
    @cycles = 0
    while runCycle do
      #puts "run cycle #{@cycles}"
    end
    puts "Simulation complete: #{@cycles} cycles, #{@architecture.numBricks} bricks"
  end

  def Simulation.createFromArgs(argv)
    return Simulation.create(argv[1], argv[2].to_i,
                             argv[3].to_i, argv[4].to_i)
  end

  def Simulation.create(rulefile, numAgents=5,
                        brickLimit=10, cycleLimit=1000)
    simulation = Simulation.createFromRules(rulefile)
    simulation.ruleFile = rulefile
    simulation.setDimensions(3)
    simulation.brickLimit = brickLimit
    simulation.ignoreBrickLimit = true if brickLimit < 1
    simulation.cycleLimit = cycleLimit
    (numAgents-1).times { simulation.addAgent }
    return simulation
  end

  def Simulation.createFromRules(rulefile)
    rules = ArchitectureCollection.loadRules(rulefile).to_a
    rules.delete_if { |rule| rule.numBricks == 1 }
    s = Simulation.new(Architecture.new(30), rules)
    s.architecture.cc.setValue(CELL_RED)
    s.architecture.cc.expandSpaceAround
    s.addAgent
    s
  end
end

if __FILE__ == $0
  simulation = Simulation.createFromArgs(ARGV)
  simulation.run
  simulation.architecture.save(simulation.ruleFile.slice(0..(simulation.ruleFile.length-7))+"-output.arch")
end