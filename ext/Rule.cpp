#include "Rule.h"

Rule::Rule(int depth) : MetaArchitecture(depth) {
    centreCell->setValue(CELL_UNDEFINED);
    centreCell->expandSpaceAround();
}


VALUE Rule::postrulesWithCells(VALUE v) {
	/*	postrules = []
		
		rulecollection.to_a.each { |postrule|
			cc.moveAllAround { |cell, moveList|
				# cell is the cell around THIS rule (i.e. NOT in the postrule)
				# moveList is the directions taken from OUR cc to that cell.	
				if cell.isEmpty() && postrule.cc.buildMatches(cell)
					# next we need to get the brick within the postrule 
					# which matches against the build brick of this rule	
					postrules << [postrule, \
					   postrule.cc.getWithList(reverseDirectionList(moveList))]
				end
			}
		}
		return postrules*/

}