#ifndef __RULE__
#define __RULE__

#include "Nest3.h"
#include "MetaArchitecture.h"
#include "ruby.h"


class Rule : public MetaArchitecture {

    public:
        Rule *next, *prev;


        Rule(int depth=5);
        
        void p() { centreCell->print3D(); }
        void p2() { centreCell->print2D(); }
        
        int order() { return centreCell->order(); }
        
        VALUE postrulesWithCells(VALUE v);
};



#endif