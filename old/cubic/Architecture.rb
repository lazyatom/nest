require 'bitvector'

# Implements the Architecture class for Cubic simulations. An Architecture represents some arrangement
# of Cells, and is the basis for both the agents construction and the Rules (see CubicRule) which the agents
# use.
class CubicArchitecture

	# the attributes of this objcet which are visible (i.e. public)
	attr_reader :cells, :cellCoords, :bitarrays, :rotationMatrix
	attr_reader :xsize, :ysize, :zsize, :sizes, :rotations
	attr_reader :boundingBox, :bitArraysEnabled, :useBoundingBox

	# this attribute is also assignable.
	# TODO: allow setting simulation names. this is just candy though.
	attr_accessor :name


	# Creates a new Architecture with the given sizes and available rotations
	# [xsize] the size of the architecture along the x-axis
	# [ysize] the size of the architecture along the y-axis
	# [zsize] the size of the architecture along the z-axis
	# [rots] an Array of rotation matrix indices (see Cubic::getRotationMatrix)
	# [bitArraysOn] a flag to enable/disable the generation of bitarrays.
	def initialize(xsize, ysize=xsize, zsize=xsize, rots=Cubic::NoRotation, bitArraysOn=true, boundingBox=false)
		if (xsize < 1) || (ysize < 1) || (zsize < 1)
			# throw an error
			raise DimensionException, "Zero or Negative dimension given for Architecture", caller
		end

		# d is a debug function - if $debug == true, it will print the string it's given
		d "creating new architecture with size [#{xsize},#{ysize},#{zsize}]"

		# assign the parameters to instance variables
		@xsize, @ysize, @zsize = xsize, ysize, zsize
		@sizes = [@xsize, @ysize, @zsize] # This is used by CubicPosition quickly generate positions

		# Restrict the rotations available, given the architecture sizes.
		# NOTE: this will not work for 1D architectures, but do we ever want (or want to rotate) a 1D architecture?
		# TODO: there may be issues here with rotating non-cube 3D architecture (3x3x2) for instance. can 4x3x2 be rotated meaningfully?
		if (@xsize == 1) && (@ysize > 1) && (@zsize > 1)
			@validRotations = Cubic::XRotations
		elsif (@xsize > 1) && (@ysize == 1) && (@zsize > 1)
			@validRotations = Cubic::YRotations
		elsif (@xsize > 1) && (@ysize > 1) && (@zsize == 1)
			@validRotations = Cubic::ZRotations
		else
			@validRotations = Cubic::AllRotations
		end

		# @cellCoords holds references to cells which hold bricks. This is used to quickly draw
		# the architecture, and also generate totals for how many bricks there are.
		# TODO: There may be a better way to do this... Architecture shouldn't care about about
		# drawing, and maybe a similar array can be quickly generated on the fly...
		@cellCoords = []

		# @cells is an array which holds all the cells in this architecture
		@cells = Array.new(@xsize*@ysize*@zsize)

		# if bitarrays are enabled, then this architecture can be rotated and compared quickly to others.
		# the advantage to disabling the bitarrays is that whenever a cell is changed, all of the
		# bitarrays must be recalculated. In general, constructon architectures should have bitarrays
		# disabled while they are being built. Rules, which do not change during the simulation (although
		# in theory there is no reason why they can't) should have bitarrays enabled so they can be
		# rotated and compared ultra-fast.
		@bitArraysEnabled = bitArraysOn

		# assigns the valid rotations for this architecture (i.e. NoRotation, XRotation, AllRotations)
		setRotations(rots)

		# fill this architecture with empty (i.e. Cell::EmptyCell) cells
		clear()

		# initialise the bounding box, which restricts movement within this architecture
		# obviously this only makes sense for the construction architecture. Actually, to keep things
		# simple the bounding box is ALWAYS used, but when it is disabled it is set to the limits
		# of the architecture and updates are skipped
		@useBoundingBox = boundingBox
		initBoundingBox()
	end


	# Fills this architecture with cells as defined by the given architecture code.
	# The code should be an unsigned integer, which can be extracted from an existing architecture
	# by calling arch.to_int
	def setFromInt(int)
		d "infusing architecture with int: #{int}"

		if int == 0 # special case: BitVector doesn't like '0'
			fillWith(Cell::Nil)
		else
			# ----##############################------
			# !!!         TODO: simulations using differnt/more colours....         !!!
			tempBitArray = BitVector.new_from_int(int, @xsize*@ysize*@zsize*Cell::NumTypes)
			# ----##############################------

			size = @xsize*@ysize*@zsize*Cell::NumTypes
			d "size: #{Cell::NumTypes}, #{size}"
			tempBitArray.resize(size)
			c = size / Cell::NumTypes
			c.times { |x| @cells[x] = Cell.new(tempBitArray.chunk_read(Cell::NumTypes, x*Cell::NumTypes)) }
			if @bitArraysEnabled
				@bitarrays[0] = tempBitArray
				updateBitArrays() #recalculate all of the rotated bitarrays
			end
		end

		# update the cellCoords array
		refreshCellCoords()

		initBoundingBox()
		updateBoundingBox()
		return self
	end

	def to_int
		if @bitArraysEnabled
			@bitarrays[0].to_uint
		else
			toBitArray().to_uint
		end
	end

	# Sets the available rotations for use when comparing this architecture to other architectures.
	def setRotations(rots)
		@rotations = rots & @validRotations # set union
		d "getting rotation matricies..."
		@rotationMatrix = (rotationEnabled())?(Cubic::getRotationMatrix(@xsize)):(nil)
		updateBitArrays()
	end

	# Returns true if any rotations (other that the '0' rotation) have been enabled
	def rotationEnabled
		return @rotations != [0]
	end

	def indexOf(x, y, z)
		x+(y*@xsize)+(z*@xsize*@ysize)
	end

	def positionOf(i)
		z = i/(@xsize*@ysize) # get the 'z' coordinates
		i2 = i-z*(@xsize*@ysize)
		y = i2/@xsize # get 'y' coordinates
		x = i2-y*@xsize
		CubicPosition.new(x,y,z)
	end

	# returns a cell within the architecture according to index and rotation. e.g. arch[0] returns cell
	# index 0. arch[0,7] returns the cell at index 0 for rotation 7 (xxyy)
	# [index] the index of the cell to return (position as identified by the 0-rotation)
	# [rotation] the rotation number to be used
	def [](index, rotation=0)
		return @cells[rotationEnabled()?@rotationMatrix[rotation][index]:index]
	end

	# Sets the value of a cell given by the position specified by the CubicPosition object
	def set(cubicPos, value)
		setCoords(cubicPos.x, cubicPos.y, cubicPos.z, value)
	end

	def checkCoords(x, y, z)
		if (x < 0) || (y < 0) || (z < 0)
			raise DimensionException, "Negative coordinates [#{x},#{y},#{z}] given to setCoords", caller
		end
		if (x >= @xsize) || (y >= @ysize) || (z >= @zsize)
			raise DimensionException, "Coordinates greater than architecture size [#{x},#{y},#{z}] given to setCoords", caller
		end
	end

	# Sets the value of a cell given by coordinates
	def setCoords(x, y, z, value)
		checkCoords(x,y,z)
		# TODO: possibly only allow access via positions.

		# generate the index of the cell within the @cells array
		index = indexOf(x,y,z)

		d "setting #{x},#{y},#{z} [#{index},id=#{@cells[index].id}] to #{value}"

		# store the original value of this cell (needed to determine if @cellCoords is 'dirty')
		prevValue = @cells[index].value
		# create a new cell if needed
		@cells[index] = Cell.new(Cell::Empty, index) if @cells[index] == Cell::EmptyCell
		# set the cell
		@cells[index].set(value)

		if (@cells[index].isEmpty?) # NOTE: it's very important that the cell is REALLY empty - i.e. no pheromones
			d "deleting empty cell...."
			@cellCoords.delete_if { |cell, x, y, z| cell.id == @cells[index].id } # remove it from our list
			@cells[index] = Cell::EmptyCell # replace the object
		elsif prevValue == Cell::Empty
			@cellCoords |= [[@cells[index], x, y, z]] # add it to our list
		end
		# NOTE: that bit of code is quite ugly. might have to change it if there is a better way to deal with
		# @cellCoords

		updateBoundingBox([x,y,z])

		# finally, update all the bitarrays.
		updateBitArrays()

		bricks #return new number of bricks
	end

	# updates the bounding box given an array of coordinates, or reconstructs it from scratch if
	# given 'nil'
	# not that this bounding box assues rules of size 3x3. in general the bounding box must be
	# <max_rule_size> beyond each cell. rationale:
	#	- if simple, 'construct in centre' rules, the offset will be (<max_rule_size>/2)
	#	- if some rule m
	#
	@offset = nil

	# create the boundingBox array - [[xmin, xmax],[ymin, ymax],[zmin, zmax]]
	# set boundingBox to nil to disable this
	# situations where a bounding box might not be wanted:
	# - rule architectures
	def initBoundingBox(rules=nil)
		# create the boundingBox array
		@boundingBox = Array.new(3).collect! { Array.new(2) }

		# update the bounding box
		if @useBoundingBox && self.bricks > 0
			# calculate the offset and create the the bounding box
			#puts "setting bb to inverted limits"
			@offset = 1 # this should reflect the nature of the rules
			3.times { |i|
				if @sizes[i] == 1
					@boundingBox[i][0] = @boundingBox[i][1] = 0
				else
					@boundingBox[i][0] = @sizes[i]
					@boundingBox[i][1] = 0
				end
			}
			updateBoundingBox(nil)
		else
			# set the bounding box to the limits of this architecture
			@offset = 1
			#puts "setting bb to limits"
			3.times { |i|
				if @sizes[i] == 1
					@boundingBox[i][0] = @boundingBox[i][1] = 0
				else
					@boundingBox[i][0] = 0
					@boundingBox[i][1] = @sizes[i]
				end
			}
		end
	end

	def updateBoundingBox(coords=nil)
		if @useBoundingBox
			 d"current box: #{@boundingBox.inspect} - coords #{coords.inspect}"
			if coords != nil
				coords.each_with_index { |c, i|
					if @sizes[i] == 1
						@boundingBox[i][0] = @boundingBox[i][1] = 0
					else
						@boundingBox[i][0] = ((c-@offset)<0)?0:(c-@offset) if c <= @boundingBox[i][0]
						@boundingBox[i][1] = ((c+@offset)>=@sizes[i])?@sizes[i]:(c+@offset) if c >= @boundingBox[i][1]
					end
				}
			else
				# if coords is nil, we assume that the bounding box must be calculated from scratch again
				3.times { |i|
					if @sizes[i] == 1
						@boundingBox[i][0] = @boundingBox[i][1] = 0
					else
						@boundingBox[i][0] = @sizes[i]
						@boundingBox[i][1] = 0
					end
				}

				@xsize.times { |x|
					@ysize.times { |y|
						@zsize.times { |z|
							updateBoundingBox([x,y,z]) if !getCoords(x,y,z).isEmpty?
						}
					}
				}
			end
			d "bounding box now: #{@boundingBox.inspect}"
		end
	end

	# recalculates the contents of @cellCoords
	def refreshCellCoords
		@cellCoords.clear
		neighbourhood(CubicPosition.new(@xsize/2, @ysize/2, @zsize/2), @xsize, @ysize, @zsize) { |x,y,z,i|
			@cellCoords << [@cells[i], x, y, z] if !@cells[i].isEmpty?
		} # neighbourhood() is defined below...
	end

	# Returns the number of bricks in this architecture (actually just the size of @cellCoords)
	def bricks
		@cellCoords.length
	end

	# Fills the whole architecture with bricks of a given type
	def fillWith(type)
		if type == Cell::Empty
			@cells.collect! { Cell::EmptyCell } # see Nest.rb [Cell::EmptyCell]
		else
			@cells.collect! { Cell.new(type) }
		end
		refreshCellCoords()
		updateBitArrays()
		return self
	end

	# Sets all cells within the architecture to Cell::Empty
	def clear()
		fillWith(Cell::Empty)
	end

	# Sets Cell::id appropriately for all cells.
	# TODO: this was a debug thing, can it be removed?
	def testFill
		@cells.length.times { |x|
			@cells[x].id = x
		}
	end

	# Randomises cell values within this architecture. unimplemented.
	def randomise(types)
		# TODO: control biases
		@cells.each_with_index { |cell, i|
			@cells[i] = Cell.new(Cell::Empty) if @cells[i] == Cell::EmptyCell
			@cells[i].set(types[random(types.length)])
		}
	end

	# returns [true, <rot>] when this architecture matches the given one, where <rot> = the rotation of this architecture which matches
	# returns [false] otherwise
	def matches(arch)

		if arch.kind_of? CubicArchitecture
			return [false] if arch.sizes != sizes # sizes have to match
			archBits = arch.toBitArray
		elsif arch.kind_of? BitVector
			archBits = arch
		end

		return matchesBitArray(archBits)
	end

	def matchesBitArray(b)
		#rotate THIS architecture to see if it matches the given one
		#d "comparing from available rotations: #{@rotations}"
		for rot in @rotations
			#d "comparing rot #{rot} [#{@bitarrays[rot].value}] with #{archBits.value}"
			# TODO: is it faster to just do teh '&' twice, or store in in a variable (necesitating the
			# creation of that variable....)?
			if ((@bitarrays[rot] & b) == b) || ((@bitarrays[rot] & b) == @bitarrays[rot])
				return [true, rot]
			end
		end
		return [false]
	end

	# Merges the cells within the given architecture (filtered through the given rotation) into this architecture, at the given position
	# (Merging of individual cells is defined in Nest::Cell)
	def merge(arch, rotation, pos)
		d "merging #{arch} at #{pos}"

		# get the center postion of the architecture
		xs = pos.x - (arch.xsize/2)
		ys = pos.y - (arch.ysize/2)
		zs = pos.z - (arch.zsize/2)

		# preinitialize variables (speedup hack)
		x = y = z = xi = yi = zi = index = prevValue = nil

		neighbourhood(pos, arch.xsize, arch.ysize, arch.zsize) { |x,y,z,index,a,b,c|

			if @cells[index] != nil  # this caters for outside of boundary matching
				prevValue = @cells[index].value
				# create a new cell if needed
				@cells[index] = Cell.new(Cell::Empty, index) if @cells[index] == Cell::EmptyCell
				# set the cell
				d "in merge, trying to merge #{x},#{y},#{z} with #{a},#{b},#{c} [#{arch.getCoords(a,b,c,rotation)}]"
				@cells[index].mergeWith(arch.getCoords(a,b,c, rotation))

				# update the bounding box
				updateBoundingBox([x,y,z])

				# This is a remnant of the per-cell bitarray caching.
				# TODO: delete this
				#@cells[index].setNeighbourhoodBitArray(nil)

				if (@cells[index].isEmpty?) # NOTE: it's very important that the cell is REALLY empty - i.e. no pheromones
					@cellCoords.delete_if { |cell| cell[0].id == @cells[index].id } # remove it from our list
					#@cells[index] = Cell::EmptyCell # replace the object
				elsif prevValue == Cell::Empty
					@cellCoords |= [[@cells[index], x, y, z]] # add it to our list
				end
			end
		}

		updateBitArrays()
	end

	# Updates the BitArray array for this Architecture
	def updateBitArrays()
		if @bitArraysEnabled
			# set appropriate bits in all ACTIVE rotation bitarrays
			@bitarrays = [] if @bitarrays == nil # create the bitarrays array if it doesn't already exist
			x = nil
			for x in @rotations
				@bitarrays[x] = toBitArray(x)
				d "updating bitarrays[#{x}] to #{@bitarrays[x].to_uint}"
			end
		end
	end

	# Returns a BitArray representing this Architecture (with the given rotation)
	def toBitArray(rotation=0)
		bitarray = BitVector.new(Cell::NumTypes*@xsize*@ysize*@zsize)
		x = nil
		@cells.length.times { |x|
			cell = self[x, rotation]
			bitarray.chunk_store(Cell::NumTypes, x*Cell::NumTypes, (cell)?(cell.bytes):(Cell::Empty))
		}
		return bitarray
	end

	# Returns the Cell at the given position (of the given rotation, if any)
	def get(pos, rotation=0)
		#d "getting #{cubicPos.to_s}"
		getCoords(pos.x, pos.y, pos.z, rotation)
	end


	# Returns the cell at the given coordinates (and the given rotation, if any)
	def getCoords(x, y, z, rotation=0)
		#d "getting #{cubicPos.to_s}"
		checkCoords(x,y,z)
		return self[indexOf(x,y,z), rotation]
	end

	def centerCell(x,y,z)
		(x == @xsize/2) && (y == @ysize/2) && (z == @zsize/2)
	end

	def centerCellPosition
		CubicPosition.new(@xsize/2, @ysize/2, @zsize/2)
	end

	# Returns a BitArray representing a neighbourhood within the architecture
	# [pos] the CubicPosition indicating the centre of the neighbourhood
	# [xd] the size of neighbourhood along the x-axis
	# [yd] the size of neighbourhood along the y-axis
	# [zd] the size of neighbourhood along the z-axis
	# [defaultType]  the type used to populate cells which are 'out-of-bounds'
	def getNeighbourhoodBitArray(pos, xd, yd, zd, defaultType=Cell::Empty)
		#TODO: caching - plus some smart way of updating the caches...
		# neighbourhoods are as large as the biggest rule in operation
		# NOTE: this assumes that all rules are the same size.
		#~ b = getCachedNeighbourhoodBitArray(pos)
		#d "tried to get cached version: #{b}"

		#~ if b == nil

			b = BitVector.new(Cell::NumTypes*xd*yd*zd)
			index = 0

			x = y = z = i = nil # these are used to cache added coordinates
			cell = nil

			neighbourhood(pos, xd, yd, zd) { |x, y, z, i|
				d "considering cell #{x},#{y},#{z}"
				# if this neighbourhood extends beyond the edge, we fill nil cells with 'empty'
				#
				# TODO: this could be replaced with getCoords/checkCoords
				#
				if (x < 0) || (y < 0) || (z < 0) ||
					(x >= @xsize) || (y >= @ysize) || (z >= @zsize)
					d "some coord < 0 - setting empty."
					b.chunk_store(Cell::NumTypes, index*Cell::NumTypes, Cell::Empty)
				else
					cell = getCoords(x,y,z)
					b.chunk_store(Cell::NumTypes, index*Cell::NumTypes, (cell == nil)?(Cell::Empty):(cell.bytes))
				end
				index += 1
			}
			#d "storing cache: #{b}"
			#~ storeCachedNeighbourhoodBitArray(pos, b)
		#~ end
		b
	end

	def getNeighbourhoodArchitecture(pos, xd, yd, zd, defaultType=Cell::Empty)

		arch = CubicArchitecture.new(xd, yd, zd)
		index = 0

		x = y = z = i = a = b = c = nil # these are used to cache added coordinates
		cell = nil

		neighbourhood(pos, xd, yd, zd) { |x, y, z, i, a, b, c|
			d "considering cell #{x},#{y},#{z}"
			# if this neighbourhood extends beyond the edge, we fill nil cells with 'empty'
			#
			# TODO: this could be replaced with getCoords/checkCoords
			#
			if (x < 0) || (y < 0) || (z < 0) ||
				(x >= @xsize) || (y >= @ysize) || (z >= @zsize)
				d "some coord < 0 - setting empty."
				arch.setCoords(a, b, c, defaultType)
			else
				cell = getCoords(x,y,z)
				arch.setCoords(a, b, c, (cell == nil)?(Cell::Empty):(cell.value))
			end
		}
		arch
	end

	# -----------------------------------------------------------------------------------------------
	# This cache mechanism stores bitarrays in a 3D array. It relies upon the simulation
	# to determine when they need to be recalculated. While this is very fast (neighbourhoods
	# are only generated once per cycle) it may lead to misperceptions and agents not recognising
	# changes made since the cache was cleared. CURRENTLY DISABLED

	#~ def setupNeighbourhoodBitArrayCache
		#~ @cache = Array.new(@sizes[0]).collect! {
			#~ Array.new(@sizes[1]).collect! {
				#~ Array.new(@sizes[2])
			#~ }
		#~ }
	#~ end

	#~ def clearCachedNeighbourhoodBitArray
		#~ a = b = nil
		#~ for a in @cache
			#~ for b in a
				#~ b.clear
			#~ end
		#~ end
	#~ end

	#~ def getCachedNeighbourhoodBitArray(pos)
		#~ @cache[pos.x][pos.y][pos.z]
	#~ end

	#~ def storeCachedNeighbourhoodBitArray(pos, b)
		#~ @cache[pos.x][pos.y][pos.z] = b
	#~ end
	# -----------------------------------------------------------------------------------------------


	# Neighbourhood() provides a universal way of iterating over a neighbourhood within this
	# (and optionally another) architecture. NOTE! when using this, you NEED to give at least two
	# variables within the loop, otherwise you seem to get all the variables passed in one array, which
	# is no use to anyone. maybe. Example:
	#	neighbourhood(position, 3, 3, 3) { |x,y,z,index,a,b,c| {
	#		.....
	# }
	# x,y,z are the coordinates of the nieghbourhood of this archtecture as defined by the central
	# position 'pos' and the dimensions xd,yd,zd
	# index gives the index with @cells for this coordinate
	# a,b,c give the 'raw' coordinates of the matrix created, i.e. from 0,0,0 through to xd,yd,zd
	# - this is useful for merging architectures
	def neighbourhood(pos, xd, yd, zd)
		bx = pos.x - xd/2 # the lowest ('base') x position
		by = pos.y - yd/2 # the lowest ('base') y position
		bz = pos.z - zd/2	# the lowest ('base') z position

		tx = ty = tz = nil # the coordinates 'multiplied up' to get array indexes
		ox = oy = oz = nil # the offsets for each coordinate (i.e. base = 3, offset = 1, actual coord = 4)
		x = y = z = nil # these are used to cache added coordinates
		cell = nil

		#d "neighbourhood - #{bx},#{by},#{bz}"

		zd.times { |oz|
			z = bz + oz
			tz = z*@xsize*@ysize
			yd.times { |oy|
				y = by + oy
				ty = y*@xsize
				xd.times { |ox|
					x = bx + ox
					yield x, y, z, (x+ty+tz), ox, oy, oz # this calls the block passed with these values
				}
			}
		}
	end

	# Prints a representation of this Architecture (optionally rotated) on stdout
	def print(rot=0)
		@zsize.times { |z|
			@ysize.times { |y|
				printf("[")
				@xsize.times { |x|
					printf(" %d", getCoords(x, y, z, rot).value)
				}
				printf("]\n")
			}
			printf("----------\n")
		}
	end

	# gives the string representation, especially for parameter files
	def to_s
		"#{@xsize},#{ysize},#{zsize},#{self.to_int}"
	end


	def isSpecific?
		result = true
		@cells.each { |cell| result = false if cell.numValues > 1 }
		result
	end


	def CubicArchitecture.copy(arch)
		Marshal::load(Marshal.dump(arch))
	end
end


