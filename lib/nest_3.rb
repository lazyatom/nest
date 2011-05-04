# load the C++ extension
require File.expand_path("../../ext/Nest3", __FILE__)

def debug(s)
  puts s if $debug #Nest.debuglevel >= level
end

module Nest3
  Directions = [N, NE, SE, S, SW, NW, DOWN, UP]
  Directions2D = [N, NE, SE, S, SW, NW]
end

# load Ruby augmentation classes
require 'nest_3/simulation'
require 'nest_3/meta_architecture'
require 'nest_3/architecture'
require 'nest_3/rule'
require 'nest_3/hex_cell'

# Other classes
require 'nest_3/nest_2_architecture'
require 'nest_3/architecture_collection'
require 'nest_3/algorithm'
# include Nest3::IncreasingStatesAlgorithm
