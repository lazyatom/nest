# Augmenting Architecture.cpp with some Ruby goodness
# ---------------------------------------------------------------------
#


def orphan?(cell)
    if cell != nil
        neighbours = cell.neighbourhoodArray.compact.delete_if { |c|
            c.isEmpty()
        }
        return true if neighbours.empty?
    end
    return false
end




class NestCore::Architecture

    # dummy
    def depth
        1
    end
    
    def centreCell
        first
    end

	# accessing Cell Data
	# ---------------------------------------
	def eachCell
		tmp = first
		while (tmp != nil)
			yield tmp
			tmp = tmp.next
		end
	end
	def eachBrick
		tmp = first
		while (tmp != nil)
			yield tmp if !tmp.isEmpty()
			#puts "each: tmp.id = #{tmp.id} & tmp.next = #{tmp.next}"
			tmp = tmp.next
		end		
	end
		
	def to_a
		a = []
		self.eachCell { |c| a << c }
		a
	end
		
	def to_brick_a
		a = []
		self.eachBrick { |b| a << b }
		a
	end
	
	def to_empty_a
		to_a.delete_if { |cell| !cell.isEmpty() }
	end


	def numStates
	   to_brick_a.collect { |b| b.value() }.uniq.length
	end
	
	
	def rules(recalculate = false)
		if (@ruleGroups == nil || recalculate)
			rules = to_brick_a.collect { |brick|
				r = Rule.new()
				brick.mapOnto(r.cc)
				r.cc.filterUsingOrder
				r.cc.expand2DSpaceAround
				r.initCoordinates
				r
			}
			
			@ruleGroups = rules #ArchitectureCollection.fromArray(rules)
			#@ruleGroups.name = "Rules"
		end
		@ruleGroups
	end

	# The subarchitecture processors
	# ---------------------------------------------------------------
	#
	def resetOrdering(newOrder=1)
		eachBrick { |cell| cell.setOrder(newOrder) }
	end
	
	def resetCellIDs()
		i = 0
		eachBrick { |c| c.setId(i); i += 1 }
	end

	def randomValidOrder
		# choose a random start cell
		startcell = self.to_brick_a.randomElement
		
		order = [startcell.id]
		frontier = [startcell]
		
		# start a random walk
		while !frontier.empty? do
			tmpCell = frontier.randomElement
			neighbours = tmpCell.neighbourhoodArray
			neighbours.delete_if { |cell| 
			     cell == nil || order.include?(cell.id) || cell.isEmpty() 
            }
			if neighbours.empty?
				frontier.delete(tmpCell)
			else
				nextCell = neighbours.randomElement
				order << nextCell.id
				frontier << nextCell
			end		
		end
		order
	end

	def setNaiveOrder
		i = 1
		eachCell { |cell|
		  cell.setOrder((i += 1)) if !cell.isEmpty
        }
	end

	def applyOrder(order)
		order.each_with_index { |id, index|
			c = self.getCell(id)
			c.setOrder(index+1)
			c.setRuleID(c.order())
		}
	end
	
	def applyRandomOrder()
	   applyOrder(randomValidOrder())
	end
	
	# note that this also works for partial orders, so long as they contain the
	# first cell
	def validOrder?(myorder=nil)
		return orderErrorBrick() == nil
	end
	
	def orderErrorBrick(myorder=nil)
		if (myorder == nil)
			# we need to generate the order array
			order = self.to_a
			order.sort! { |x,y| x.order() <=> y.order() }
			order.collect! { |brick| brick.id() }
		else
			order = myorder.dup
		end
	
		previousCells = [order.delete_at(0)]
		
		#puts order.inspect
		
		order.each_with_index { |brickId, index|
			#puts "id = " + brickId.to_s
			cell = self.getCell(brickId)
			#puts "looking at cell #{brickId}, order #{cell.order}"
			neighbourIDs = []
			cell.moveAllAround { |brick, list|
				neighbourIDs << brick.id #if brick != nil
			}
			#puts "\tneighbours: " + neighbourIDs.inspect
			#puts "\talready seen: " + previousCells.inspect
			return [brickId,index+1] if (previousCells & neighbourIDs == [])
			previousCells << brickId
		}
		return nil
	end






	#
	# Architecture Output Code
	# ----------------------------------------------------------
	#

    def cellInfoString(cell)
        line = "#{cell.id}=#{cell.value},#{cell.order},#{cell.ruleID} : "
        Directions.each { |dir|
            if cell.get(dir) != nil && !orphan?(cell.get(dir))
                line += cell.get(dir).id.to_s + " "
            else
                line += "-1 "
            end
        }
        line    
    end

	def to_full_s
		str = ""
		str << depth.to_s + "\n"
		str << first.id.to_s + "\n"
		eachCell { |cell|
			str << cellInfoString(cell) + "\n"
		}
		str
	end
	
	def to_s
		str = ""
		str << depth.to_s + "\n"
		str << first.id.to_s + "\n"
		eachBrick { |cell|
			str << cellInfoString(cell) + "\n"
		}
		str	
	end	

	def save(filename)
	   return false if filename == nil
		File.open(filename, "w") { |f|
			puts "Saving architecture as \"#{filename}\""
			f.puts(self.to_full_s)
		}
	end
    
 	# class methods to load architectures
	# ------------------------------------------------------------
	def Architecture.load(filename)
		begin
	     lines = IO.readlines(filename)        
	     depth = lines.shift.to_i
	     a = Architecture.new(depth)
	     a.loadFrom(lines)
	     return a
	  rescue Errno::ENOENT
	   	puts "couldn't load \"#{filename}\" in dir \"#{Dir.pwd}\""
	   	return nil
	  end
	end	
		

    # this will expect the depth to have already been extracted and used
    # to create this instance
    def loadFrom(lines)
    
        deleteAllCells()

        celldata = {}

		debug "loading architecture from #{lines.length} lines:\n\t" + lines.join("\t")

		ccId = lines.delete_at(0).to_i

		debug "center cell id: #{ccId}"

		lines.each { |line|
			id, val, order, ruleID, links = Architecture.parseCellLine(line)
			celldata[id] = [val,order,ruleID,links]
			debug "parsed into #{id},#{val},#{order},#{ruleID}, " + links.to_s
			#so cell[id] = [value, [N.id, NE.id, SE.id, ..., DOWN.id, UP.id]]
		}
				
		# pick a cell to start with - it doesn't really matter which one
		# (although we could always start with the first one)
		cell = centreCell
		cell.setValue(celldata[ccId][0])
		cell.setOrder(celldata[ccId][1])
		cell.setRuleID(celldata[ccId][2])
		cell.setId(ccId)

		hexcells = {}
		hexcells[ccId] = centreCell # insert our pregenerated centreCell

		# this first one is almost certainly the centreCell.
		cellIDs = celldata.keys.sort
		
		debug "cellIDs: " + cellIDs.inspect

        error = 0

		while !cellIDs.empty? && error < 100
			cellId = cellIDs[0]
			cellInfo = celldata[cellId]
			cell = hexcells[cellId]

			#debug "looking for #{cellId}"

			if cell == nil
				# we've not seen this cell yet, so stick it at the end,
				# we'll do it later.
				cellIDs.push(cellIDs.delete(cellId))
				error += 1 # we're not going to knock ourselves out looking for cells.
			else
			     error = 0 # reset the error count.
				Directions.each { |dir|
					cellInThisDir = cellInfo[3][dir]
					if cellInThisDir != -1 && cell.get(dir) == nil && celldata[cellInThisDir] != nil
						cell.set(dir, celldata[cellInThisDir][0]) # ;) heheheheh
						hexcells[cellInThisDir] = cell.get(dir)
						hexcells[cellInThisDir].setOrder(celldata[cellInThisDir][1])
						hexcells[cellInThisDir].setId(cellInThisDir)
					end
				}
				cellIDs.delete(cellId)
			end
		end
		initCoordinates()    
    end

	# expects lines to the in the form [id, val, order, [links]]
	def Architecture.parseCellLine(line)
		debug "parsing: " + line
		line  =~ /([0-9]*)=([0-9]*),([0-9]*),([0-9\-]*) \: ([0-9\-]*) ([0-9\-]*) ([0-9\-]*) ([0-9\-]*) ([0-9\-]*) ([0-9\-]*) ([0-9\-]*) ([0-9\-]*)/
		return $1.to_i, $2.to_i, $3.to_i, $4.to_i, 
		  [$5.to_i, $6.to_i, $7.to_i, $8.to_i, $9.to_i, $10.to_i, $11.to_i, $12.to_i]
	end





	def Architecture.ring
		# returns a small ring of red bricks
		a = Architecture.new(30)
		a.centreCell.setValue(CELL_EMPTY)
		c = a.centreCell
	
		6.times { |d|
			c.set(d, CELL_RED)
			c.get(d).setOrder(d+1)
		}
		
		a.initCoordinates
		a.resetCellIDs
		a
	end
	
	def Architecture.default2
	   a = Architecture.new(30)
	   a.cc.set(N, CELL_RED)
	   a.cc.n.setOrder(1)
	   a.cc.set(NE, CELL_RED)
	   a.cc.ne.setOrder(2)
	   a.cc.setValue(CELL_RED)
	   a.cc.setOrder(3)
        a.cc.set(SW, CELL_RED)
        a.cc.sw.setOrder(4)
        a.cc.set(S, CELL_RED)
        a.cc.s.setOrder(5)
        
        a.initCoordinates
        a.resetCellIDs
        a
    end
    
	def Architecture.default3
	   a = Architecture.new(30)
	   a.cc.set(N, CELL_RED)
	   a.cc.n.setOrder(1)
	   a.cc.set(NE, CELL_RED)
	   a.cc.ne.setOrder(2)
	   a.cc.ne.set(SE, CELL_RED)
	   a.cc.ne.se.setOrder(3)
        a.cc.setValue(CELL_RED)
        a.cc.setOrder(4)
        a.cc.set(SE, CELL_RED)
        a.cc.se.setOrder(5)
        a.cc.set(SW, CELL_RED)
        a.cc.sw.setOrder(6)
        
        a.initCoordinates
        a.resetCellIDs
        a
    end
    
    def Architecture.line(length=5, dir=S)
    	a = Architecture.new(30)
			a.cc.setValue(CELL_RED)
			a.cc.setOrder(1)
			tmp = a.cc
			(length-1).times { |x|
				tmp.set(dir, CELL_RED)
				tmp = tmp.get(dir)
				tmp.setOrder(x+2)
			}
			a.resetCellIDs
			a.resetOrdering()
			a  
    end
    
    def Architecture.column(length=5)
			Architecture.line(length, DOWN)
    end    
    
    def Architecture.random(bricks=10)
    
        a = Architecture.new(30)
        a.cc.setValue(CELL_RED)
        
        startcell = a.cc
        startcell.expandSpaceAround()
        
        # start a random walk
        while a.numBricks < bricks do
            tmpCell = a.to_a[rand(a.numBricks)]
            neighbours = tmpCell.neighbourhoodArray
            neighbours.delete_if { |cell| cell == nil || !cell.isEmpty() }
            if !neighbours.empty?
                nextCell = neighbours[rand(neighbours.length)]
                nextCell.setValue(CELL_RED)
                nextCell.expandSpaceAround()
            end		
        end
        
        a.resetCellIDs
        a.applyOrder(a.randomValidOrder())
        a		
    end

    
    def Architecture.random2D(bricks=10)
    
        a = Architecture.new(30)
        a.cc.setValue(CELL_RED)
        
        startcell = a.cc
        startcell.expandSpaceAround()
        
        # start a random walk
        while a.numBricks < bricks do
            tmpCell = a.to_a[rand(a.numBricks)]
            tmpCell.set(rand(NUM_CARDINAL_DIRECTIONS), CELL_RED)		
        end
        
        a.resetCellIDs
        a.applyOrder(a.randomValidOrder())
        a		
    end

end


	
#	# returns a nested array of cells, one from each MUST be
#	# present before this suborder for the whole order to be valid
#	def subOrderDependencies(subOrder)
#		# get the neighbours of the first cell in the subOrder
#		# the first cell is a special case, because it has no dependencies
#		neighbourIDs = []
#		cell = self.getCell(subOrder[0])
#		cell.allNeighbours { |brick, list|
#			neighbourIDs << brick.id if !subOrder.include?(brick.id)
#		}
#		neighbourIDs = [neighbourIDs]
#		
#		# check the other cells
#		subOrder[1..(subOrder.length-1)].each_with_index { |cellID, index|
#			tmpNeighbourIDs = []
#			cell = self.getCell(cellID)
#			cell.allNeighbours { |brick, list|
#				tmpNeighbourIDs << brick.id
#			}
#			# check if any of these are present already (previous to this brick)
#			# in the subOrder
#			commonIDs = subOrder[0..index] & tmpNeighbourIDs
#			if commonIDs.empty? # there are no common bricks, i.e. this brick
#													# requires a brick external to this subOrder
#				neighbourIDs << tmpNeighbourIDs # add these ones
#			end
#		}
#		
#		return neighbourIDs
#	end

	# Groups
#	def matchingCells
#		pCells = self.to_brick_a() # the set of all unmatched cells
#		i = 0
#		groups = []
#		while (pCells.length > 0)
#			baseCell = pCells.pop
#			groups[i] = [[baseCell, 0]] # the current cell to match
#			pCells.delete_if { |cell| # compare currentCell to pCells
#				if !cell.isEmpty()
#					# if cell matches groups[i][0] then extract it
#					rot = (cell.matches3D(groups[i][0][0]))?(0):(-1)
#					if rot != -1
#						groups[i] << [cell, rot]
#					end
#				end
#			}
#			i += 1
#		end
#		
#		groups
#	end
#
#
#	def subArchitectureGroups(recalculate = false)
#		if (@subArchitectureGroups == nil || recalculate)
#			groups = matchingCells()
#			@subArchitectureGroups = ArchitectureCollection.new()
#			groups.each_with_index { |group, index|
#				group.each { |pattern|
#					a = Architecture.new(3)
#					pattern[0].mapOnto(a.centreCell)
#					a.initCoordinates
#					@subArchitectureGroups.addPattern(index, a, pattern[1])
#				}
#			}
#			
#			@subArchitectureGroups.eachPattern { |x| x.clear(CELL_NIL) }		
#			@subArchitectureGroups.name = "SubArchitectures"
#		end
#		@subArchitectureGroups
#	end
