class CondorJob
    @@nextId = 0
    
    attr_reader :archString, :id
    
    def initialize(archStr)
        @id = @@nextId
        @@nextId += 1
        @archString = archStr
    end
end

class CondorManager

    attr_accessor :evaluator

    def initialize(ga = nil)
        @jobs = []
        @offline = false
        @ga = ga
    end

    def goOffline(eval)
        @offline = true
    end

    # arch_str is a string which can be loaded directly
    # by the evaluator system.
    def submit(archStr)
        @jobs << Job.new(archStr)
        return @jobs.last.id
    end
    
    # this method should return once all evaluations have
    # been performed.
    def process()
    
        if @offline
            @jobs.each { |job|
                @ga.applySolution
                #@evaluator.ISA()
            }
        
        else
        
            # send all the jobs to condor
            @jobs.each { |job|
                job.sendToCondor()
            }
            
            #
        end
    end    
    
    def waitForFiles(files)
        threads = []
        files.each { |file|
            threads << Thread.new(file) { |myFile|
                while !FileTest.exists?(myFile) do
                    sleep(1)
                end
            }
        }
        threads.each { |thread| thread.join }
        puts "ALL OK!"
    end
end