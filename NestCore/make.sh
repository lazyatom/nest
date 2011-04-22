#!/bin/sh

swig -c++ -ruby -o Nest_wrap.cpp Nest.i
ruby extconf.rb
make

