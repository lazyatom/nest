require 'Nest3'
$debug = true

10.times { |i|
    a = Nest3::Architecture.random(10)
    a.resetCellIDs
    a.applyRandomOrder
    a.save("arch"+i.to_s+".arch")
    Nest3::Algorithm.new(a).ISA
    
    a.save("arch"+i.to_s+".arch")
    Nest3::ArchitectureCollection.fromArray(a.rules(true)).save("arch"+i.to_s+".rules")
}

10.times { |i|
    s = Nest3::Simulation.create("arch"+i.to_s+".rules", 5, 10, 1000)
    s.run
    s.architecture.save("arch"+i.to_s+"-out.arch")
}
