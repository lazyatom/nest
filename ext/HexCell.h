#ifndef __HEXCELL__
#define __HEXCELL__


#include "NestCore.h"
#include "Cell.h"
#include "MetaArchitecture.h"
#include "CellData.h"

#include "ruby.h"

// helper functions which might operate on NULL
CELL_VALUE valueOfCell(HexCell *cell);
bool emptyCell(HexCell *cell);


class HexCell : public Cell {

	private:
		CellData *data;
		double x, y, z;
		MetaArchitecture *myArch;

	public:
		bool coordsSet;
	
		HexCell *next, *prev;

	public:

		HexCell(CELL_VALUE v=CELL_EMPTY, MetaArchitecture *arch=NULL);
		~HexCell();

		HexCell *getNeighbour(DIRECTION dir);
		HexCell *get(DIRECTION dir);
		HexCell *setNeighbour(DIRECTION dir, HexCell *cell);
		HexCell *set(DIRECTION dir, CELL_VALUE val);


    HexCell *n() { return get(N); }
    HexCell *ne() { return get(NE); }
    HexCell *nw() { return get(NW); }
    HexCell *se() { return get(SE); }
    HexCell *sw() { return get(SW); }
    HexCell *s() { return get(S); }
    HexCell *up() { return get(UP); }
    HexCell *down() { return get(DOWN); }


		CELL_VALUE value();
		bool setValue(CELL_VALUE val);

		int order();
		void setOrder(int o);

        // returns the common ID for this cell	
		int id();
		void setId(int id);

        // returns the OBJECT ID of the cellData object
        // i.e. Cells with identical cellDataIds share the same data
        // and therefore correspond to the same Cell.		
		int cellDataId();
	
        // this modifies the information regarding the rule
        // which placed a brick in this cell
		int ruleID();
		void setRuleID(int r);

		bool isEmpty();
		bool isDefined();
		bool isDifferentiatedFrom(HexCell *cell);
	
		void replaceData(CellData *newData);
		
		void setCoords(double cx, double cy, double zc);
		double getX() { return x; }
		double getY() { return y; }
		double getZ() { return z; }

		CELL_VALUE getNeighbourValue(DIRECTION dir);

		void prepFor3DMatching();
		void expandSpaceAround();
		void expand2DSpaceAround();
		
		bool matches(HexCell *cell);
		bool matches2D(HexCell *cell, int rotation=0, bool matchCenter=true);
		bool matches3D(HexCell *cell, int rotation=0, bool matchCenter=true);

		bool matchValue(CELL_VALUE val);

		bool equals(HexCell *cell);
		bool equals2D(HexCell *cell);
		bool equals3D(HexCell *cell);

		void print2D();
		void print3D();
		
		// produce a copy of the structure of this cell's neighbourhood
		// but sharing the cell data information
		void mapOnto(HexCell *cell);
		
		// remove cells from out neighbourhood which are ordered after
		// this one.
		void filterUsingOrder();
		
		
		/********** RUBY *********/
		HexCell *getWithList(VALUE list);
		HexCell *getWithListFAST(int dir1, int dir2);
		
};

#endif
