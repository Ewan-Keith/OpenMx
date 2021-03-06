\name{MxFitFunctionGREML-class}
\Rdversion{1.1}
\docType{class}
\alias{MxFitFunctionGREML-class}
\alias{MxFitFunctionGREML}

\title{Class \code{"MxFitFunctionGREML"}}
\description{
\code{MxFitFunctionGREML} is the fitfunction class for GREML analyses.  
}
\section{Objects from the Class}{
Objects can be created by calls of the form \code{mxFitFunctionGREML(dV)}.
}
\section{Slots}{
  \describe{
    \item{\code{dV}:}{Object of class \code{"MxCharOrNumber"}.  Identifies the \code{\link{MxAlgebra}} or \code{\link{MxMatrix}} object(s) to serve as the derivatives of 'V' with respect to free parameters.}
    \item{\code{dVnames}:}{Vector of character strings; names of the free parameters corresponding to slot \code{dV}.}
    \item{\code{MLfit}:}{Object of class \code{"numeric"}, equal to the maximum-likelihood fitfunction value (as opposed to the restricted maximum-likelihood value).}
    \item{\code{numObs}:}{Object of class \code{"integer"}.  Number of observations.}
    \item{\code{aug}:}{Object of class \code{"MxCharOrNumber"}.  Identifies the \code{\link{MxAlgebra}} or \code{\link{MxMatrix}} object used to "augment" the fitfunction value at each function evaluation during optimization.}
    \item{\code{augGrad}:}{Object of class \code{"MxCharOrNumber"}.  Identifies the \code{\link{MxAlgebra}} or \code{\link{MxMatrix}} object(s) to serve as the first derivatives of \code{aug} with respect to free parameters.}
    \item{\code{augHess}:}{Object of class \code{"MxCharOrNumber"}.  Identifies the \code{\link{MxAlgebra}} or \code{\link{MxMatrix}} object(s) to serve as the second derivatives of \code{aug} with respect to free parameters.}
    \item{\code{info}:}{Object of class \code{"list"}.}
    \item{\code{dependencies}:}{Object of class \code{"integer"}.}
    \item{\code{expectation}:}{Object of class \code{"integer"}.}
    \item{\code{vector}:}{Object of class \code{"logical"}.}
    \item{\code{rowDiagnostics}:}{Object of class \code{"logical"}.}
    \item{\code{result}:}{Object of class \code{"matrix"}.}
    \item{\code{name}:}{Object of class \code{"character"}.}
    
  }
}
\section{Extends}{
Class \code{"MxBaseFitFunction"}, directly.
Class \code{"MxBaseNamed"}, by class "MxBaseFitFunction", distance 2.
Class \code{"MxFitFunction"}, by class "MxBaseFitFunction", distance 2.
}
\section{Methods}{
No methods defined with class "MxFitFunctionGREML" in the signature.
}
\references{
The OpenMx User's guide can be found at \url{http://openmx.psyc.virginia.edu/documentation}.
}

\seealso{
See \code{\link{mxFitFunctionGREML}()} for creating MxFitFunctionGREML objects.  See \code{\link{mxExpectationGREML}()} for creating MxExpectationGREML objects, and for more information generally concerning GREML analyses, including a complete example. More information about the OpenMx package may be found \link[=OpenMx]{here}. 
}
\examples{
showClass("MxFitFunctionGREML")
}
\keyword{classes}
