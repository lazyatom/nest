class Nest2Architecture

	attr_reader :cells

	def initialize(size)
		@size = size
		@cells = []
	end

	def getCell(x, y, z)
		@cells[x+y*@size+z*@size*@size]
	end
	
	def setCell(x, y, z, val)
		@cells[x+y*@size+z*@size*@size] = val		
	end

	def Nest2Architecture.load(filename)

		f = File.open(filename, "r")

		if (f == nil)
			puts "ERROR >> unable to read file #{filename}"
			return 0
		else
			# read the architecture
			cells = []
			
			archsizestr = f.gets       # reading parameter archSize
			archsizestr =~ /architecture size = ([0-9]+)/
			size = $1.to_i;
			cellsNumberStr = f.gets      # reading parameter cellsNumber
			cellsNumberStr =~ /number of cells = ([0-9]+)/
			cellsNumber = $1.to_i;

			arch = Nest2Architecture.new(size)

			size.times { |k|
				size.times { |j|
					temp = f.gets
					#puts "read: #{temp}"
					size.times { |i|
						#puts "considering: #{temp[j]} [#{temp[j].class.to_s}]"
						if (temp[i] == 45) # '-'
							#puts "got empty..."
							arch.setCell(i, j, k, CELL_EMPTY)
						elsif (temp[i] == 82) # 'R'
							#puts "got red..."
							arch.setCell(i, j, k, CELL_RED)
						elsif (temp[i] == 89) # 'Y'
							#puts "got yellow..."
							arch.setCell(i, j, k, CELL_YELLOW)
						elsif (temp[i] == 66) # 'B'
							#puts "got blue..."
							arch.setCell(i, j, k, CELL_BLUE)
						else
							#puts "rejected!"
							arch.setCell(i, j, k, CELL_EMPTY)
						end
					}
				}
			}
		end
		f.close()
		
		arch
	end
	
		
	# we've now got the cells in a pretty array, we should try and find the centre
	# to then build out masterpiece.	
	def toNest3Architecture
		a = Architecture.new(@size*2)
		
		cell = a.centreCell
		(@size/2).times { 
			cell = cell.set(UP, CELL_EMPTY)
		}
		# now we are at the top, in the middle.
		
		# go south size/2 times
		(@size/2).times { cell = cell.set(S, CELL_EMPTY) }
		# zig-zag outwards.
		(@size/2).times { |s| ((s%2)==0)?(cell = cell.set(NW, CELL_EMPTY)):(cell = cell.set(SW, CELL_EMPTY)) }
		
		planeCornerCell = cell
		rowTopCell = cell
		
		#puts cell.id
		
		@size.times { |z|
			# go through each level - 'z' = UP/DOWN
			#puts "creating 0,0,#{z}; val = #{getCell(0,0,z)}"
			#puts "planeCorner cell is currently: #{planeCornerCell.cellId}"
			planeCornerCell = planeCornerCell.set(DOWN, getCell(0, 0, z))
			#puts "\tand now: #{planeCornerCell}"
			rowTopCell = planeCornerCell
			cell = rowTopCell
			(1..(@size-1)).each { |x|
				# x+ = north
				#puts "creating #{x},#{0},#{z}; val = #{getCell(x,0,z)}"
				cell = cell.set(N, getCell(x, 0, z))
			}
			(1..(@size-1)).each { |y|
				# y+ = NE (on even rows) & SE (on odd rows)
				#puts "creating 0,#{y},#{z}; val = #{getCell(0,y,z)}"
				rowTopCell = rowTopCell.set(((y%2)==0)?(NE):(SE), getCell(0, y, z))
				cell = rowTopCell
				(1..(@size-1)).each { |x|
					# x+ = north
					#puts "creating #{x},#{y},#{z}; val = #{getCell(x,y,z)}"
					cell = cell.set(N, getCell(x, y, z))
				}
			}
		}

		# we have to do the coordinate calculation before we clear the
		# empty cells, because otherwise orphan cells with no links to base
		# their coordinates on will exist.
		a.initCoordinates()

		a.clearEmptyCells()
		
		# we need to somehow reorient the centre cell... mostlikely it will currently
		# be empty, and if this architecture is saved it won't load properly.
		
		a
	end
end