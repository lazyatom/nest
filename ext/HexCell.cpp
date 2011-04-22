#include "HexCell.h"





// these macros operate on CELL_VALUE data
#define emptyOrFilled(val) \
    (((val==CELL_NIL)||(val==CELL_EMPTY))?CELL_EMPTY:CELL_UNDEFINED)
#define emptyOrValue(val) \
    (((val==CELL_NIL)||(val==CELL_EMPTY))?CELL_EMPTY:val)


// these functions operate on cell objects (that may be NULL)
CELL_VALUE valueOfCell(HexCell *cell) {
	if (cell == NULL)
		return CELL_EMPTY;

	return emptyOrValue(cell->value());
}

bool emptyCell(HexCell *cell) {
    if (cell != NULL)
        return cell->isEmpty();
    return true;
}






HexCell::HexCell(CELL_VALUE v, MetaArchitecture *arch) {
	
	data = new CellData(this->getCellId(), v, 1);

	x = y = z = 0;
	coordsSet = false;

	next = prev = NULL;

	myArch = arch;
	if (myArch != NULL) myArch->addCell(this);
}


HexCell::~HexCell() { }



/* GET/SET */
CELL_VALUE HexCell::value() { return data->value; }
bool HexCell::setValue(CELL_VALUE val) {
	if (frozen) { return false;
	} else { data->value = val; return true; }
}

int HexCell::order() { return data->order; }
void HexCell::setOrder(int o) { data->order = o; }

int HexCell::id() { return data->id; }
void HexCell::setId(int id) { data->id = id; }

int HexCell::ruleID() { return data->ruleID; }
void HexCell::setRuleID(int r) { data->ruleID = r; }

int HexCell::cellDataId() { return data->cellDataId; }

void HexCell::setCoords(double cx, double cy, double cz) {
	x = cx; y = cy; z = cz; coordsSet = true;
}




bool HexCell::isEmpty() { 
    return ((value() == CELL_EMPTY) || (value() == CELL_NIL));
}

bool HexCell::isDefined() {
    return (value() != CELL_UNDEFINED);
}

bool HexCell::isDifferentiatedFrom(HexCell *cell) {
    if (cell == NULL)
        return (this->isDefined() && !this->isEmpty()); // not sure about this.
    if (!this->isDefined() && !cell->isDefined() && 
        (this->value() != cell->value()))
        return true;
    if (this->id() == cell->id())
        return true;
    
    return false;
}






HexCell *HexCell::getNeighbour(DIRECTION dir) { 
    return (HexCell *)Cell::getNeighbour(dir); 
}
HexCell *HexCell::get(DIRECTION dir) { return getNeighbour(dir); }


/*
	A helper function to quickly get a valid value for some
	neighbour of this cell. if there is no cell, it returns
	CELL_NIL
*/
CELL_VALUE HexCell::getNeighbourValue(DIRECTION dir) {
	if (getNeighbour(dir) != NULL)
		return getNeighbour(dir)->value();
	else
		return CELL_NIL;
}

HexCell *HexCell::setNeighbour(DIRECTION dir, HexCell *cell) {
	HexCell *x = (HexCell *)Cell::setNeighbour(dir, cell);
	myArch->setCoordinatesForCellInDir(this, dir); // set the coordinates, only go one level deep.
		
	return x;
}

/* this will add a new neighbour, or set the value of the existing neighbour */
HexCell *HexCell::set(DIRECTION dir, CELL_VALUE val) {
	HexCell *tmp = getNeighbour(dir);
	if (tmp == NULL) {
		tmp = new HexCell(val, this->myArch);
		HexCell *result = setNeighbour(dir, tmp);
		if (result == NULL) {
			this->myArch->removeCell(tmp);
		}
		return result;
	} else {
		tmp->setValue(val);
		return tmp;
	}
}



/* returns true only if the given value 'val' is a subset of this cells cell_value */
bool HexCell::matchValue(CELL_VALUE val) {
	if ((val == CELL_NIL) && (value() == CELL_EMPTY)) return true; //Shoudl this use isempty?
	return matchCellValue(value(), val);
}



/************************** equals **************************/

bool HexCell::equals(HexCell *cell) {
	if (cell == NULL) return false;
	return (value() == cell->value());
}

bool HexCell::equals2D(HexCell *cell) {
	if (cell == NULL) return false;

	if (!equals(cell)) return false;
	for (int i = 0; i < NUM_CARDINAL_DIRECTIONS; i++) {
		if (cell->getNeighbour(i) == NULL) { 
		  if (getNeighbour(i) != NULL) return false;
		} else if (getNeighbour(i) == NULL) { 
		  return false;
		} else if (!getNeighbour(i)->equals(cell->getNeighbour(i))) 
		  return false;
	}
	return true;
}

bool HexCell::equals3D(HexCell *cell) {
	if (cell == NULL) return false;

    prepFor3DMatching(); cell->prepFor3DMatching();

	return (equals2D(cell) &&
            getNeighbour(UP)->equals2D(cell->getNeighbour(UP)) &&
            getNeighbour(DOWN)->equals2D(cell->getNeighbour(DOWN)));
}



/*********************** Matches *********************/

/* 
	if cell is NULL or CELL_NIL, we probably don't know what the actual
	cell is, so we should assume that is a match.
*/
bool HexCell::matches(HexCell *cell) {		
	if ((cell == NULL) || (cell->value() == CELL_NIL)) 
		return true;
	if (value() == CELL_UNDEFINED)
	   return (emptyOrFilled(cell->value()) == this->value());
    if (cell->value() == CELL_UNDEFINED)
        return (emptyOrFilled(this->value()) == cell->value());
    if (this->isEmpty())
        return cell->isEmpty();
    if (cell->isEmpty())
        return this->isEmpty();
    return (this->value() == cell->value());
}

bool HexCell::matches2D(HexCell *cell, int rotation, bool matchCenter) {
	if (matchCenter && !this->matches(cell)) {
		//printf("centre clash!\n");
		return false;
	}
	
	for (int i = 0; i < NUM_CARDINAL_DIRECTIONS; i++) {
        HexCell *tmpCell = this->get((i+rotation)%NUM_CARDINAL_DIRECTIONS);
        if ((tmpCell != NULL) && !tmpCell->matches(cell->get(i))) {
			//printf("cell %d != cell %d [%d != %d]\n", tmpCell->id(),
			//	   cell->id(), tmpCell->value(), cell->value());
            return false;
        }
        if ((tmpCell == NULL) && // tmpCell is presumed to be empty
            !emptyCell(cell->get(i))) {
            return false;
        }
    }	
    return true;	
}

bool HexCell::matches3D(HexCell *cell, int rotation, bool matchCenter) {
	if (cell == NULL) return false;
		
	prepFor3DMatching(); cell->prepFor3DMatching();
	
	if (!getNeighbour(UP)->matches2D(cell->getNeighbour(UP), rotation)) 
	   return false;
	if (!matches2D(cell, rotation, matchCenter)) return false;
	if (!getNeighbour(DOWN)->matches2D(cell->getNeighbour(DOWN), rotation)) 
	   return false;
	
	return true;	
}


/*
 *************************************************************
 * Misc Functions
 **************************************************************/

void HexCell::print2D() {
	printf("    _     \n");
	printf("  _/%d\\_   \n", getNeighbourValue(N));
	printf(" /%d\\_/%d\\  \n", getNeighbourValue(NW), getNeighbourValue(NE));
	printf(" \\_/%d\\_/  \n", this->value());
	printf(" /%d\\_/%d\\  \n", getNeighbourValue(SW), getNeighbourValue(SE));
	printf(" \\_/%d\\_/  \n", getNeighbourValue(S));
	printf("   \\_/    \n");
}

#define up(dir) (get(UP)==NULL)?(0):(get(UP)->getNeighbourValue(dir))
#define down(dir) (get(DOWN)==NULL)?(0):(get(DOWN)->getNeighbourValue(dir))
#define upValue() (get(UP)==NULL)?(0):(get(UP)->value())
#define downValue() (get(DOWN)==NULL)?(0):(get(DOWN)->value())

void HexCell::print3D() {
	
	printf("  u _       _     d _\n");
	printf("  _/%d\\_   _/%d\\_   _/%d\\_\n", up(N), getNeighbourValue(N), down(N));
	printf(" /%d\\_/%d\\ /%d\\_/%d\\ /%d\\_/%d\\\n", up(NW), up(NE), getNeighbourValue(NW), getNeighbourValue(NE), down(NE), down(NW));
	printf(" \\_/%d\\_/ \\_/%d\\_/ \\_/%d\\_/\n", upValue(), this->value(), downValue());
	printf(" /%d\\_/%d\\ /%d\\_/%d\\ /%d\\_/%d\\\n", up(SW), up(SE), getNeighbourValue(SW), getNeighbourValue(SE), down(SW), down(SE));
	printf(" \\_/%d\\_/ \\_/%d\\_/ \\_/%d\\_/\n", up(S), getNeighbourValue(S), down(S));
	printf("   \\_/     \\_/     \\_/\n");	
	
}


/* this function could probably be avoided by automatically creating the
    empty UP/DOWN cells upon creation of a new cell. 
    the cell is set to CELL_NIL to indicate that it doesn't really exist,
    and can't be moved into by agents
*/
void HexCell::prepFor3DMatching() {
	if (getNeighbour(UP) == NULL) { set(UP, CELL_NIL); }
	if (getNeighbour(DOWN) == NULL) { set(DOWN, CELL_NIL); }
}

void HexCell::expandSpaceAround() {
	prepFor3DMatching();
	
	expand2DSpaceAround();
	if (get(UP)->isEmpty()) { get(UP)->setValue(CELL_EMPTY); }
	get(UP)->expand2DSpaceAround();
	if (get(DOWN)->isEmpty()) { get(DOWN)->setValue(CELL_EMPTY); }
	get(DOWN)->expand2DSpaceAround();
}

void HexCell::expand2DSpaceAround() {
	HexCell *tmp = this;
	for (int dir = 0; dir < NUM_CARDINAL_DIRECTIONS; dir++)
		if ((tmp->get(dir) == NULL) || 
		  (tmp->get(dir)->value() == CELL_NIL))
			tmp->set(dir, CELL_EMPTY);
	myArch->setSurroundingCellCoords(this);
}


void HexCell::replaceData(CellData *newData) {	
	delete data; data = newData;
}

void HexCell::mapOnto(HexCell *cell) {
	if (cell == NULL) return;
	
	prepFor3DMatching();
	cell->prepFor3DMatching();
	
	cell->replaceData(this->data);
	
	HexCell *tmp = NULL;
	HexCell *other = NULL;
	for (int dir = 0; dir < 8; dir++) {
		tmp = get(dir);
		if (tmp != NULL) {
			// create the cell, tho it's data will soon be replaced
			other = cell->set(dir, tmp->value()); 
			other->replaceData(tmp->data);
		}
	}
	
	for (int dir = 0; dir < NUM_CARDINAL_DIRECTIONS; dir++) {
        // get our upper root cell, get(UP) != NULL because of
        // prepFor3DMatching
		tmp = get(UP)->get(dir); 
		if (tmp != NULL) {
			other = cell->get(UP)->set(dir, tmp->value());
			other->data = tmp->data;
		}
		tmp = get(DOWN)->get(dir); // get our lower root cell, get(DOWN) != NULL because of prepFor3DMatching
		if (tmp != NULL) {
			other = cell->get(DOWN)->set(dir, tmp->value());
			other->data = tmp->data;
		}
	}
}

void HexCell::filterUsingOrder() {
	
	prepFor3DMatching();
	
	HexCell *tmp = NULL;
	for (int dir = 0; dir < NUM_CARDINAL_DIRECTIONS; dir++) {
		tmp = get(dir);
		if (tmp != NULL) {
			if (order() < tmp->order()) {
				myArch->removeCell(tmp); // deleting CellData would be bad.
			}
		}
	}
	
	HexCell *upCell = get(UP);
	HexCell *downCell = get(DOWN);
	for (int dir = 0; dir < NUM_CARDINAL_DIRECTIONS; dir++) {
		tmp = upCell->get(dir);
		if (tmp != NULL) {
			if (order() < tmp->order()) {
				myArch->removeCell(tmp);
			}
		}
		tmp = downCell->get(dir);
		if (tmp != NULL) {
			if (order() < tmp->order()) {
				myArch->removeCell(tmp);
			}
		}
	}
	
	// finally check up & down; we needed them present up until now.
	if (order() < downCell->order())
		myArch->removeCell(downCell);
	if (order() < upCell->order())
		myArch->removeCell(upCell);
}







/***************** RUBY CODE ****************/

HexCell *HexCell::getWithList(VALUE list) {
    HexCell *tmp = this;
    int dir = DIRECTION_ERROR;
    
    Check_Type(list, T_ARRAY);
    
    long len = RARRAY(list)->len;
    
    /*if (len == 2) {
        VALUE entry1 = rb_ary_entry(list, 0);
        VALUE entry2 = rb_ary_entry(list, 1);
        int val1 = (entry1 == Qnil)?DIRECTION_NIL:FIX2INT(entry1);
        int val2 = (entry2 == Qnil)?DIRECTION_NIL:FIX2INT(entry2);
        printf("val1 = %d, val2 = %d\n", val1, val2);
        return getWithListFAST(val1, val2);
    }*/
    
    for (long i = 0; i < len; i++) {
        VALUE entry = rb_ary_entry(list, i);
        if (entry != Qnil) {
            dir = FIX2INT(entry);
            //printf("going from cell %d in dir %d\n", tmp->id(), dir);
            tmp = tmp->get(dir);
            if (tmp == NULL) return NULL;
            //else printf("got: %d.\n", tmp->id());
        }
    }
    return tmp;
}

/* WARNING! this doesn't handle NIL values from ruby. */
HexCell *HexCell::getWithListFAST(int dir1, int dir2) {
    //printf("FAST called with %d, %d\n",dir1,dir2);
    HexCell *tmp = this;
    if (dir1 > DIRECTION_NIL) // ignore that
        if (dir1 < 8) tmp = get(dir1);
        //else return NULL; // skip over this even if it is NULL
    if (dir2 > DIRECTION_NIL) // ignore
        if (dir2 < 8) tmp = tmp->get(dir2);
        else return NULL;
        
    return tmp;
}