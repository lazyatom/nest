
=begin
each rule contains two architectures:
	1. the match architecture, which is used to match the agent's	current environment.
		this is also the base architecture (which rule inherits)
	2. the apply architecture, which describes the changes to be made to the current
		environment.

=end
class CubicRule < CubicArchitecture

	attr_reader :timesApplied, :buildArch, :rotations
	attr_accessor :probability

	def initialize(xsize, ysize=xsize, zsize=xsize, rots=Cubic::NoRotation)
		super(xsize, ysize, zsize, rots, true)
		@timesApplied = 0
		@probability = 1.0
		@buildArch = CubicArchitecture.new(xsize, ysize, zsize, rots, true)
		@buildArch.fillWith(Cell::Nil)
	end

	def matchArch
		return self
	end

	def code
		bitarrays.compact.collect { |b| b.to_uint }.sort[0]
	end

	def reset()
		@timesApplied = 0
	end

	# Randomises cell values within this architecture. does not set the centre cell.
	def randomise(types=[Cell::Empty, Cell::Red])
		# TODO: control biases
		@cells.each_with_index { |cell, i|
			if (i != ((@cells.length-1)/2))
				@cells[i] = Cell.new(Cell::Empty) if @cells[i] == Cell::EmptyCell
				@cells[i].set(types[random(types.length)])
			else
				@buildArch.cells[i].set(types.last)
			end
		}
	end

	def matches(arch, position=nil)

	# TODO: write probibalistic matches
	# TODO: weight matches depending on distance from centre
		if position == nil
			return super(arch)
		else
			# NOTE: this is the only point where getNeighbourhood is called.
			tmpArch = arch.getNeighbourhoodBitArray(position, @xsize, @ysize, @zsize)
			result = super(tmpArch)
			if result[0] && ((rand(1000).to_f / 1000) < @probability)
				return result
			else
				return [false]
			end
		end
	end

	# -----------------------------------------------------
	# this matches the current rule to a precalculated bitarray. this could
	# be useful for fast checking of many rules on the same neighbourhood
	# NOTE: assumes that all rules will be of the same dimension
	def matchesBitArray(b)
		result = super(b)
		if result[0] && ((rand(1000).to_f / 1000) < @probability)
			return result
		else
			return [false]
		end
	end
	# -----------------------------------------------------


	def apply(arch, pos, rotation=0)
		arch.merge(@buildArch, rotation, pos)
		@timesApplied = @timesApplied + 1
	end

	def to_s
		updateBitArrays()
		buildArch.updateBitArrays()
		"#{self.to_int},#{buildArch.to_int},#{probability}"
	end

	def CubicRule.copy(rule)
		Marshal::load(Marshal.dump(rule))
	end
end
