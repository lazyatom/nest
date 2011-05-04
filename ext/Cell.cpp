#include "Cell.h"




/* helper function to reverse hexagonal directions
  NOTE: these functions only work in the 6 2D cardinal directions:
  N, NE, SE, S, SW, NW
  - UP, DOWN are ignored thrpigj the use of '%6'
*/
inline int converseDirection(DIRECTION dir) {
  if (dir < 6)
    return (dir+3)%6;
  else if (dir == UP) return DOWN;
  else if (dir == DOWN) return UP;
  else {
    printf("direction error!\n");
    return DIRECTION_ERROR;
  }
}

inline int cwNeighbour(DIRECTION dir) {
  return (dir+1)%6;
}

inline int ccwNeighbour(DIRECTION dir) {
  return (dir+5)%6;
}


// initialise the static cell ID
int Cell::nextId = 0;



Cell::Cell() {
  for (int i=0; i < NUM_DIRECTIONS; i++) neighbour[i] = NULL;
  for (int i=0; i < NUM_DIRECTIONS; i++) children[i] = NULL;
  cellId = Cell::nextId++;
  dirToParent= DIRECTION_ERROR;
  frozen = false;
}

Cell::~Cell() {
  this->detach();
  this->unlink();
}

void Cell::detach() {
  if (this->children[PARENT] != NULL) {
    this->children[PARENT]->children[converseDirection(this->dirToParent)] = NULL;
    this->children[PARENT] = NULL;
  }
}

void Cell::unlink() {
  for (int i=0; i < 8; i++) {
    if (neighbour[i] != NULL) {
      neighbour[i]->neighbour[converseDirection(i)] = NULL;
    }
  }

}

Cell *Cell::getChild(DIRECTION dir) {
  return (dir < 0 || dir > NUM_DIRECTIONS)?NULL:(children[dir]);
}




// a simple, fast way to get the neighbour. this should only be 
// called once the cell has been properly linked
Cell *Cell::getNeighbour(DIRECTION dir) {
  return (dir < 0 || dir > NUM_DIRECTIONS)?NULL:(neighbour[dir]);
}



#define checkNeighbour(dir) \
    if (this->children[PARENT]->neighbour[dir] == NULL) \
        {/*printf("\tno child in dir [%d]!\n", dir);*/ return NULL;}

// a more thorough neighbour finding system, that looks via the hypercells

Cell *Cell::findNeighbouringCell(DIRECTION dir) {
  int convDir = converseDirection(dir);
  int convParentDir = converseDirection(this->dirToParent);

  if ((dir == UP) || (dir == DOWN)) {
    // link using the appropriate level's parent cell
    checkNeighbour(dir)// we are at the edge of the hypergrid
    return this->children[PARENT]->neighbour[dir]->children[convParentDir];

  } else {

    if (this->dirToParent == UP) {
      // we are right under a root cell, so we can just use the children of our parent.
      return this->children[PARENT]->children[dir];
    } else if (dir == this->dirToParent) {
      //dirToParent + 0
      // we are looking back at the cell 'below' our parent
      //printf("\tlooking back at the 'root' cell\n");
      return this->children[PARENT]->children[DOWN];

    } else if (dir == cwNeighbour(this->dirToParent)) {
      //dirToParent + 1

      // this means the neighbour in question is linked to our own parent.
      // dir -> neighbour
      // n 0 -> p.ne 1
      // ne 1 -> p.se 2
      // se 2 -> p.s 3
      // s 3 -> p.sw 4
      // sw 4 -> p.nw 5
      // nw 5 -> p.n 0
      return this->children[PARENT]->children[ccwNeighbour(convParentDir)];
    } else if (dir == ((this->dirToParent+2)%6)) {
      //dirToParent + 2
      int pn = convParentDir;
      int cn = this->dirToParent;
      checkNeighbour(pn);// we are at the edge of the hypergrid
      return this->children[PARENT]->neighbour[pn]->children[cn];
    } else if (dir == ((this->dirToParent+3)%6)) {
      //dirToParent + 3
      // i.e. straighline away from the parent
      int pn = convParentDir;
      int cn = ccwNeighbour(this->dirToParent);
      checkNeighbour(pn); // we are at the edge of the hypergrid
      return this->children[PARENT]->neighbour[pn]->children[cn];
    } else if (dir == ((this->dirToParent+4)%6)) {
      //dirToParent + 4
      int pn = cwNeighbour(convParentDir);
      int cn = converseDirection(dir);
      checkNeighbour(pn); // we are at the edge of the hypergrid
      return this->children[PARENT]->neighbour[pn]->children[cn];
    } else if (dir == ccwNeighbour(this->dirToParent)) {
      //dirToParent + 5

      // this means the neighbour in question is linked to our own parent.
      // dir -> neighbour
      // n 0 -> p.nw 5
      // ne 1 -> p.n 0
      // se 2 -> p.ne 1
      // s 3 -> p.se 2
      // sw 4 -> p.s 3
      // nw 5 -> p.sw 4
      return this->children[PARENT]->children[cwNeighbour(convParentDir)];
    }
  }
  printf("\t!!! something bad happened. hmm.\n");
  return NULL;
}


void Cell::linkUp() {
  for (int d = 0; d < NUM_DIRECTIONS; d++) {  // N, NE, SE, S, SW, NW, UP, DOWN
    Cell *n = this->findNeighbouringCell(d);
    if (n != NULL) {
      n->neighbour[converseDirection(d)] = this;
    }
    this->neighbour[d] = n;
  }
}


/* sets the parent of THIS cell to be the given cell, and that that parent is
  in the GIVEN DIRECTION form this cell. */
void Cell::setParent(Cell *pcell, DIRECTION dir) {
  int convDir = converseDirection(dir);
  pcell->children[convDir] = this;
  this->children[PARENT] = pcell;
  this->dirToParent = dir;
  this->linkUp();
}


/* sets the given cell as a neighbour of THIS cell in the GIVEN direction */
Cell *Cell::setNeighbour(DIRECTION dir, Cell *cell) {

  if (cell == NULL) printf("The cell was NULL!!\n");

  if (frozen || cell->frozen) {
    printf("no! cell was frozen.\n");
    return NULL;
  }

  int convDir = converseDirection(dir);

  if ((neighbour[dir] != NULL) || (cell->neighbour[convDir] != NULL)) {
    // problem - either we already have a neighbour here, or the other
    // cell has a neighbour where we are.
    printf("error: a cell already exists there.\n");
    return NULL;
  } else {

    //printf("finding parent cell...\n");

    //if OUR parent is NULL, then so should this cell's parent be. we are probably
    // working at the toplevel.
    if (this->children[PARENT] == NULL) {
      //printf("working at the toplevel\n");
      // do nothing except the linking.
      this->neighbour[dir] = cell;
      cell->neighbour[convDir] = this;
      return cell;
    }

    // set the cell's hypercell.
    if ((dir == UP) || (dir == DOWN)) {
      //printf("\tup/down.\n");
      if (this->children[PARENT]->neighbour[dir] == NULL) {
        
        //
        // !!! TODO !!!
        //
        // printf("at the edge of the hypergrid!\n");
        
        return NULL; // we are at the edge of the hypergrid
      }
      cell->setParent(this->children[PARENT]->neighbour[dir], this->dirToParent);

    } else if (this->dirToParent == UP) {
      // 'this' is directly under a parent cell, so
      // cell->parent == this->parent and cell->dirtoParent = convDir
      cell->setParent(this->children[PARENT], convDir);

    } else if (dir == this->dirToParent) {
      // this means that the cell we are adding is a new one to be placed directly under a hyper cell
      // note that cell->dirToParent == ABOVE, and cell->parent->children[BELOW==6] = cell
      cell->setParent(this->children[PARENT], UP);

    } else {
      // this means that we are on an edge. we can either be on the edge of a hypercell
      // that has a cell, or an 'empty' hyper cell. I.E. we are either linking directly to a cell 'under'
      // the hypercell, or we are linking to a cell that is linked to a cell 'under' the hypercell.
      // the latter case: have we crossed into a new hypercell?

      int cwParentDir = cwNeighbour(dirToParent);
      int ccwParentDir = ccwNeighbour(dirToParent);

      int convParentDir = converseDirection(dirToParent);
      int cwConvParentDir = cwNeighbour(convParentDir);
      int ccwConvParentDir = ccwNeighbour(convParentDir);

      // we moved further away from the cell 'under' the hyper cell, so we've got to
      // link it to a new hypercell.
      if (dir == convParentDir) {
        // straight line
        if (this->children[PARENT]->neighbour[convParentDir] == NULL) {
          printf("at hypergrid edge... returning null\n");
          return NULL; // we are at the edge of the hypergrid
        }
        cell->setParent(this->children[PARENT]->neighbour[convParentDir], ccwConvParentDir);
      } else if (dir == cwConvParentDir) {
        // bend right
        if (this->children[PARENT]->neighbour[cwConvParentDir] == NULL) {
          printf("at hypergrid edge... returning null\n");
          return NULL; // we are at the edge of the hypergrid
        }
        cell->setParent(this->children[PARENT]->neighbour[cwConvParentDir], cwConvParentDir);
      } else if (dir == ccwConvParentDir) {
        // bend left
        if (this->children[PARENT]->neighbour[convParentDir] == NULL) {
          printf("at hypergrid edge... returning null\n");
          return NULL; // we are at the edge of the hypergrid
        }
        cell->setParent(this->children[PARENT]->neighbour[convParentDir], convParentDir);

      // we're adding to a secondary cell, but folding back on ourselves
      } else if (dir == cwParentDir) {
        // we're bending back on ourselves, to the left
        cell->setParent(this->children[PARENT], ccwParentDir);

      } else if (dir == ccwParentDir) {
        // we're bending back on ourselves, to the right
        cell->setParent(this->children[PARENT], cwParentDir);
      }
    }

    // we now know our hyper cell, so we need to check it and it's 6 neighbours on all 3 planes for other cells
    // that we should link to.

    cell->linkUp();

    return cell;
  }
}

/* sets an individual child of this cell, rather than a whole sublevel (see createSubLevel()) */
Cell *Cell::setChild(DIRECTION dir, Cell *cell) {
  if (cell == NULL) printf("The cell was NULL!!\n");

  if (frozen || cell->frozen) {
    printf("no! cell was frozen.\n");
    return false;
  }

  int convDir = converseDirection(dir);

  if (children[dir] != NULL) {
    printf("error: a cell already exists there.\n");
    return NULL;
  } else {
    cell->setParent(this, dir);
    return cell;
  }
}

void Cell::createSubLevel() {
  Cell *myChild = new Cell();
  //printf("[%d] created child cellId %d\n", cellId, myChild->cellId);
  myChild->setParent(this, UP); // this is the center cell underneath us
  for (int i = 0; i < 6; i++) {
    // N, NE, SE, S, SW, NW...
    Cell *newCell = new Cell();
    myChild->setNeighbour(i, newCell);
  }
}

void Cell::createNeighbourLevel() {
  for (int i = 0; i < 8; i++) {
    if (this->neighbour[i] == NULL) {
      this->setNeighbour(i, new Cell());
    }
  }
}


#define getID(n) (neighbour[n]!=NULL)?(neighbour[n]->cellId):(-1)

void Cell::print2D() {
  printf("    _     \n");
  printf("  _/%d\\_   \n", getID(0));
  printf(" /%d\\_/%d\\  \n", getID(5), getID(1));
  printf(" \\_/%d\\_/  \n", this->cellId);
  printf(" /%d\\_/%d\\  \n", getID(4), getID(2));
  printf(" \\_/%d\\_/  \n", getID(3));
  printf("   \\_/    \n");
}

void Cell::print3D() {
  if (neighbour[UP] != NULL) {
    neighbour[UP]->print2D();
  } else printf("upper level is NULL\n");
  print2D();
  if (neighbour[DOWN] != NULL) {
    neighbour[DOWN]->print2D();
  } else { printf("lower level is NULL\n"); }
}


void Cell::freeze() {
  frozen = true;
}

void Cell::freeze2D() {
  int i;
  freeze();
  for (i = 0; i < 6; i++) {
    if (neighbour[i] != NULL) neighbour[i]->freeze();
  }
}

void Cell::freeze3D() {
  freeze2D();
  if (neighbour[UP] != NULL) neighbour[UP]->freeze2D();
  if (neighbour[DOWN] != NULL) neighbour[DOWN]->freeze2D();
}

void Cell::unfreeze() {
  frozen = false;
}

void Cell::unfreeze2D() {
  int i;
  unfreeze();
  for (i = 0; i < 6; i++) {
    if (neighbour[i] != NULL) neighbour[i]->unfreeze();
  }
}

void Cell::unfreeze3D() {
  unfreeze2D();
  neighbour[UP]->unfreeze2D();
  neighbour[DOWN]->unfreeze2D();
}

