require 'Nest3'

module IncreasingStatesAlgorithm


	def nextState(states, usedStates=[])
		unusedStates = states - usedStates
		if unusedStates.empty?
			states << nextCellValue(states.last)
			return states.last
		else
			return unusedStates.first
		end
	end


	def increasingStates(architecture)
	
		startTime = Time.new
		
		states = [CELL_RED]
		
		# this simply expands space around the structure for ease in 
		# comparing neighbourhoods
		architecture.prepFor3DMatching()		
		# set all cell states to UNDEFINED
		architecture.setBricks(CELL_UNDEFINED)
		# extract rules 'R'
		rules = architecture.rules(true).to_a.sort {|x,y| 
            x.order <=> y.order 
        }.freeze
		
		# setup loop variables, for speed
		currentRule = nil
		matchingBricks = nil

        tags = Array.new(architecture.numBricks)

		rules.each { |currentRule| # for each rule Rx in R
		
            next if currentRule.cc.isDefined # skip?
            
            debug "====== Processing Rule #{currentRule.order} ======="    
			
			# find matching bricks for all postrules Rp for Rx
			matchingBricks = rules.collect { |rule| 
                currentRule.hasPostrule?(rule) 
            }.flatten
			matchingBricks.delete(false)
			debug matchingBricks.inspect
			
			# remove 'desired' postrules
			matchingBricks.delete_if { |brick| brick == currentRule.cc }
			debug matchingBricks.inspect

            # calculate the used values given matching bricks and tags
            usedValues = matchingBricks.collect { |brick| brick.value }.uniq
            usedValues += tags[currentRule.cc.id] if tags[currentRule.cc.id] != nil
            
            debug usedValues.inspect + " : " + tags[currentRule.cc.id].inspect + " >> " + tags.inspect
            
            usedValues.delete(CELL_UNDEFINED)
            
            # assign the new value
            currentRule.cc.setValue(nextState(states, usedValues))
            debug "assigned value #{currentRule.cc.value} to rule"


            # remove all the matching bricks that are now differentiated			
			matchingBricks.delete_if { |brick| brick.isDefined() }
			
			# tag all the UNDEFINED matching bricks with this brick's value
			matchingBricks.each { |brick| 
                tags[brick.id] = [] if tags[brick.id] == nil
                debug "tagging brick #{brick.id} with #{currentRule.cc.value}"
                tags[brick.id] << currentRule.cc.value
            }
		}	
		
		timeTaken = Time.new - startTime
		puts "total of #{states.length} states used! [time taken: #{timeTaken}]"
	end
end



