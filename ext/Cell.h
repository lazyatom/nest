#ifndef __CELL__
#define __CELL__

#include "Nest3.h"

class Cell {

    private:
    int cellId;

  public:
    
    static int nextId;

    /* neighbours are peer-cells that this cell is linked to. i.e. is this is a
      HexCell, the neighbours are the other HexCells that exist in the phyiscal
      plane along with this one, plus the UP and DOWN cells between planes*/
    Cell *neighbour[NUM_DIRECTIONS];

    // for hyperlinking...
    Cell *children[NUM_DIRECTIONS]; // the cell 'under' this one, plus it's 6 surrounding cells

    /* this is the direction from this cell that the parent cell occupies (i.e. this direction
    from this cell which leads to a cell that is 'UNDER' the parent. */
    DIRECTION dirToParent; // dir to children[PARENT]
    bool frozen;

  
    // ************************************************************
    // methods
    //
  
    Cell();
    ~Cell();
    virtual Cell *getNeighbour(DIRECTION dir);
    virtual Cell *setNeighbour(DIRECTION dir, Cell *cell);

        int getCellId() { return this->cellId; }

    Cell *getChild(DIRECTION dir);
    Cell *setChild(DIRECTION dir, Cell *cell);
    void setParent(Cell *pcell, DIRECTION dir); // TODO: change order of parameters

    Cell *findNeighbouringCell(DIRECTION dir);

    void createSubLevel();
    void createNeighbourLevel();

    void linkUp();

    void detach();
    void unlink();

    virtual void freeze();
    virtual void freeze2D();
    virtual void freeze3D();

    virtual void unfreeze();
    virtual void unfreeze2D();
    virtual void unfreeze3D();

    virtual void print2D();
    virtual void print3D();

};


#endif
