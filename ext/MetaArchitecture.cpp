#include "MetaArchitecture.h"

int debuglevel = 0;

MetaArchitecture::MetaArchitecture(int archDepth) {
  centreCell = NULL;
  rootCell = NULL;

  first = NULL;
  last = NULL;

  depth = archDepth;
  if (depth < 3) depth = 3; // must have UP/DOWN planes.
  
  createHyperStructure();
}

MetaArchitecture::~MetaArchitecture() {
    deleteAllCells();
}

void MetaArchitecture::deleteAllCells() {
  // delete all cells.
  //printf(".");
  HexCell *tmp = first;
  while (tmp != NULL) {
    //printf("\t->removing cell %d\n", tmp->cellId);
    tmp = removeCell(tmp);
    //if (tmp == NULL) printf("\t->tmp == NULL now.\n");
    //else printf("\t->tmp is now cell %d\n", tmp->cellId);
  }
  //fflush(stdout);
}

void MetaArchitecture::createHyperStructure() {

    deleteAllCells(); // in case we are recreating ;)
    Cell *oldFirst = this->first;
    this->first = NULL;
    delete oldFirst; // plus we are dumping the original firstcell
                    // (something which is protected during the normal
                    //  delete process)

  Cell *currentLevelRoot = NULL;
  rootCell = new Cell();
  currentLevelRoot = rootCell;

  for (int d = 0; d < depth;
    d++, currentLevelRoot = currentLevelRoot->neighbour[DOWN]) {

    //printf("==============\nmoving down to level %d\n===========\n", d);

    //if (currentLevelRoot == NULL) printf("SHIT!!\n");

    // this expands the level to have a capacity 7^2 children, diameter 3^2
    currentLevelRoot->createSubLevel();

    // now the total capacity is 7^3 children, diameter 3^3
    for (int i = 0; i < 7; i++) {
      //printf("expanding child %d [%d] of cell %d\n", i, rootCell->children[i]->id, rootCell->id);
      currentLevelRoot->children[i]->createSubLevel();
    }

    // now the total capacity is 7^4 children, diameter 3^4
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 7; j++) {
        //rootCell->children[i]->children[j]->print2D();
        //printf("expanding child %d [%d] of cell %d [%d]\n", j, rootCell->children[i]->children[j]->id, i, rootCell->children[i]->id);
        currentLevelRoot->children[i]->children[j]->createSubLevel();
      }
    }

    // do this on every level except the last one...
    // prepare the level below... it will have an initial capacity of 7^1 children, diameter 3^1
    if (d < depth-1) currentLevelRoot->setNeighbour(DOWN, new Cell());
  }

  Cell *topCell = getMiddleCell();
  centreCell = new HexCell(CELL_EMPTY, this);
  centreCell->setParent(topCell, UP);
}


Cell *MetaArchitecture::getMiddleCell() {
  int myDepth = (int) floor(this->depth/2);
  Cell *tempCell = rootCell;

  while (tempCell->children[DOWN] != NULL) tempCell = tempCell->children[DOWN];

  // now tempCell is a pointer to the hypercell at teh top of our hyperstructure.
  //printf("tempCell is now at id: %d\n", tempCell->id);

  for (int i = 0; i < myDepth; i++)
    tempCell = tempCell->neighbour[DOWN];

  return tempCell;
}

int MetaArchitecture::clearEmptyCells() {
  return clear(CELL_EMPTY);
  //printf("architecture: cleared. size now %d\n", numCells());
}

/*
  TODO: what effects does removing cells have on mapped cells?
*/
int MetaArchitecture::clear(CELL_VALUE type) {
  HexCell *tmp = first;
  while (tmp != NULL) {
    if (tmp->matchValue(type)) {
      tmp = removeCell(tmp);
    } else {
      tmp = tmp->next;
    }
  }
  //printf("architecture: cleared. size now %d\n", numCells());
}

void MetaArchitecture::addCell(HexCell *cell) {
  //printf("architecture: adding cell %d\n", cell->id());
  if (first == NULL) {
    first = cell;
    last = cell;
  } else {
    last->next = cell;
    cell->prev = last;
    last = cell;
  }
  //printf("architecture: added. size now %d\n", numCells());
}


HexCell *MetaArchitecture::removeCell(HexCell *cell) {
  //printf("architecture: removing cell %d [f:%d; l:%d]\n", cell->id(), first->id(), last->id());
  if (cell == first) {
    //printf("trying to delete the first cell...\n");
    /* the first cell is the centreCell.
      currently let's not let that be destroyed, ok?
    */
    //first = cell->next;
    HexCell *tmp = cell->next;
    //delete cell;
    return tmp;
  } else if (cell == last) {
    //printf("trying to delete the last cell...\n");
    last = cell->prev; // this is the new last cell
    last->next = NULL;
    //printf("\tlast now %d\n", last->id());
    delete cell;
    return NULL;
  } else {
    //printf("removing from the middle...\n");
    cell->prev->next = cell->next; // set the next of our previous to our next
    cell->next->prev = cell->prev; // set the previous of our next to our previous
    HexCell *tmp = cell->next; // get a pointer to the next cell
    delete cell; // delete us
    return tmp; // return the next cell.
  }
  //printf("architecture: cell removed. size now: %d\n", numCells());
}

HexCell *MetaArchitecture::removeCellWithoutDeleting(HexCell *cell) {
  //printf("architecture: removing cell %d WITHOUT DELETING [f:%d; l:%d]\n", cell->id(), first->id(), last->id());
  if (cell == first) {
    //printf("trying to delete the first cell...\n");
    HexCell *tmp = cell->next;
    return tmp;
  } else if (cell == last) {
    //printf("removing the last cell...\n");
    last = cell->prev; // this is the new last cell
    last->next = NULL;
    //printf("last is now %d\n", last->id());
    return NULL;
  } else {
    //printf("removing from the middle...\n");
    cell->prev->next = cell->next; // set the next of our previous to our next
    cell->next->prev = cell->prev; // set the previous of our next to our previous
    HexCell *tmp = cell->next; // get a pointer to the next cell
    return tmp; // return the next cell.
  }
  //printf("architecture: cell removed. size now: %d\n", numCells());
}

int MetaArchitecture::numCells() {
  HexCell *tmp = first;
  int num;
  for (num = 0; tmp != NULL; num++, tmp = tmp->next);
  return num;
}

int MetaArchitecture::numBricks() {
  HexCell *tmp = first;
  int num;
  //printf("numBricks...\n");
  for (num = 0; tmp != NULL; tmp = tmp->next) {
    //if (tmp == NULL) printf("tmp is NULL in numBricks()!\n");
    //printf("getting value...\n");
    //tmp->value();
    //printf("got value\n");
    ((tmp->value() != CELL_EMPTY) && (tmp->value() != CELL_NIL))?(num++):(num);
  }
  //printf("numBricks got %d\n", num);
  return num;
}

HexCell *MetaArchitecture::getCell(int id) {
  for (HexCell *tmp = first; tmp != NULL; tmp = tmp->next) {
    if (tmp->id() == id) 
      return tmp;
  }
  return NULL;
}

void MetaArchitecture::setBricks(CELL_VALUE val) {
  for(HexCell *cell = first; cell != NULL; cell = cell->next)
    if ((cell->value() != CELL_EMPTY) && (cell->value() != CELL_NIL))
      cell->setValue(val);
}

void MetaArchitecture::prepFor3DMatching() {
  HexCell *tmp = first;
  while (tmp != NULL) {
    if (tmp->value() != CELL_EMPTY) {
      tmp->prepFor3DMatching();
    }
    tmp = tmp->next;
  }
}

float MetaArchitecture::RelativeCoords[8][3] =  {{2*H/2, 0, 0},
                  {H/2, (R+P)/2, 0},
                  {-H/2, (R+P)/2, 0},
                  {-2*H/2, 0, 0},
                  {-H/2, -(R+P)/2, 0},
                  { H/2, -(R+P)/2, 0},
                  {0, 0, -L/2},
                  {0, 0, L/2}};


void MetaArchitecture::initCoordinates() {
  centreCell->setCoords(0,0,0);
  setSurroundingCellCoords(centreCell, 0);
}

void MetaArchitecture::setSurroundingCellCoords(HexCell *cell, int depth) {

  if (depth > MetaArchitecture::SetCellCoordsLimit) return;
  
  HexCell *newcell = NULL;

  for (int dir = 0; dir < NUM_DIRECTIONS; dir++) {
    newcell = cell->getNeighbour(dir);
    if ((newcell != NULL) && (!newcell->coordsSet)) {  //need to think of a better tree traversal
      newcell->setCoords(cell->getX() + RelativeCoords[dir][0],\
                  cell->getY() + RelativeCoords[dir][1],\
                  cell->getZ() + RelativeCoords[dir][2]);
      setSurroundingCellCoords(newcell, depth+1);
    }
  }
}

void MetaArchitecture::setCoordinatesForCellInDir(HexCell *cell, DIRECTION dir) {
    HexCell *newcell = cell->getNeighbour(dir);
    if ((newcell != NULL) && (!newcell->coordsSet)) {  //need to think of a better tree traversal
      newcell->setCoords(cell->getX() + RelativeCoords[dir][0],\
                  cell->getY() + RelativeCoords[dir][1],\
                  cell->getZ() + RelativeCoords[dir][2]);
    } 
}



