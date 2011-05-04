Nest 3.0
========

This is the software that I wrote to support my investigation into "[The Automatic Extraction of Stigmergic Algorithms from Lattice Structures][thesis]"

*IMPORTANT*: You should also bear in mind that lots of this software may not currently function; I was not building a "product", but was evolving software and algorithms to explore the ideas required for my thesis. Things that used to work could easily be broken. This software may not be useful for you.

It's the first "serious" Ruby that I wrote (in around 2003), and as such it's not exactly polished. It also may not work well on your system.


Getting it running
------------------

You'll need the following:

* ruby (1.8.7, probably)
* ruby-opengl (`gem install ruby-opengl`, I'm using 0.60.1)
* a C++ compiler

Go into the 'ext' directory, and run `make.sh`. This should compile the C++ data structures required for fast processing of rules and architectures.

Then, in the top level directory, run `./glv` to actually start the software



Using it
--------

I implemented a weird modal interface for interacting with the rules and the architecture. It is the opposite of user-friendly. I strongly recommend reading the [thesis][] to understand what the point of it was.

I'll repeat what I said above: you should also bear in mind that lots of this software may not currently function; I was not building a "product", but was evolving software and algorithms to explore the ideas required for my thesis. Things that used to work could easily be broken. This software may not be useful for you.

That said:

In a nutshell, you use the numbers 0-6 to move in any of the six horizontal directions, and up & down. Hitting spacebar will place a cell.

Beyond that, you'll need to go to the code. Hopefully I will get the chance to tidy this up and explain a bit more about what the point was, but for now, this is all there is.


[thesis]: http://assets.lazyatom.com/thesis.pdf