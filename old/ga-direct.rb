require 'Nest3'

# Basic Algorithm

def piAB(i, a, b) # this is the index from B which holds the element
            # at index i in A
	
	x = nil
	b.length.times { |x|
		return x if b[x] == a[i]
	}
	# ERROR!
end


def l(x, y, a, b) # this is the minimum value of piAB over x <= i <= y
	(x..y).to_a.collect { |i| piAB(i,a,b) }.min
end


def u(x, y, a, b) # this is the maximum value of piAB over x <= i <= y
  (x..y).to_a.collect { |i| piAB(i,a,b) }.max
end

def f(x, y, a, b)
	u(x, y, a, b) - l(x, y, a, b) - (y - x)
end


def BSC(a,b)
	result = []
	(0..(a.length-2)).each { |x|
		((x+1)..(a.length-1)).each { |y|
			#puts x.to_s + "," + y.to_s
			if f(x,y,a,b) == 0
				result << [[x,y],[l(x,y,a,b),u(x,y,a,b)]]
			end
		}
	}
	
	# strip out the 'whole series' match
	result.delete_if { |pair| pair[0][0] == 0 && pair[0][1] == (a.length-1) }

	result
end


def LHP(a,b)
	result = []
	(0..(a.length-2)).each { |x|
		((x+1)..([a.length-1,x+a.length-4].min)).each { |y|
			#puts x.to_s + "," + y.to_s
			if f(x,y,a,b) == 0
				result << [[x,y],[l(x,y,a,b),u(x,y,a,b)]]
			end
		}
	}
	
	# strip out the 'whole series' match
	result.delete_if { |pair| pair[0][0] == 0 && pair[0][1] == (a.length-1) }

	result
end


def test(a,b)
	t, t2 = 0,0
	t = Time.new
	BSC(a,b)
	t2 = Time.new
	puts "BCS = #{t2 - t}"
	t = Time.new
	LHP(a,b)
	t2 = Time.new
	puts "LHP = #{t2-t}"
end

def testsize(n)
	a = (0..n).to_a.shuffle
	b = (0..n).to_a.shuffle
	test(a,b)
end

class CandidateOrder

	attr_accessor :order, :fitness, :architecture

	def initialize(arch)
		@architecture = arch
	end

	def to_s
		@order.to_s + " : " + @fitness.to_s
	end
	
	
	# this method replaces part of one order with another one
	# if both orders were valid, 
	def insertAt(index, newSubOrder)
		newSubOrder.each_with_index { |element, i|
			@order[index+i] = element
		}

		# make the order valid
		# first check that all elements are present
		allElements = (0..@order.length).to_a - @order
		if !allElements.empty?
			@order |= allElements
		end
		errorBrick, errorIndex = @architecture.orderErrorBrick(@order)
		while errorBrick != nil do
			# here we've got a number of options.
			
			
			
		end
	end

	def orderErrorBrick
		@architecture.orderErrorBrick(@order)
	end

	def insertAtEnd(index, newSubOrder)
		@order.fill(nil, index, newSubOrder.length).compact!
		@order << newSubOrder
		@order.flatten!
	end

	def crossover(index, newSubOrder)
		insertAtEnd(index, newSubOrder)
	end

	def valid?
		@architecture.validOrder?(@order)
	end	
end






if __FILE__ == $0

$initialPopulation = 10

a = Architecture.random(10)
alg = Algorithm.new(a)

# create the initial population of candidate orders
population = []

$initialPopulation.times {
	c = CandidateOrder.new(a)
	c.order = a.randomValidOrder
	c.fitness = 0
	population << c
}


averageFitness = 5000
bestFitness = 1
worstFitness = 10000

idealPairSize = a.numBricks/2


def stop()
	false
end

while !stop() do

	# evalute the current population
	averageFitness = 0
	population.each { |candidate|
		a.applyOrder(candidate.order)
		alg = Algorithm.new(a)
		candidate.fitness = alg.states.length
		bestFitness = [bestFitness, candidate.fitness].max
		worstFitness = [worstFitness, candidate.fitness].min
		averageFitness += candidate.fitness
	}
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
		idealPairSize.downto(2) { |size|
			selectedPairIndex = pairSizes.index(size)
			break if selectedPairIndex != nil			
		}
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