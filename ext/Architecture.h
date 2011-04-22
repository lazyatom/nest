#ifndef __ARCHITECTURE__
#define __ARCHITECTURE__

#include "NestCore.h"
#include "MetaArchitecture.h"
#include "Rule.h"

//#include <vector>

class Architecture : public MetaArchitecture {

    public:
        Rule* firstRule, *lastRule;

        //vector<Rule *> rules;
    
        Architecture(int depth=5);
    
        void deleteRules();
        void createRules();

};

Architecture *defaultArchitecture();

#endif