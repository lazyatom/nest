#include "Architecture.h"

Architecture::Architecture(int depth) : MetaArchitecture(depth) {
}

void Architecture::deleteRules() {
    Rule *tmp = this->lastRule;
    while (tmp != this->firstRule) {
        this->lastRule = this->lastRule->prev;
        delete tmp;
        tmp = this->lastRule;
    }
    firstRule = NULL;
    lastRule = NULL;
    delete tmp;
}


void Architecture::createRules() {

    HexCell *brick = first;
    Rule *r;
    while (brick != NULL) {
        if (!emptyCell(brick)) {
            r = new Rule();
            brick->mapOnto(r->centreCell);
            r->centreCell->filterUsingOrder();
            r->centreCell->expand2DSpaceAround();
            r->initCoordinates();
            
            	if (firstRule == NULL) {
                firstRule = r;
                lastRule = r;
            } else {
                lastRule->next = r;
                r->prev = lastRule;
                lastRule = r;
            }
            
        }
    }
}


Architecture *defaultArchitecture() {
	Architecture *a = new Architecture(30);
	for(int i = 0; i < NUM_CARDINAL_DIRECTIONS; i++)
		a->centreCell->set(i, CELL_RED);
	return a;
}