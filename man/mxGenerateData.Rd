%
%   Copyright 2007-2016 The OpenMx Project
%
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
% 
%        http://www.apache.org/licenses/LICENSE-2.0
% 
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.

\name{mxGenerateData}
\alias{mxGenerateData}


\title{Generate data based on an MxModel object}

\description{
This function creates a randomly sampled data set based on the model.
}

\usage{
mxGenerateData(model, nrows, returnModel=FALSE)
}


\arguments{
   \item{model}{An MxModel object upon which the data are generated.}
   \item{nrows}{Numeric. The number of rows of data to generate.}
   \item{returnModel}{Logical. Return data.frames if FALSE or model
   populated with new data if TRUE.}
}

\details{
This function looks inside the MxModel object to extract the model-implied means and covariance.  It then generates data with the same mean and covariance.  Data can be generated based on Normal (\link{mxExpectationNormal}), RAM (\link{mxExpectationRAM}), LISREL (\link{mxExpectationLISREL}), and state space (\link{mxExpectationStateSpace}) models.

Thresholds and ordinal data are implemented by generating continuous data and then using \link{cut} and \link{mxFactor} to break the continous data at the thresholds into an ordered factor.

If the model has definition variables, then a data set must be included in the model object and the number of rows requested must match the number of rows in the model data.  In this case the means, covariance, and thresholds are reevaluated for each row of data, potentially creating a a different mean, covariance, and threshold structure for every generated row of data.

For state space models (i.e. models with an \link{mxExpectationStateSpace} or \link{mxExpectationStateSpaceContinuousTime} expectation), the data are generated based on the autoregressive structure of the model.  The rows of data in a state space model are not independent replicates of a stationary process.  Rather, they are the result of a latent (possibly non-stationary) autoregressive process.  For state space models different rows of data often correspond to different times.  As alluded to above, data generation works for discrete time state space models and hybrid continuous-discrete time state space models.  The latter have a continous process that is measured as discrete times.
}

\value{
    A data.frame, list of data.frames, or model populated with the new data
    (depending on the \code{returnModel} parameter).
}


\references{
The OpenMx User's guide can be found at http://openmx.psyc.virginia.edu/documentation.
}

\examples{

#----------
# Create data based on state space model.
require(OpenMx)
nvar <- 5
varnames <- paste("x", 1:nvar, sep="")
ssModel <- mxModel(model="State Space Manual Example",
    mxMatrix("Full", 1, 1, TRUE, .3, name="A"),
    mxMatrix("Zero", 1, 1, name="B"),
    mxMatrix("Full", nvar, 1, TRUE, .6, name="C", dimnames=list(varnames, "F1")),
    mxMatrix("Zero", nvar, 1, name="D"),
    mxMatrix("Diag", 1, 1, FALSE, 1, name="Q"),
    mxMatrix("Diag", nvar, nvar, TRUE, .2, name="R"),
    mxMatrix("Zero", 1, 1, name="x0"),
    mxMatrix("Diag", 1, 1, FALSE, 1, name="P0"),
    mxMatrix("Zero", 1, 1, name="u"),
    mxExpectationStateSpace("A", "B", "C", "D", "Q", "R", "x0", "P0", "u"),
    mxFitFunctionML()
)

ssData <- mxGenerateData(ssModel, 200) # 200 time points

# Add simulated data to model
ssModel <- mxModel(ssModel, mxData(ssData, 'raw'))

# Fit model to simulated data
ssRun <- mxRun(ssModel)

# Compare parameters estimated from random data to
#  their true generating values
cbind(Rand=omxGetParameters(ssRun), Gen=omxGetParameters(ssModel))
# Note the parameters should be "close" (up to sampling error)
# to the generating values


#----------
require(OpenMx)
manifests <- paste("x", 1:5, sep="")
latents <- c("G")
factorModel <- mxModel("One Factor",
      type="RAM",
      manifestVars = manifests,
      latentVars = latents,
      mxPath(from=latents, to=manifests, values=.8),
      mxPath(from=manifests, arrows=2, values=.2),
      mxPath(from=latents, arrows=2,
            free=FALSE, values=1.0),
      mxPath(from = 'one', to = manifests))

factorData <- mxGenerateData(factorModel, 100)

factorModel <- mxModel(factorModel,
                       mxData(observed=cov(factorData), type="cov",
                              numObs=nrow(factorData),
                              means = colMeans(factorData)))
factorRun <- mxRun(factorModel)
cbind(Rand=omxGetParameters(factorRun), Gen=omxGetParameters(factorModel))


}
