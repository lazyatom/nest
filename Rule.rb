require 'Nest3'

class Rule < MetaArchitecture
  def initialize(depth=5)
    super(depth)
    cc.setValue(CELL_UNDEFINED)
    cc.expandSpaceAround # make sure no cells are NULL
  end

  def p
    cc.print3D
  end

  def p2
    cc.print2D
  end

  def order
    cc.order
  end

  def hasPostrule?(otherRule)
    return false if otherRule == nil
    result = []
    cc.moveAllAround do |cell, moveList|
      # cell is the cell around THIS rule (i.e. NOT in the postrule)
      # moveList is the directions taken from OUR cc to that cell.

      if cell.isEmpty && otherRule.cc.matches3D(cell, 0, false)

          reversedList = reverseDirectionList(moveList)
          result << otherRule.cc.getWithList(reversedList)

      end
    end

    return false if result == []
    return result
  end
end