module Nest3
  class MetaArchitecture # extending the C++ class in MetaArchitecture.{h,cpp}
    # this will expect the depth to have already been extracted and used
    # to create this instance
    def loadFrom(lines)

      deleteAllCells
      celldata = {}

      debug "loading architecture from #{lines.length} lines:\n\t" + lines.join("\t")

      ccId = lines.delete_at(0).to_i

      debug "center cell id: #{ccId}"

      lines.each do |line|
        id, val, order, ruleID, links = parseCellLine(line)
        celldata[id] = [val,order,ruleID,links]
        debug "parsed into #{id},#{val},#{order},#{ruleID}, " + links.to_s
        #so cell[id] = [value, [N.id, NE.id, SE.id, ..., DOWN.id, UP.id]]
      end

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
          Directions.each do |dir|
            cellInThisDir = cellInfo[3][dir]
            if cellInThisDir != -1 && cell.get(dir) == nil && celldata[cellInThisDir] != nil
              cell.set(dir, celldata[cellInThisDir][0]) # ;) heheheheh
              hexcells[cellInThisDir] = cell.get(dir)
              hexcells[cellInThisDir].setOrder(celldata[cellInThisDir][1])
              hexcells[cellInThisDir].setId(cellInThisDir)
            end
          end
          cellIDs.delete(cellId)
        end
      end
      initCoordinates
    end

    private

    # expects lines to the in the form [id, val, order, [links]]
    def parseCellLine(line)
      debug "parsing: " + line
      line  =~ /([0-9]*)=([0-9]*),([0-9]*),([0-9\-]*) \: ([0-9\-]*) ([0-9\-]*) ([0-9\-]*) ([0-9\-]*) ([0-9\-]*) ([0-9\-]*) ([0-9\-]*) ([0-9\-]*)/
      return $1.to_i, $2.to_i, $3.to_i, $4.to_i,
             [$5.to_i, $6.to_i, $7.to_i, $8.to_i, $9.to_i, $10.to_i, $11.to_i, $12.to_i]
    end
  end
end