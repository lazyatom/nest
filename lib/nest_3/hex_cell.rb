module Nest3
  class HexCell # extending C++ class in ext/HexCell.{h,cpp}
    def ==(other)
      return false if other == nil or !other.respond_to?(:cellDataId)
      other.cellDataId == self.cellDataId
    end

    def ===(other)
      self == other
    end

    def eql?(other)
      return self.hash == other.hash
    end

    def hash
      self.cellDataId.hash
    end

    def to_s
      #id
      #value
      "HexCell #{id} (#{value})"
    end

    # gives every cell around this cell, along with directions
    # from us to them
    def moveAllAround
      dirList = nil
      cell = nil
      vdir = nil
      hdir = nil
      dirs = Nest3::Directions2D + [nil]

      [UP, nil, DOWN].each do |vdir|
        dirs.each do |hdir|
          dirList = [vdir,hdir].compact
          cell = self.getWithList(dirList)
          yield cell, dirList if (!dirList.empty? && (cell != nil))
        end
      end
    end

    def allNeighbours
      dirList = nil
      cell = nil
      [UP, nil, DOWN].each do |vdir|
        (Directions2D + [nil]).each do |hdir|
          dirList = [vdir,hdir].compact
          cell = self.getWithList(dirList)
          if (!dirList.empty? && !Nest3.emptyCell(cell))
            yield cell, dirList
          end
        end
      end
    end

    def neighbourhoodArray
      self.expandSpaceAround
      [self.up,self,self.down].collect do |c|
        [c,c.n,c.ne,c.se,c.s,c.sw,c.nw]
      end.flatten
    end

    # def matchesRotations(cell)
    #   result = []
    #   6.times { |rotation|
    #     result << rotation if yield cell, rotation
    #   }
    #   return result
    # end
    #
    # def matches2DRotations(cell)
    #   self.matchesRotations(cell) { |cell, rotation|
    #     (cell, rotation)
    #        }
    # end
    #
    # def matches3DRotations(cell)
    #   self.matchesRotations(cell) { |cell, rotation|
    #            matches3D(cell, rotation)
    #        }
    # end
    #
    # def buildMatches2DRotations(cell)
    #   self.matchesRotations(cell) { |cell, rotation|
    #            buildMatches2D(cell, rotation)
    #        }
    # end

    # def buildMatches3DRotations(cell)
    #   self.matchesRotations(cell) { |cell, rotation|
    #            buildMatches3D(cell, rotation)
    #        }
    # end

    # def structureMatches2DRotations(cell)
    #   self.matchesRotations(cell) { |cell, rotation|
    #            structureMatches2D(cell, rotation)
    #        }
    # end
    #
    # def structureMatches3DRotations(cell)
    #   self.matchesRotations(cell) { |cell, rotation|
    #            structureMatches3D(cell, rotation)
    #        }
    # end

    def p
      print2D
    end

    def activeNeighbours
      a = []
      self.allNeighbours do |cell, list|
        a << cell if cell.order == UNORDERED_CELL
      end
      a
    end
  end
end