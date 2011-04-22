%module NestCore
%{
#include "Cell.h"
#include "HexCell.h"
#include "NestCore.h"
#include "CellData.h"
#include "MetaArchitecture.h"
#include "Architecture.h"
#include "Rule.h"
%}

%include Cell.h
%include CellData.h
%include HexCell.h
%include NestCore.h
%include MetaArchitecture.h
%include Architecture.h
%include Rule.h