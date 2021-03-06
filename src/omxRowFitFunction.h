/*
 *  Copyright 2007-2016 The OpenMx Project
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#ifndef _OMX_ROW_FITFUNCTION_
#define _OMX_ROW_FITFUNCTION_ TRUE

#include "omxDefines.h"
#include "omxSymbolTable.h"
#include "omxData.h"
#include "omxFIMLFitFunction.h"

void omxDestroyRowFitFunction(omxFitFunction *oo);

omxRListElement* omxSetFinalReturnsRowFitFunction(omxFitFunction *oo, int *numReturns);


void omxCopyMatrixToRow(omxMatrix* source, int row, omxMatrix* target);

void omxInitRowFitFunction(omxFitFunction* oo);





#endif /* _OMX_ROW_FITFUNCTION_ */
