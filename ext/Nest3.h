#ifndef __NEST_3__
#define __NEST_3__

#include <cstdio>
#include <cstdlib>
#include "math.h"



#define CELL_ERROR 0
// NIL cells are used just to ensure that linking between levels is correctly preserved.
#define CELL_NIL 1

#define CELL_EMPTY 2
#define CELL_UNDEFINED 3
#define CELL_RED 4
#define CELL_BLUE 5
#define CELL_GREEN 6
#define CELL_YELLOW 7
#define CELL_CYAN 8
#define CELL_MAGENTA 9
#define CELL_ORANGE 10
#define CELL_DARK_RED 11
#define CELL_DARK_GREEN 12
#define CELL_DARK_BLUE 13
#define CELL_DARK_CYAN 14
#define CELL_DARK_MAGENTA 15
#define CELL_DARK_YELLOW 16
#define CELL_DARK_ORANGE 17
#define CELL_LIGHT_RED 18
#define CELL_LIGHT_GREEN 19
#define CELL_LIGHT_BLUE 20
#define CELL_LIGHT_CYAN 21
#define CELL_LIGHT_MAGENTA 22
#define CELL_LIGHT_YELLOW 23
#define CELL_LIGHT_ORANGE 24
#define CELL_WHITE 25
#define CELL_GREY 26
#define CELL_LIGHT_GREY 27
#define CELL_DARK_GREY 28

typedef long int CELL_VALUE;

#define nextCellValue(n) n+1

/*
    this defines how we actually compare values
    for bitwise comparisons vs. straight integers
*/

#define matchCellValue(a,b) a == b


// ----- DIRECTIONS ------------------

#define N 0
#define NE 1
#define SE 2
#define S 3
#define SW 4
#define NW 5
#define UP 7
#define DOWN 6

typedef int DIRECTION;

// these are 'hyperspace' directions
// they are used in linking between parent and child, as opposed to
// UP and DOWN which relate to neighbour cells (albeit in 3D)
#define PARENT UP

#define DIRECTION_ERROR -1
#define DIRECTION_NIL -1

#define NUM_DIRECTIONS 8
#define NUM_CARDINAL_DIRECTIONS 6


extern int debuglevel;


// predeclare all the classes, just in case.
class HexCell;
class HyperCell;
class Agent;
class Architecture;
class Coordinates;
class Simulator;
class Random;
class Cell;
class Rule;
class MetaArchitecture;

#define __DEBUG__

#ifndef __DEBUG__
#define debug(s) ;
#else
#define debug(s) printf(s);
#endif

#endif
