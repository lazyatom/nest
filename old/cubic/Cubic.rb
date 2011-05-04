require 'Position'
require 'Architecture'
require 'Rule'

# The Cubic module handles non-instance Cubic stuff, such as generating rotation matricies
module Cubic

	# These module constants define the specific architecture, rule and position types
	# for Cubic simulations.
	# Module constants such as this are accessible through <modulename>::<constant>,
	# e.g. Cubic::RuleType, Cubic::AllRotations (see below), etc etc
	ArchitectureType = CubicArchitecture
	PositionType = CubicPosition
	RuleType = CubicRule


	# the following indexes are used to refer to the 24 possible rotations of a 3D cube.
	# These indexes are used in the rotation matrix system, which is described below
	#  0: <no rotation>
	#  1: x
	#  2: xy
	#  3: xyy
	#  4: xyyy
	#  5: xx
	#  6: xxy
	#  7: xxyy
	#  8: xxyyy
	#  9: xxx
	# 10: xxxy
	# 11: xxxyy
	# 12: xxxyyy
	# 13: y
	# 14: yy
	# 15: yyy
	# 16: z
	# 17: zx
	# 18; zxx
	# 19: zxxx
	# 20: zzz
	# 21: zzzx
	# 22: zzzxx
	# 23: zzzxxx

	# these should hold the rotationMatricies indexes of all relevant rotations for each constraint.
	NoRotation = [0]

	# TODO: those rotations enabled by the removal of gravity
	NoGravity = [0]  # fix this

	# those rotations useful for an internal compass, and also the only permissible
	# rotations for 2D
	# all rotations around z axis
	# - = 0
	# z = 16
	# zz = xxyy [= yyxx] = 7
	# zzz = 20
	InternalCompass = [0,20,7,16]

	# These define the valid rotations for 2D architectures
	ZRotations = [0,20,7,16] # same as InternalCompass
	YRotations = [0,13,14,15]
	XRotations = [0,1,5,9]

	# all allowable rotations
	AllRotations = Array.new(24)
	# this basically sets each element of the array to the value of it's psition, giving
	# [0,1,2,3,4,5,....,23]
	AllRotations.each_index { |x| AllRotations[x] = x }


	# ------------------------- DEFAULT PARAMETERS --------------------------------

	# the default simulation parameters for a new Cubic Simulation. The SimulationParameters
	# object and system are described in Nest.rb
	DefaultParameters = SimulationParameters.new(nil, false)
	DefaultParameters["name"] = "newCubicSimulation"
	DefaultParameters["type"] = Cubic
	DefaultParameters["architecture"] = "10,10,1,empty"
	DefaultParameters["rule.dimensions"] = "3,3,1,#{ZRotations.inspect}"  # inspect produces a string representation of an array
	DefaultParameters["agents.number"] = 0
	DefaultParameters["agents.movement"] = Position::MoveWarping
	DefaultParameters["cycles.limit"]  = 1
	DefaultParameters["bricks.limit"] = 100

	# generate the temporary helper parameters
	DefaultParameters.loadRuleDimensions
	DefaultParameters.loadArchitectureDimensions



	# creates an array of CubicRules from a SimulationParameter object.
	# The format for Rule lines should be <match_arch_code>,<build_arch_code>,<probability>
	def Cubic.createRules(params)
		x, y, z, rots = params["rule.xsize"], params["rule.ysize"], params["rule.zsize"], params["rule.rotations"]
		ruleArray = []
		lines = params["rule.array"]

		for line in lines
			line =~ /(\d+),(\d+),(\d\.\d+)/
			match, build, prob = $1.to_i, $2.to_i, $3.to_f
			rule = RuleType.new(x, y, z, rots)
			rule.setFromInt(match)
			rule.buildArch.setFromInt(build)
			rule.updateBitArrays
			rule.buildArch.updateBitArrays
			rule.probability = prob
			rule.refreshCellCoords
			rule.buildArch.refreshCellCoords
			ruleArray << rule
		end

		return ruleArray
	end

	# Creates an architecture from a SimulationParameter object.
	# The format for the architecture line should be: <xsize>,<ysize>,<zsize>,<architecture_code>
	# but params.loadArchitectureDimensions will extract the information into it's components
	def Cubic.createArchitecture(params)
		x, y, z, code = params["architecture.xsize"], params["architecture.ysize"], params["architecture.zsize"], params["architecture.code"]
		a = ArchitectureType.new(x, y, z, NoRotation, false, true)
		if code == nil
			a.clear
		else
			a.setFromInt(code)
		end
		return a
	end



	# ------------------------- ROTATION STUFF --------------------------------

	# the cache for rotation matricies (see below). each element of this array will hold
	# 24 arrays in itself (one for each rotation of this particular size)
	@@rotationMatricies = [] # a new array

	# Returns a rotation matrix for Cubic architectures of a given size.
	# Generated matricies are cached so they are only calculated once.
	# Rotations are indexed as above.
	#
	# Explanation:
	# the rotation matricies simply hold indexes to the new position of a cell within a rotated architecture.
	# for instance, in the 'x' rotation matrix, element 0 holds the new index of element 0 in the rotated
	# architecture.
	def Cubic.getRotationMatrix(size)
		d "getting rotation matrix for cubic architecture of size #{size}"
		if @@rotationMatricies[size] != nil
			d "--> returning cached version!"
			return @@rotationMatricies[size]
		else
			d "--> generating new matrix..."

			# assume that the architectures will be 3D. this still works for 2D architectures, but certain
			# rotations (i.e. rotating aruond the x axis for an x-y planar architecture) will be invalid.
			matrixSize = size**3

			# create the 24 arrays for matricies of this size
			@@rotationMatricies[size] = Array.new(24).collect! {
				Array.new(matrixSize)
			}
			rotationMatrix = @@rotationMatricies[size]
			# rotationMatrix is now ready to hold our array of different rotational indexes

			# intializing the variables speeds things up slightly
			x = 0
			i = nil

			# the first one is not rotated
			matrixSize.times { |i| rotationMatrix[x][i] = i }; x = x+1 # -

			# create the rotation matricies. to speed this up, previously calculated rotations are used to incrementally
			# generate new ones. for instance, the rotation 'xx' (rotate around x axis twice) is created by rotating
			# the matrix already generated for 'x'.
			matrixSize.times { |i| rotationMatrix[x][i] = rotx(rotationMatrix[x-1][i], size) }; x = x+1 # x
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1 # xy
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1 # xyy
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1 # xyyy

			matrixSize.times { |i| rotationMatrix[x][i] = rotx(rotationMatrix[x-4][i], size) }; x = x+1  # xx
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1  # xxy
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1  # xxyy
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1  # xxyyy

			matrixSize.times { |i| rotationMatrix[x][i] = rotx(rotationMatrix[x-4][i], size) }; x = x+1  # xxx
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1  # xxxy
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1  # xxxyy
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1  # xxxyyy

			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[0][i], size) }; x = x+1  # y
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1  # yy
			matrixSize.times { |i| rotationMatrix[x][i] = roty(rotationMatrix[x-1][i], size) }; x = x+1  # yyy

			matrixSize.times { |i| rotationMatrix[x][i] = rotz(rotationMatrix[0][i], size) }; x = x+1  # z
			matrixSize.times { |i| rotationMatrix[x][i] = rotx(rotationMatrix[x-1][i], size) }; x = x+1  # zx
			matrixSize.times { |i| rotationMatrix[x][i] = rotx(rotationMatrix[x-1][i], size) }; x = x+1  # zxx
			matrixSize.times { |i| rotationMatrix[x][i] = rotx(rotationMatrix[x-1][i], size) }; x = x+1  # zxxx

			matrixSize.times { |i| rotationMatrix[x][i] = rotz(rotz(rotationMatrix[x-4][i], size), size) }; x = x+1  # zzz
			matrixSize.times { |i| rotationMatrix[x][i] = rotx(rotationMatrix[x-1][i], size) }; x = x+1  # zzzx
			matrixSize.times { |i| rotationMatrix[x][i] = rotx(rotationMatrix[x-1][i], size) }; x = x+1  # zzzxx
			matrixSize.times { |i| rotationMatrix[x][i] = rotx(rotationMatrix[x-1][i], size) }; x = x+1  # zzzxxx

			return rotationMatrix
		end
	end

	# returns the new index of element x when it is rotated around the X axis in an architecture
	# of size s
	def Cubic.rotx(x, s)
		(((x/s)%s)+1)*(s**2) - ((x/(s**2))+1)*s + (x%s)
	end

	# returns the new index of element x when it is rotated around the Y axis in an architecture
	# of size s
	def Cubic.rotz(x, s)
		a = (x+1)%s
		a = s if a == 0
		return s*a - (x%(s**2))/s + (s**2)*(x/(s**2)) - 1
	end

	# returns the new index of element x when it is rotated around the Z axis in an architecture
	# of size s
	def Cubic.roty(x, s)
		(x%s)*(s**2) + (((x/s)%s)+1)*s - ((x/(s**2)) + 1)
	end



	#
	# A crude attempt at loading Nest 2.1 .rul files. Requires much work.
	#
	def Cubic.convertVal(val)
		if val.to_i == 0
			p "converting #{val} to Empty"
			return Cell::Empty
		elsif val.to_i == 1
			p "converting #{val} to Red"
			return Cell::Red
		end
	end
	def Cubic.loadRulesFrom2(filename)
		ruleMatcher = /(\d) (\d) (\d) (\d) (\d) (\d) (\d) (\d) (\d)/
		ruleArray = []

		File.open(filename, "r") do |file|

			lines = file.entries
			# read name
			#name = lines[0]
			# read type

			# read fitness
			#fitness = lines[2]

			# grab all rules
			x = 3
			while (lines[x] != nil) do
				rule = CubicRule.new(3)
				rule.probability = lines[x].match(/\d+\.\d+/)[0].to_f
				x = x + 1
				offset = 0
				3.times {
					md = lines[x].match(ruleMatcher)
					rule[0+offset].set(convertVal(md[8]))
					rule[1+offset].set(convertVal(md[1]))
					rule[2+offset].set(convertVal(md[2]))
					rule[3+offset].set(convertVal(md[7]))
					rule[4+offset].set(convertVal(md[9]))
					rule[5+offset].set(convertVal(md[3]))
					rule[6+offset].set(convertVal(md[6]))
					rule[7+offset].set(convertVal(md[5]))
					rule[8+offset].set(convertVal(md[4]))
					p "loaded: #{rule[0+offset].value} #{rule[1+offset].value} #{rule[2+offset].value} #{rule[3+offset].value} #{rule[4+offset].value} #{rule[5+offset].value} #{rule[6+offset].value} #{rule[7+offset].value} #{rule[8+offset].value}"
					x = x + 1
					offset = offset + 9
				}
				ruleArray << rule
			end
		end

		return ruleArray
	end
end



=begin
 this might work for caching generated bitarray stuff - need to find a good way to update
 the dependant cells though. also doesn't work well with singleton Cell::EmptyCell solution

 it is currently disabled.
=end
$caching = false
class Cell
	def getNeighbourhoodBitArray
		$caching?@neighbourhood:nil
	end
	def setNeighbourhoodBitArray(b)
		if $caching
			@neighbourhood = b
		end
	end
end