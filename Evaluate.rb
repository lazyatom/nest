require 'Algorithm'

#require 'rbprof'
#$profiler.profile_method(:moveAllAround, HexCell)
#$profiler.profile_method(:getWithList, HexCell)

if __FILE__ == $0
  if ARGV.length == 0
    puts "usage: ruby evaluate.rb <architecture-file>"
    exit(-1)
  end
  arch = Architecture.load(ARGV[0])
  alg = Algorithm.new(arch)
  alg.ISA
  puts "number of states: #{alg.states.length}"
  File.open(ARGV[0]+".result", "w") do |f|
    f.puts alg.states.length
  end
  exit(alg.states.length)
end