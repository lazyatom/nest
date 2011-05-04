%module "Nest3"
%{
#include "Cell.h"
#include "HexCell.h"
#include "Nest3.h"
#include "CellData.h"
#include "MetaArchitecture.h"
#include "Architecture.h"
#include "Rule.h"
%}

%include Cell.h
%include CellData.h
%include HexCell.h
%include Nest3.h
%include MetaArchitecture.h
%include Architecture.h
%include Rule.h