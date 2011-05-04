#ifndef __CELLDATA__
#define __CELLDATA__

#include "Nest3.h"

class CellData {
	public:
		
		static int nextCellDataId;
	
		int cellDataId;
		int id;
		CELL_VALUE value;
		int order;
		int ruleID;
	
	CellData(int i=0, CELL_VALUE v=CELL_EMPTY, int o=0, int r=-1);
	~CellData();
	
	void print();
};

#endif
