#ifndef __METAARCHITECTURE__
#define __METAARCHITECTURE__

/*#include <iostream>
#include <vector>*/

#include "Nest3.h"
#include "Cell.h"
#include "HexCell.h"

class MetaArchitecture {
  public:
    // this is confusing, i know but:
    // rootCell is the root cell of the hypertree used to create our
    // structure
    Cell *rootCell;
  
    HexCell *centreCell;

    int depth;

    HexCell *first, *last;

  
  private:
    static float RelativeCoords[8][3];
    
  public:
    static const float L = 1.0; //spacing between levels
    static const float R = 1.0; //hexagon radius
    static const float P = 1.0/2; //hexagon 'side' / 2
    static const float H = 0.866025; //hexagon 'height' / 2
    static const int SetCellCoordsLimit = 500;

  public:
    MetaArchitecture(int depth=1);
    ~MetaArchitecture();

        void deleteAllCells();

    void createHyperStructure();

    Cell *getMiddleCell();
  
    HexCell *getCell(int id);
    
    HexCell *cc() { return this->centreCell; }

    int clearEmptyCells();
    int clear(CELL_VALUE type);
    HexCell *removeCell(HexCell *cell);
    HexCell *removeCellWithoutDeleting(HexCell *cell);
    void addCell(HexCell *cell);


    int numCells();
    int numBricks();
  
    void setBricks(CELL_VALUE val=CELL_RED);

    void prepFor3DMatching();
    
    
    
    // coordinate functions
    void initCoordinates();
    void setSurroundingCellCoords(HexCell *cell, int limit=SetCellCoordsLimit);
    void setCoordinatesForCellInDir(HexCell *, DIRECTION dir);

};


#endif
