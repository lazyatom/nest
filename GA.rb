require 'Nest3'
require 'condor'

# MAX_CELLS := the total number of cells in the architecture
# MAX_LINKS := the size of a neighbourhood, 26 in a 3D hexagonal grid
#
# genestring := [startCell,gene-1,gene-2,...,gene-MAX_CELLS - 1]
# gene := [cell_num,link_num]
# cell_num := integer between 0 and MAX_CELLS-1
# link_num := integer between 0 and MAX_LINKS


UNORDERED_CELL = -1

class NestCore::HexCell
  def activeNeighbours
      a = []
      self.allNeighbours { |cell, list|
          a << cell if cell.order == UNORDERED_CELL
      }
      a
  end
end

class Solution

  MaxLinks = 26

  attr_accessor :id, :score, :geneString, :architecture

  def initialize(arch, genes)
    @id = -1
    @score = -1
    @geneString = genes.dup if genes != nil
    @architecture = arch
    @numBricks = @architecture.numBricks
    @geneStringLength = (@numBricks*2)-1
  end

  # creates a random string of genes for this architecture
  def Solution.random(arch)
    Solution.new(arch, nil).randomise
  end

  def randomise
    genes = [rand(@numBricks)] # the start cell ID
    @numBricks.times {
        genes << rand(@numBricks-1)
        genes << rand(MaxLinks)
    }
    @geneString = genes
    return self
  end

  def to_s
    @geneString.id
  end

  # applies the ordering the given solution encodes to to
  # an architecture. if no architecture is given, the stored
  # architecture is used.
  def applyTo(arch)
    startcell = arch.getCell(@geneString.head % @numBricks)
    genes = @geneString.tail

    arch.resetOrdering(UNORDERED_CELL)

    activeCells = [startcell]
    visitedCells = [startcell]
    startcell.setOrder(1)

    limit = @geneStringLength - 1
    index = 0
    while index < limit do
      geneCellIndex = genes[index]
      geneLinkIndex = genes[index+1]
      sourceCell = activeCells[geneCellIndex % activeCells.length]

      potentialCells = sourceCell.activeNeighbours
      nextCell = potentialCells[geneLinkIndex % potentialCells.length]

      activeCells << nextCell
      visitedCells << nextCell

      nextCell.setOrder(visitedCells.length)

      activeCells.delete_if { |cell| cell.activeNeighbours.empty? }

      index += 2 # skip to the next pair.
    end
  end

  def apply
    applyTo(@architecture)
  end

  # mutate a solution. we can modify anything here... so what makes sense.
  # hmm... just add a number to anything. we can add any amount because all
  # of the values in the gene string are used to get remainders.
  def mutate
    geneIndex = rand(@geneStringLength)
    geneString[geneIndex] += 1
  end
end


class GA
  attr_reader :evaluator, :architecture, :population

  def initialize(arch)
    @architecture = arch
    @numBricks = @architecture.numBricks
    @architecture.resetCellIDs
    @population = []
    @geneStringLength = (@numBricks*2)-1
    @evaluator = GAEvaluator.new(@architecture)
    @bestScoreHistory = []

    @scoreHistoryLength = 5
    @threshold = 0
    @populationSize = 15
  end

  def crossover(solutionA, solutionB)
    splitIndex = rand(@geneStringLength)

    # valid splitpoints are odd numbers, since we don't want to
    # break up a single gene. or do we?
    # splitIndex += 1 if (splitIndex % 2) == 0

    newSolutionA = solutionA.geneString[0..(splitIndex-1)] +
                    solutionB.geneString[splitIndex..(@geneStringLength)]
    newSolutionB = solutionB[0..(splitIndex-1)] +
                    solutionA[splitIndex..(@geneStringLength)]

    solutionA.geneString = newSolutionA
    solutionB.geneString = newSolutionB
  end

  def createPopulation(size = @populationSize)
    size.times do
        @population << Solution.random(@architecture)
    end
  end

  def checkForAdequateSolution
    @population.sort { |a,b| a.score <=> b.score }
    # low scores are better
    @bestScoreHistory = (@bestScoreHistory << @population[0].score).sort[0..@scoreHistoryLength]

    # calculate difference of best score from worst.
    #if (@bestScoreHistory[@scoreHistoryLength] - @bestScoreHistory[0]) <= @threshold
    #    return true
    #else
    #    return false
    #end

    total = 0
    @population.each { |solution| total += solution.score }
    average = total / @population.length
    if average - @population[0].score > @threshold
        return false
    else
        return true
    end
  end

  def run
    running = true
    while running do
        createPopulation
        @evaluator.evaluate(@population)
        running = !checkForAdequateSolution
        modifyPopulation if running
    end
    puts "best solution: #{@population[0].score} states"
  end
end


class GAEvaluator
  def initialize(arch)
    @offline = true
    @algorithm = Algorithm.new(arch)
  end

  def evaluate(population)
    population.each do |candidate|
        evaluateCandidate(candidate)
    end
  end

  def evaluateCandidate(candidate)
    if @offline
      puts "evaluating #{candidate.to_s}"
      candidate.applyTo(@algorithm.architecture)
      @algorithm.ISA
      candidate.score = @algorithm.states.length
    end
  end
end


if __FILE__ == $0

  $initialPopulation = 10

  a = Architecture.random(10)
  alg = Algorithm.new(a)

  # create the initial population of candidate orders
  population = []

  $initialPopulation.times do
    c = CandidateOrder.new(a)
    c.order = a.randomValidOrder
    c.fitness = 0
    population << c
  end

  averageFitness = 5000
  bestFitness = 1
  worstFitness = 10000

  idealPairSize = a.numBricks/2

  def stop
    false
  end

  while !stop do

    # evalute the current population
    averageFitness = 0
    population.each do |candidate|
      a.applyOrder(candidate.order)
      alg = Algorithm.new(a)
      candidate.fitness = alg.states.length
      bestFitness = [bestFitness, candidate.fitness].max
      worstFitness = [worstFitness, candidate.fitness].min
      averageFitness += candidate.fitness
    end
    averageFitness /= population.length

    # sort the population according to fitness
    population.sort! { |x,y| x.fitness <=> y.fitness }

    # breed each of the top half with a random one
    babies = []
    winnerIndexes = ((population.length/2)..(population.length-1)).to_a
    while !winnerIndexes.empty? do
      index = winnerIndexes.pop
      winner = population[index]
      mate = population[rand(index)] # pick a random candidate that hasn't been mated

      pairs = LHP(winner.order, mate.order)

      # pick a pair... choose the one sized closest to half the order size i guess...
      pairSizes == pairs.collect { |pair| pair[0][1] - pair[0][0] + 1 }
      selectedPairIndex = nil
      idealPairSize.downto(2) do |size|
        selectedPairIndex = pairSizes.index(size)
        break if selectedPairIndex != nil
      end
      if selectedPairIndex == nil
        nil # no crossover!?
      else
        # do the crossover
        selectedPair = pairs[selectedPairIndex]
        winnerIndex = selectedPair[0][0]
        mateIndex = selectedPair[1][0]
        winnerSubOrder = winner.order[winnerIndex, selectedPair[0][1]-winnerIndex]
        mateSubOrder = mate.order[mateIndex, selectedPair[1][1]-mateIndex]

        winner.crossover(winnerIndex, mateSubOrder)
        mate.crossover(mateIndex, winnerSubOrder)
      end
    end
  end

  a.applyOrder(population[0].order)
  alg = Algorithm.new(a)
  alg.save("output.rules")
  a.save("column.ordered.arch")

  s = Simulation.createFromRules("output.rules")
  s.run(1000,20,10)
  s.architecture.save("output.arch")
end