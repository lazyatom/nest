# Describes a position within a CubicArchitecture.
# Position objects are needed to give a universal interface between the simulation and
# the different Architecture implementations it could use. This was one fo the big
# problems in the original simulation...
class CubicPosition < Position

	# Returns a new random position within a given CubicArchitecture
	def CubicPosition.randomPosition(arch)
		pos = CubicPosition.new()
		pos.moveRandomly(arch, Position::MoveWarping)
		return pos
	end

	# allow us to read the coordinates of this position
	attr_reader :x, :y, :z

	# Creates a new CubicPosition, with default coordinates of (0,0,0)
	def initialize(x=0, y=0, z=0)
		set(x, y, z)
	end

	# Sets the coordinates for this CubicPosition, with default coordinates of (0,0,0)
	def set(x=0, y=0, z=0)
		@x = (x<0)?0:x
		@y = (y<0)?0:y
		@z = (z<0)?0:z
	end

	# Returns a  String representing this CubicPosition
	def to_s
		return "[#{x},#{y},#{z}]"
	end

	# returns an array with the coordinates in them
	def to_a
		return [@x, @y, @z]
	end


	# This class-shared Array is used to quickly create random coordinates
	# these are a speedup because they don't have to be created each time
	@@coords = Array.new(3).collect { 0 }
	@@current = []
	@@i = nil
	@@ok = false

	# moves this position's coordinates somewhere unoccupied within the architecture.
	# TODO: might want to consider a bounding box too
	# NOTE: potential performance bottleneck. any speedups are an advantage.
	def moveRandomly(arch, type)

		@@i, @@ok = nil, false # reset variables
		@@current = [@x, @y, @z]

		until @@ok
			arch.sizes.length.times { |i|
				if arch.sizes[i] == 1
					@@coords[i] == 0
				else
					case type
						when Position::MoveWarping
							@@coords[i] = random(arch.sizes[i])
							#puts "got my ass a random: #{@@coords[i]}"
						when Position::MoveAdjacent
							@@coords[i] = @@current[i] + (random(3)-1) # -1,0, or 1
					end
						@@coords[i] = arch.boundingBox[i][1] if @@coords[i] >= arch.boundingBox[i][1]
						@@coords[i] = arch.boundingBox[i][0] if @@coords[i] < arch.boundingBox[i][0]
				end
			}
			#puts "checking #{@@coords.inspect}, bounding box = #{arch.boundingBox.inspect}"
			# this next bit basically checks that the coordinates are in range, and that the cell is unoccupied
			@@ok = ((cell = arch.getCoords(@@coords[0], @@coords[1], @@coords[2])) != nil) &&
					cell.isEmpty?
		end

		# assign it to our position
		@x, @y, @z = @@coords
	end
end
