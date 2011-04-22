require 'Nest3'

a = Architecture.ring

startTime = Time.new

10.times {
    puts a.applyRandomOrder.inspect
    
    increasingStates(a)
}

timeTaken = Time.new - startTime
puts "[time taken: #{timeTaken}]"
