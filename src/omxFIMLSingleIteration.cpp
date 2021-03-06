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


#include "omxDefines.h"
#include "omxSymbolTable.h"
#include "omxData.h"
#include "omxFIMLFitFunction.h"

#pragma GCC diagnostic warning "-Wshadow"

void omxFIMLAdvanceJointRow(int *row, int *numIdenticalDefs, 
	int *numIdenticalContinuousMissingness,
	int *numIdenticalOrdinalMissingness, 
	int *numIdenticalContinuousRows,
	omxFIMLFitFunction *obj, int numDefs, int numIdentical) {

	int rowVal = *row;

	auto& identicalDefs = obj->identicalDefs;
	auto& identicalMissingness = obj->identicalMissingness;
	auto& identicalRows = obj->identicalRows;

	if(*numIdenticalDefs <= 0)
		*numIdenticalDefs = identicalDefs[rowVal];
	if(*numIdenticalContinuousMissingness <= 0)
		*numIdenticalContinuousMissingness = identicalMissingness[rowVal];
	if(*numIdenticalOrdinalMissingness <= 0)
		*numIdenticalOrdinalMissingness = identicalMissingness[rowVal];
	if(*numIdenticalContinuousRows <= 0)
		*numIdenticalContinuousRows = identicalRows[rowVal];

	*row += numIdentical;
	*numIdenticalDefs -= numIdentical;
	*numIdenticalContinuousMissingness -= numIdentical;
	*numIdenticalContinuousRows -= numIdentical;
	*numIdenticalOrdinalMissingness -= numIdentical;
}


/**
 * The localobj state cannot be accessed from other threads.
 *
 * All threads can access sharedobj. No synchronization mechanisms are
 * employed to maintain consistency of sharedobj references.
 *
 * Because (1) these functions may be invoked with arbitrary 
 * rowbegin and rowcount values, and (2) the log-likelihood
 * values for all data rows must be calculated (even in cases
 * of errors), this function is forbidden from return()-ing early.
 *
 * As another consequence of (1) and (2), if "rowbegin" is in
 * the middle of a sequence of identical rows, then defer
 * move "rowbegin" to after the sequence of identical rows.
 * Grep for "[[Comment 4]]" in source code.
 */
bool omxFIMLSingleIterationJoint(FitContext *fc, omxFitFunction *localobj,
				 omxMatrix *rowLikelihoods, int rowbegin, int rowcount)
{
	omxFIMLFitFunction* ofo = ((omxFIMLFitFunction*) localobj->argStruct);
	omxFIMLFitFunction* shared_ofo = ofo->parent? ofo->parent : ofo;
	
	double Q = 0.0;
	int numIdenticalDefs = 0, numIdenticalOrdinalMissingness = 0,
		numIdenticalContinuousMissingness = 0, numIdenticalContinuousRows = 0;
	
	omxMatrix *cov, *means, *smallRow, *smallCov, *smallMeans, *RCX;
	omxMatrix *ordMeans, *ordCov, *contRow;
	omxMatrix *halfCov, *reduceCov, *ordContCov;
	omxData* data;
	
	// Locals, for readability.  Compiler should cut through this.
	cov 		= ofo->cov;
	means		= ofo->means;
	smallRow 	= ofo->smallRow;
	smallCov 	= ofo->smallCov;
	smallMeans	= ofo->smallMeans;
	ordMeans    = ofo->ordMeans;
	ordCov      = ofo->ordCov;
	contRow     = ofo->contRow;
	halfCov     = ofo->halfCov;
	reduceCov   = ofo->reduceCov;
	ordContCov  = ofo->ordContCov;
	RCX 		= ofo->RCX;
	
	data		= ofo->data;
	int numDefs = data->defVars.size();
	
	omxExpectation* expectation = localobj->expectation;
	auto dataColumns	= expectation->getDataColumns();
	omxMatrix *thresholdsMat = expectation->thresholdsMat;
	std::vector< omxThresholdColumn > &thresholdCols = expectation->thresholds;

	OrdinalLikelihood &ol = ofo->ol;
	ol.attach(dataColumns, data, expectation->thresholdsMat, expectation->thresholds);
	Eigen::ArrayXi ordBuffer(dataColumns.size());
	
	Eigen::VectorXi ordRemove(cov->cols);
	Eigen::VectorXi contRemove(cov->cols);
	char u = 'U', l = 'L';
	int info;
	double determinant = 0.0;
	double oned = 1.0, zerod = 0.0, minusoned = -1.0;
	int onei = 1;
	double likelihood;
	
	auto& indexVector = shared_ofo->indexVector;
	auto& identicalRows = shared_ofo->identicalRows;
	bool firstRow = true;
	int row = rowbegin;
	
	// [[Comment 4]] moving row starting position
	if (row > 0) {
		int prevIdentical = identicalRows[row - 1];
		row += (prevIdentical - 1);
	}
	
	int numContinuous = 0;
	int numOrdinal = 0;
	
	while(row < data->rows && (row - rowbegin) < rowcount) {
		mxLogSetCurrentRow(row);
		int numIdentical = identicalRows[row];
		
		omxDataRow(data, indexVector[row], dataColumns, smallRow);
		
		if (ofo->isStateSpace) {
			omxSetExpectationComponent(expectation, localobj, "y", smallRow);
		}
		//If the expectation is a state space model then
		// set the y attribute of the state space expectation to smallRow.
		
		if(numIdenticalDefs <= 0 || numIdenticalContinuousMissingness <= 0 || numIdenticalOrdinalMissingness <= 0 || 
		   firstRow || ofo->isStateSpace) {  // If we're keeping covariance from the previous row, do not populate 
			// Handle Definition Variables.
			if((numDefs && numIdenticalDefs <= 0) || firstRow || ofo->isStateSpace) {
				if(OMX_DEBUG_ROWS(row)) { mxLog("Handling Definition Vars."); }
				bool numVarsFilled = expectation->loadDefVars(indexVector[row]);
				if (numVarsFilled || firstRow || ofo->isStateSpace) {
					if(row == 0 && ofo->isStateSpace) {
						if(OMX_DEBUG){ mxLog("Resetting State Space state (x) and error cov (P)."); }
						omxSetExpectationComponent(expectation, localobj, "Reset", NULL);
					}
					omxExpectationCompute(fc, expectation, NULL);
				}
			}
			// Filter down correlation matrix and calculate thresholds.
			// TODO: If identical ordinal or continuous missingness, ignore only the appropriate columns.
			numContinuous = 0;
			numOrdinal = 0;
			for(int j = 0; j < dataColumns.size(); j++) {
				int var = dataColumns[j];
				// TODO: Might save time by preseparating ordinal from continuous.
				if (omxDataElementMissing(data, indexVector[row], var)) {
					ordRemove[j] = 1;
					contRemove[j] = 1;
					if(OMX_DEBUG_ROWS(row)) { 
						mxLog("Row %d, column %d : NA", row, j);
					}
					continue;
				}
				else if (omxDataColumnIsFactor(data, var)) {
					++numOrdinal;
					ordRemove[j] = 0;
					contRemove[j] = 1;
					if(OMX_DEBUG_ROWS(row)) { 
						mxLog("Row %d, column %d : Ordinal", row, j);
					}
				} 
				else {
					++numContinuous;
					ordRemove[j] = 1;
					contRemove[j] = 0;
					if(OMX_DEBUG_ROWS(row)) { 
						mxLog("Row %d, column %d : Continuous", row, j);
					}
				}
			}
			
			if(OMX_DEBUG_ROWS(row)) {
				mxLog("Removals: %d ordinal, %d continuous out of %d total.",
				      dataColumns.size() - numOrdinal, dataColumns.size() - numContinuous,
				      dataColumns.size());
			}

			if (thresholdsMat) {
				omxRecompute(thresholdsMat, fc);
				for(int j=0; j < dataColumns.size(); j++) {
					int var = dataColumns[j];
					if (!omxDataColumnIsFactor(data, var)) continue;
					if (!thresholdsIncreasing(thresholdsMat, thresholdCols[j].column,
								  thresholdCols[j].numThresholds, fc)) return true;
				}
			}
		} // keep covariance from previous row
			
			// TODO: Possible solution here: Manually record threshold column and index from data 
			//   during this initial reduction step.  Since all the rest is algebras, it'll filter 
			//   naturally.  Calculate offsets from continuous data, then dereference actual 
			//   threshold values from the threshold matrix in its original state.  
			//   Alternately, rearrange the thresholds matrix (and maybe data matrix) to split
			//    ordinal and continuous variables.
			//   Requirement: colNum integer vector
			
			if(numContinuous <= 0 && numOrdinal <= 0) {
				// All elements missing.  Skip row.
				for(int nid = 0; nid < numIdentical; nid++) {	
					omxSetMatrixElement(rowLikelihoods, indexVector[row+nid], 0, 1.0);
				}
				omxFIMLAdvanceJointRow(&row, &numIdenticalDefs, 
				&numIdenticalContinuousMissingness,
				&numIdenticalOrdinalMissingness, 
				&numIdenticalContinuousRows,
						       shared_ofo, numDefs, numIdentical);
				continue;
			}
			
			//  smallCov <- cov[!contRemove, !contRemove] : covariance of continuous elements
			//  smallMeans <- means[ALL, !contRemove] : continuous means
			//  smallRow <- data[ALL, !contRemove]  : continuous data
			//              ordCov <- cov[!ordRemove, !ordRemove]
			//              ordMeans <- means[NULL, !ordRemove]
			//              ordData <- data[NULL, !ordRemove]
			//              ordContCov <- cov[!contRemove, !ordRemove]
			
			// TODO: Data handling is confusing.  Maybe set two self-aliased row-reduction "datacolumns" elements?
			
			// SEPARATION: 
			// Catch here: If continuous columns are all missing, skip everything except the ordCov calculations
			//              in this case, log likelihood of the continuous is 1 (likelihood is 0)
			// Do not recompute ordcov if missingness is identical and no def vars
			
			// SEPARATION: 
			//  Unprojected covariances only need to reset and re-filter if there are def vars or the appropriate missingness pattern changes
			//  Also, if each one is not all-missing.
			
			if(numContinuous <= 0) {
				// All continuous missingness.  Populate some stuff.
				Q = 0.0;
				determinant = 0.0;
				if(numIdenticalDefs <= 0 || numIdenticalOrdinalMissingness <= 0 || firstRow) {
					// Recalculate Ordinal covariance matrix
					omxCopyMatrix(ordCov, cov);
					omxRemoveRowsAndColumns(ordCov, ordRemove.data(), ordRemove.data());

					EigenMatrixAdaptor EordCov(ordCov);
					ol.setCovariance(EordCov, fc);
					
					// Recalculate ordinal fs
					omxCopyMatrix(ordMeans, means);
					omxRemoveElements(ordMeans, ordRemove.data()); 	    // Reduce the row to just ordinal.
					
					EigenVectorAdaptor EordMeans(ordMeans);
					ol.setMean(EordMeans);
				}
			} 
			else if( numIdenticalDefs <= 0 || numIdenticalContinuousRows <= 0 || firstRow || ofo->isStateSpace) {
				
				/* Reset and Resample rows if necessary. */
				// First Cov and Means (if they've changed)
				if( numIdenticalDefs <= 0 || numIdenticalContinuousMissingness <= 0 || firstRow || ofo->isStateSpace) {
					if(OMX_DEBUG_ROWS(row)) { mxLog("Beginning to recompute inverse cov for standard models"); }
					
					/* If it's a state space expectation, extract the inverse rather than recompute it */
					if(ofo->isStateSpace) {
						smallMeans = omxGetExpectationComponent(expectation, "means");
						omxRemoveElements(smallMeans, contRemove.data());
						if(OMX_DEBUG_ROWS(row)) { mxLog("Beginning to extract inverse cov for state space models"); }
						smallCov = omxGetExpectationComponent(expectation, "inverse");
						if(OMX_DEBUG_ROWS(row)) { omxPrint(smallCov, "Inverse of Local Covariance Matrix in state space model"); }
						//Get covInfo from state space expectation
						info = (int) omxGetExpectationComponent(expectation, "covInfo")->data[0];
						if(info!=0) {
							if (fc) fc->recordIterationError("Expected covariance matrix is "
											 "not positive-definite in data row %d",
											 indexVector[row]);
							return TRUE;
						}
						
						determinant = *omxGetExpectationComponent(expectation, "determinant")->data;
						if(OMX_DEBUG_ROWS(row)) { mxLog("0.5*log(det(Cov)) is: %3.3f", determinant);}
					} //If it's a GREML expectation, extract the inverse rather than recompute it:
					else if(!strcmp(expectation->expType, "MxExpectationGREML")){
						smallMeans = omxGetExpectationComponent(expectation, "means");
						smallCov = omxGetExpectationComponent(expectation, "invcov");
						info = (int) omxGetExpectationComponent(expectation, "cholV_fail_om")->data[0];
						if(info!=0) {
							if (fc) fc->recordIterationError("expected covariance matrix is not "
											 "positive-definite in data row %d",
											 indexVector[row]);
							return TRUE;
						}
						determinant = 0.5 * omxGetExpectationComponent(expectation, "logdetV_om")->data[0];
						if(OMX_DEBUG_ROWS(row)) { mxLog("0.5*log(det(Cov)) is: %3.3f", determinant);}
					}
					else {
						/* Calculate derminant and inverse of Censored continuousCov matrix */
						omxCopyMatrix(smallMeans, means);
						omxRemoveElements(smallMeans, contRemove.data());
						omxCopyMatrix(smallCov, cov);
						omxRemoveRowsAndColumns(smallCov, contRemove.data(), contRemove.data());
						
						if(OMX_DEBUG_ROWS(row)) { 
							omxPrint(smallCov, "Cont Cov to Invert"); 
						}
						
						F77_CALL(dpotrf)(&u, &(smallCov->rows), smallCov->data, &(smallCov->cols), &info);
						
						if(info != 0) {
							for(int nid = 0; nid < numIdentical; nid++) {
								omxSetMatrixElement(rowLikelihoods, indexVector[row+nid], 0, NA_REAL);
							}
							if (fc) fc->recordIterationError("Expected covariance matrix for continuous variables "
											 "is not positive-definite in data row %d", indexVector[row]);
							omxFIMLAdvanceJointRow(&row, &numIdenticalDefs, 
							&numIdenticalContinuousMissingness,
							&numIdenticalOrdinalMissingness, 
							&numIdenticalContinuousRows,
									       shared_ofo, numDefs, numIdentical);
							continue;
						}
						// Calculate determinant: squared product of the diagonal of the decomposition
						// For speed, use sum of logs rather than log of product.
						
						determinant = 0.0;
						for(int diag = 0; diag < (smallCov->rows); diag++) {
							determinant += log(fabs(omxMatrixElement(smallCov, diag, diag)));
						}
						// determinant = determinant * determinant;  // Delayed.
						F77_CALL(dpotri)(&u, &(smallCov->rows), smallCov->data, &(smallCov->cols), &info);
					}
					
					if(info != 0) {
						omxRaiseErrorf("Cannot invert expected continuous "
							       "covariance matrix for row %d. Error %d.",
							       indexVector[row], info);
						for(int nid = 0; nid < numIdentical; nid++) {
							omxSetMatrixElement(rowLikelihoods, indexVector[row+nid], 0, NA_REAL);
						}
						omxFIMLAdvanceJointRow(&row, &numIdenticalDefs, 
						&numIdenticalContinuousMissingness,
						&numIdenticalOrdinalMissingness, 
						&numIdenticalContinuousRows,
								       shared_ofo, numDefs, numIdentical);
						continue;
					}
				}
				
				// Reset continuous data row (always needed)
				omxCopyMatrix(contRow, smallRow);
				omxRemoveElements(contRow, contRemove.data()); 	// Reduce the row to just continuous.
				F77_CALL(daxpy)(&(contRow->cols), &minusoned, smallMeans->data, &onei, contRow->data, &onei);
				
				/* Calculate Row Likelihood */
				/* Mathematically: (2*pi)^cols * 1/sqrt(determinant(ExpectedCov)) * (dataRow %*% (solve(ExpectedCov)) %*% t(dataRow))^(1/2) */
				//EigenMatrixAdaptor EsmallCov(smallCov);
				//mxPrintMat("smallcov", EsmallCov);
				F77_CALL(dsymv)(&u, &(smallCov->rows), &oned, smallCov->data, &(smallCov->cols), contRow->data, &onei, &zerod, RCX->data, &onei);       // RCX is the continuous-column mahalanobis distance.
				Q = F77_CALL(ddot)(&(contRow->cols), contRow->data, &onei, RCX->data, &onei); //Q is the total mahalanobis distance
				
				if(numOrdinal > 0) { // also check numIdenticalDefs?
					
					// Precalculate Ordinal things that change with continuous changes
					// Reserve: 1) Inverse continuous covariance (smallCov)
					//          2) Columnwise Mahalanobis distance (contCov^-1)%*%(Data - Means) (RCX)
					//          3) Overall Mahalanobis distance (FIML likelihood of data) (Q)
					//Calculate:4) Cont/ord covariance %*% Mahalanobis distance  (halfCov)
					//          5) ordCov <- ordCov - Cont/ord covariance %*% Inverse continuous cov
					
					if(numIdenticalContinuousMissingness <= 0 || firstRow) {
						// Re-sample covariance between ordinal and continuous only if the continuous missingness changes.
						omxCopyMatrix(ordContCov, cov);
						omxRemoveRowsAndColumns(ordContCov, contRemove.data(), ordRemove.data());
						
						// TODO: Make this less of a hack.
						halfCov->rows = smallCov->rows;
						halfCov->cols = ordContCov->cols;
						omxMatrixLeadingLagging(halfCov);
						reduceCov->rows = ordContCov->cols;
						reduceCov->cols = ordContCov->cols;
						omxMatrixLeadingLagging(reduceCov);
						
						F77_CALL(dsymm)(&l, &u, &(smallCov->rows), &(ordContCov->cols), &oned, smallCov->data, &(smallCov->leading), ordContCov->data, &(ordContCov->leading), &zerod, halfCov->data, &(halfCov->leading));          // halfCov is inverse continuous %*% cont/ord covariance
						F77_CALL(dgemm)((ordContCov->minority), (halfCov->majority), &(ordContCov->cols), &(halfCov->cols), &(ordContCov->rows), &oned, ordContCov->data, &(ordContCov->leading), halfCov->data, &(halfCov->leading), &zerod, reduceCov->data, &(reduceCov->leading));      // reduceCov is cont/ord^T %*% (contCov^-1 %*% cont/ord)
					}
					
					if(numIdenticalOrdinalMissingness <= 0 || firstRow) {
						// Means, projected covariance, and Columnwise mahalanobis distance must be recalculated
						//   unless there are no ordinal variables or the continuous variables are identical
						
						// Recalculate Ordinal and Ordinal/Continuous covariance matrices.
						if(OMX_DEBUG_ROWS(row)) {
							mxLog("Resetting Ordinal Covariance Matrix.");
							omxPrint(ordCov, "Was:");
						}
						
						omxCopyMatrix(ordCov, cov);
						if(OMX_DEBUG_ROWS(row)) {
							mxLog("Resetting/Filtering Ordinal Covariance Matrix.");
							omxPrint(ordCov, "Reset to:");
						}
						
						omxRemoveRowsAndColumns(ordCov, ordRemove.data(), ordRemove.data());
						if(OMX_DEBUG_ROWS(row)) {
							mxLog("Resetting/Filtering Ordinal Covariance Matrix.");
							omxPrint(ordCov, "Filtered to:");
						}
						
						// FIXME: This assumes that ordCov and reducCov have the same row/column majority.
						int vlen = reduceCov->rows * reduceCov->cols;
						F77_CALL(daxpy)(&vlen, &minusoned, reduceCov->data, &onei, ordCov->data, &onei); // ordCov <- (ordCov - reduceCov) %*% cont/ord
						EigenMatrixAdaptor EordCov(ordCov);
						ol.setCovariance(EordCov, fc);
					}
					
					// Projected means must be recalculated if the continuous variables change at all.
					omxCopyMatrix(ordMeans, means);
					omxRemoveElements(ordMeans, ordRemove.data()); 	    // Reduce the row to just ordinal.
					F77_CALL(dgemv)((smallCov->minority), &(halfCov->rows), &(halfCov->cols), &oned, halfCov->data, &(halfCov->leading), contRow->data, &onei, &oned, ordMeans->data, &onei);                      // ordMeans += halfCov %*% contRow
					EigenVectorAdaptor EordMeans(ordMeans);
					ol.setMean(EordMeans);
				}
				
			} // End of continuous likelihood values calculation
			
			if(numOrdinal <= 0) {       // No Ordinal Vars at all.
			likelihood = 1;
			} 
			else {  
				int ox=0;
				for(int j = 0; j < dataColumns.size(); j++) {
					if(ordRemove[j]) continue;         // NA or non-ordinal
					ordBuffer[ox] = j;
					ox += 1;
				}
				
				Eigen::Map< Eigen::ArrayXi > ordRow(ordBuffer.data(), ox);
				likelihood = ol.likelihood(indexVector[row], ordRow);

				if (likelihood == 0.0) {
					if (fc) fc->recordIterationError("Improper value detected by integration routine "
									 "in data row %d: Most likely the maximum number of "
									 "ordinal variables (20) has been exceeded.  \n"
									 " Also check that expected covariance matrix is not "
									 "positive-definite", indexVector[row]);
					for(int nid = 0; nid < numIdentical; nid++) {
						omxSetMatrixElement(rowLikelihoods, indexVector[row+nid], 0, NA_REAL);
					}
					if(OMX_DEBUG) {mxLog("Improper input to sadmvn in row likelihood.  Skipping Row.");}
					omxFIMLAdvanceJointRow(&row, &numIdenticalDefs, 
					&numIdenticalContinuousMissingness,
					&numIdenticalOrdinalMissingness, 
					&numIdenticalContinuousRows,
							       shared_ofo, numDefs, numIdentical);
					continue;
				}
			}
			
			double rowLikelihood = pow(2 * M_PI, -.5 * numContinuous) * (1.0/exp(determinant)) * exp(-.5 * Q) * likelihood;
			
			for(int j = numIdentical + row - 1; j >= row; j--) {
				omxSetMatrixElement(rowLikelihoods, indexVector[j], 0, rowLikelihood);
			}
				
			if(OMX_DEBUG_ROWS(row)) { 
				mxLog("row[%d] log likelihood det %3.3f + q %3.3f + const %3.3f + ord %3.3f = %3.3g", 
				      indexVector[row], (2.0*determinant), Q, M_LN_2PI * numContinuous, 
				      log(likelihood), -2.0 * log(rowLikelihood));
			}

			if(firstRow) firstRow = false;
			omxFIMLAdvanceJointRow(&row, &numIdenticalDefs, 
			&numIdenticalContinuousMissingness,
			&numIdenticalOrdinalMissingness, 
			&numIdenticalContinuousRows,
					       shared_ofo, numDefs, numIdentical);
			continue;
			
	}
	return FALSE;
}
