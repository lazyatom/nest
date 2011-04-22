require 'Nest3'

a = Architecture.ring

startTime = Time.new

10.times do
  puts a.applyRandomOrder.inspect
  increasingStates(a)
end

timeTaken = Time.new - startTime
puts "[time taken: #{timeTaken}]"
