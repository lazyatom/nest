$LOAD_PATH.unshift "lib"
require 'nest_3'

# a = Nest3::Architecture.ring
# 
# startTime = Time.new
# 
# 10.times do
#   puts a.applyRandomOrder.inspect
#   Nest3::IncreasingStatesAlgorithm.increasingStates(a)
# end
# 
# timeTaken = Time.new - startTime
# puts "[time taken: #{timeTaken}]"


a = Nest3::Architecture.ring #load(ARGV[0])
puts a.to_full_s