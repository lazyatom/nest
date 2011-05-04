module Nest3
  class ArchitectureCollection
    attr_reader :architectureGroups

    attr_accessor :name

    def initialize
      @patternGroups = [[]]
      @name = ""
    end

    def eachPattern
      @patternGroups.each do |group|
        group.each do |pattern|
          yield pattern[0]
        end
      end
    end

    def each
      @patternGroups.each do |group|
        group.each do |pattern|
          yield pattern[0]
        end
      end
    end

    def to_a
      a = []
      eachPattern { |p| a << p }
      a
    end

    def eachGroup
      @patternGroups.each do |group|
        yield group
      end
    end

    def ArchitectureCollection.fromArray(array)
      i = 0
      collection = ArchitectureCollection.new
      while (array.length > 0)
        #puts "pCells = #{pCells.inspect}"
        baseArch = array.pop
        #puts "working with cell #{baseCell.id}"
        collection.addPattern(i, baseArch, 0) # the current cell to match, groups[i][0]
        array.delete_if do |a| # compare currentCell to array
          #puts "\tcomparing to #{cell.id}"
          if !a.cc.isEmpty
            # if cell matches this group then extract it
            rot = (a.cc.matches3D(baseArch.cc))?(0):(-1)
            #puts "\t\t--> #{rot}"
            if rot != -1
              collection.addPattern(i, a, rot)
            end
          end
        end
        i += 1
      end

      collection.sort
      collection
    end

    def to_s
      str = ""
      numGroups.times do |g|
        numPatterns(g).times do |p|
          rot = getPatternRotation(g, p)
          str << "group=#{g} pattern=#{p} rotation=#{rot}\n"
          str << getPattern(g, p).to_s
        end
      end
      str
    end

    def to_full_s
      str = ""
      numGroups.times do |g|
        numPatterns(g).times do |p|
          rot = getPatternRotation(g, p)
          str << "group=#{g} pattern=#{p} rotation=#{rot}\n"
          str << getPattern(g, p).to_full_s
        end
      end
      str
    end

    def save(filename)
      File.open(filename, "w") do |f|
        f.puts(to_full_s)
      end
    end

    def ArchitectureCollection.parseHeaderLine(line)
      line  =~ /group=([\d+]) pattern=([\d+]) rotation=([\d+])/
      return $1.to_i, $2.to_i, $3.to_i
    end

    def ArchitectureCollection.load(filename)
      lines = IO.readlines(filename)
      currentstart = 0
      ac = ArchitectureCollection.new
      until currentstart >= lines.length
        length = 1
        until (lines[currentstart+length] == nil) || (lines[currentstart+length][0..4] == "group")
          length += 1
        end
        group, pattern, rot = ArchitectureCollection.parseHeaderLine(lines[currentstart])
        debug "parsed header into #{group},#{pattern},#{rot}, parsing from line #{currentstart+1} [#{length} lines]"
        depth = lines[currentstart+1].to_i
        a = Nest3::Architecture.new(depth)
        a.loadFrom(lines.slice(currentstart+2, length-2))
        ac.addPattern(group, a, rot)
        currentstart += length
      end
      debug "parsed all architectures"
      ac
    end

    def ArchitectureCollection.loadRules(filename)
      lines = IO.readlines(filename)
      currentstart = 0
      ac = ArchitectureCollection.new
      until currentstart >= lines.length
        length = 1
        until (lines[currentstart+length] == nil) || # the line is nil (i.e. end of line)
              (lines[currentstart+length][0..4] == "group") # the line starts with "group"
          length += 1
        end
        group, pattern, rot = ArchitectureCollection.parseHeaderLine(lines[currentstart])
        debug "parsed header into #{group},#{pattern},#{rot}, parsing from line #{currentstart+1} [#{length} lines]"
        depth = lines[currentstart+1].to_i
        a = Rule.new
        debug "loading:" + lines.slice(currentstart+2, length-2).join("") # add 2 to skip header & arch depth
        a.loadFrom(lines.slice(currentstart+2, length-2))
        debug "loaded rule #{a.cc.id}"
        ac.addPattern(group, a, rot)
        currentstart += length
      end
      debug "parsed all architectures"
      ac
    end

    def addPattern(group, arch, rotation)
      @patternGroups[group] = [] if @patternGroups[group] == nil
      @patternGroups[group] << [arch, rotation]
      sortGroup(group)
    end

    def getGroup(group)
      @patternGroups[group]
    end

    def [](x,y=0)
      getPattern(x,y)
    end

    def getPattern(group, pattern)
      @patternGroups[group][pattern][0]
    end

    def getPatternRotation(group, pattern)
      @patternGroups[group][pattern][1]
    end

    def numGroups
      @patternGroups.length
    end

    def numPatterns(group)
      @patternGroups[group].length
    end

    def removeGroupsWithSingleBricks
      @patternGroups.delete_if do |group|
        group[0][0].numBricks == 1
      end
    end

    def sortGroup(i)
      @patternGroups[i].sort! do |rule1, rule2|
        rule1[0].cc.order <=> rule2[0].cc.order
      end
    end

    def sort
      @patternGroups.length.times do |i|
        sortGroup(i)
      end
      @patternGroups.sort! do |group1, group2|
        group1[0][0].cc.order <=> group2[0][0].cc.order
      end
    end
  end
end