#include "CellData.h"


// initialise the static cell ID
int CellData::nextCellDataId = 0;

CellData::CellData(int i, CELL_VALUE v, int o, int r) {
	id = i; value = v; order = o; ruleID = r;
	cellDataId = CellData::nextCellDataId++;
};

CellData::~CellData() { }

void CellData::print() {
	printf("id=%d, order=%d, value=%d [%d]\n", id, order, value, cellDataId);
}
