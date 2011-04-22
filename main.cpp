#include "NestCore/NestCore.h"
#include "NestCore/Architecture.h"
#include "NestCore/HexCell.h"

int main() {
	
    Architecture *a = new Architecture();
    Architecture *b = new Architecture();
	
	a->centreCell->setValue(CELL_RED);
	
	b->centreCell->setValue(CELL_RED);
	b->centreCell->set(NE, CELL_RED);
	b->centreCell->set(S, CELL_RED);
	
	a->centreCell->expandSpaceAround();
	b->centreCell->expandSpaceAround();
	
	HexCell *sw = a->centreCell->get(SW);
	HexCell *n = a->centreCell->get(N);
	
	
	bool bsw = b->centreCell->matches3D(sw, 0, false);
	bool bn = b->centreCell->matches3D(n, 0, false);

	if (bsw) printf("matched SW.\n");

	if (bn) printf("matched N.\n");
	
}