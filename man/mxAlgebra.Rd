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

\name{mxAlgebra}
\alias{mxAlgebra}
\alias{p2z}
\alias{logp2z}
\alias{lgamma1p}
\alias{\%&\%}
\alias{\%^\%}

\title{Create MxAlgebra Object}

\description{
   This function creates a new \link{MxAlgebra} object.
}

\usage{
mxAlgebra(expression, name = NA, dimnames = NA, ..., fixed = FALSE,
          joinKey=as.character(NA), joinModel=as.character(NA))
}

\arguments{
   \item{expression}{An R expression of OpenMx-supported matrix operators and matrix functions.}
   \item{name}{An optional character string indicating the name of the object.}
   \item{dimnames}{list. The dimnames attribute for the algebra: a list
   of length 2 giving the row and column names respectively. An empty
   list is treated as NULL, and a list of length one as row names. The
   list can be named, and the list names will be used as names for the
   dimensions.}
   \item{...}{Not used.  Forces argument \sQuote{fixed} to be specified by name.}
   \item{fixed}{If TRUE, this algebra will not be recomputed
     automatically when things it depends on change. \link{mxComputeOnce}
     can be used to force it to recompute.}
\item{joinKey}{The name of the column in current model's raw data that
  is used as a foreign key to match against the primary key in
  joinModel's raw data.}
\item{joinModel}{The name of the model that this matrix joins against.}
}

\details{
The mxAlgebra function is used to create algebraic expressions that operate on one or more 
\link{MxMatrix} objects. To evaluate an \link{MxAlgebra} object, 
it must be placed in an \link{MxModel} object, along with all referenced \code{MxMatrix} 
objects and the \code{mxFitFunctionAlgebra} function. 
The \code{mxFitFunctionAlgebra} function must reference by name the \code{MxAlgebra} object to be evaluated.

Note that, if the result for an \link{MxAlgebra} depends upon one or more "definition variables" (see \code{\link{mxMatrix}()}), then the value returned after the call to \code{\link{mxRun}()} will be computed using the values of those definition variables in the first (i.e., first before any automated sorting is done) row of the raw dataset.

The following operators and functions are supported in mxAlgebra:

Operators

\describe{
\item{\code{solve()}}{Inversion}
\item{\code{t()}}{Transposition}
\item{\code{^}}{Elementwise powering}
\item{\code{\%^\%}}{Kronecker powering}
\item{\code{+}}{Addition}
\item{\code{-}}{Subtraction}
\item{\code{\%*\%}}{Matrix Multiplication}
\item{\code{*}}{Elementwise product}
\item{\code{/}}{Elementwise division}
\item{\code{\%x\%}}{Kronecker product}
\item{\code{\%&\%}}{Quadratic product: pre- and post-multiply B by A and its transpose t(A), i.e: A \code{\%&\%} B ==  A \code{\%*\%} B \code{\%*\%} t(A)}
}

Functions

\describe{
\item{\code{cov2cor}}{Convert covariance matrix to correlation matrix}
\item{\code{chol}}{Cholesky Decomposition}
\item{\code{cbind}}{Horizontal adhesion}
\item{\code{rbind}}{Vertical adhesion}
\item{\code{det}}{Determinant}
\item{\code{tr}}{Trace}
\item{\code{sum}}{Sum}
\item{\code{mean}}{Arithmetic mean}
\item{\code{prod}}{Product}
\item{\code{max}}{Maximum}
\item{\code{min}}{Min}
\item{\code{abs}}{Absolute value}
\item{\code{sin}}{Sine}
\item{\code{sinh}}{Hyperbolic sine}
\item{\code{asin}}{Arcsine}
\item{\code{asinh}}{Inverse hyperbolic sine}
\item{\code{cos}}{Cosine}
\item{\code{cosh}}{Hyperbolic cosine}
\item{\code{acos}}{Arccosine}
\item{\code{acosh}}{Inverse hyperbolic cosine}
\item{\code{tan}}{Tangent}
\item{\code{tanh}}{Hyperbolic tangent}
\item{\code{atan}}{Arctangent}
\item{\code{atanh}}{Inverse hyperbolic tangent}
\item{\code{exp}}{Exponent}
\item{\code{log}}{Natural Logarithm}
\item{\code{sqrt}}{Square root}
\item{\code{p2z}}{\emph{Standard}-normal quantile}
\item{\code{logp2z}}{\emph{Standard}-normal quantile from log probabilities}
\item{\code{lgamma}}{Log-gamma function}
\item{\code{lgamma1p}}{Compute log(gamma(x+1)) accurately for small x}
\item{\code{\link{eigenval}}}{Eigenvalues of a square matrix. Usage: eigenval(x); eigenvec(x); ieigenval(x); ieigenvec(x)}
\item{\code{\link{rvectorize}}}{Vectorize by row}
\item{\code{\link{cvectorize}}}{Vectorize by column}
\item{\code{\link{vech}}}{Half-vectorization}
\item{\code{\link{vechs}}}{Strict half-vectorization}
\item{\code{\link{vech2full}}}{Inverse half-vectorization}
\item{\code{\link{vechs2full}}}{Inverse strict half-vectorization}
\item{\code{\link{vec2diag}}}{Create matrix from a diagonal vector (similar to \link{diag}) }
\item{\code{\link{diag2vec}}}{Extract diagonal from matrix (similar to \link{diag}) }
\item{\code{\link{expm}}}{Matrix Exponential}
\item{\code{\link{logm}}}{Matrix Logarithm}
\item{\code{\link{omxExponential}}}{Matrix Exponential}
\item{\code{\link{omxMnor}}}{Multivariate Normal Integration}
\item{\code{\link{omxAllInt}}}{All cells Multivariate Normal Integration}
\item{\code{\link[=omxLogical]{omxNot}}}{Perform unary negation on a matrix}
\item{\code{\link[=omxLogical]{omxAnd}}}{Perform binary and on two matrices}
\item{\code{\link[=omxLogical]{omxOr}}}{Perform binary or on two matrices}
\item{\code{\link[=omxLogical]{omxGreaterThan}}}{Perform binary greater on two matrices}
\item{\code{\link[=omxLogical]{omxLessThan}}}{Perform binary less than on two matrices}
\item{\code{\link[=omxLogical]{omxApproxEquals}}}{Perform binary equals to (within a specified epsilon) on two matrices}
\item{\code{\link[OpenMx:omxSelectRowsAndCols]{omxSelectRows}}}{Filter rows from a matrix}
\item{\code{\link[OpenMx:omxSelectRowsAndCols]{omxSelectCols}}}{Filter columns from a matrix}
\item{\code{\link[OpenMx:omxSelectRowsAndCols]{omxSelectRowsAndCols}}}{Filter rows and columns from a matrix}
}

There are also several multiargument functions usable in MxAlgebras, which apply themselves elementwise to the matrix provided as their first argument.  These functions have slightly different usage from their \R counterparts.  Their result is always a matrix with the same dimensions as that provided for their first argument.  Values must be provided for ALL arguments of these functions, in order.  Provide zeroes as logical values of \code{FALSE}, and non-zero numerical values as logical values of \code{TRUE}.  For most of these functions, OpenMx cycles over values of arguments other than the first, by column (i.e., in column-major order), to the length of the first argument.  Notable exceptions are the \code{log}, \code{log.p}, and \code{lower.tail} arguments to probability-distribution-related functions, for which only the [1,1] element is used.  It is recommended that all arguments after the first be either (1) scalars, or (2) matrices with the same dimensions as the first argument.
\tabular{ccl}{
Function \tab Arguments \tab Notes \cr
\code{dbeta} \tab \code{x,shape1,shape2,ncp,log} \tab The algorithm for the non-central beta distribution is used for non-negative values of \code{ncp}.  Negative \code{ncp} values are ignored, and the algorithm for the central beta distribution is used. \cr
\code{pbeta} \tab \code{q,shape1,shape2,ncp,lower.tail,log.p} \tab Values of \code{ncp} are handled as with \code{dbeta()}.\cr
\code{besselI} & \code{besselK} \tab \code{x,nu,expon.scaled} \tab Note that OpenMx \emph{does} cycle over the elements of \code{expon.scaled}. \cr
\code{besselJ} & \code{besselY} \tab \code{x,nu} \tab  \cr
\code{dnbinom} \tab \code{x,size,prob,mu,log} \tab Exactly one of arguments \code{size}, \code{prob}, and \code{mu} should be negative, and therefore ignored.  Otherwise, \code{mu} is ignored, possibly with a warning, and the values of \code{size} and \code{prob} are used, irrespective of whether they are in the parameter space.  If only \code{prob} is negative, the algorithm for the alternative \code{size}-\code{mu} parameterization is used.  If \code{size} is negative, a value for size is calculated as \code{mu*prob/(1-prob)}, and the algorithm for the \code{size}-\code{prob} parameterization is used (note that this approach is ill-advised when \code{prob} is very close to 0 or 1).\cr
\code{pnbinom} \tab \code{q,size,prob,mu,lower.tail,log.p} \tab Arguments are handled as with \code{dnbinom()}.\cr
\code{dpois} \tab \code{x,lambda,log} \tab  \cr
\code{ppois} \tab \code{q,lambda,lower.tail,log.p} \tab  \cr
}
}

\value{
    Returns a new \link{MxAlgebra} object.
}

\references{
The OpenMx User's guide can be found at http://openmx.psyc.virginia.edu/documentation.
}

\seealso{
\link{MxAlgebra} for the S4 class created by mxAlgebra. \link{mxFitFunctionAlgebra} for an objective function which takes an  MxAlgebra or MxMatrix object as the function to be minimized. 
\link{MxMatrix} and \link{mxMatrix} for objects which may be entered in the \code{expression} argument and the function that creates them. More information about the OpenMx package may be found \link[=OpenMx]{here}. 
}

\examples{

A <- mxMatrix("Full", nrow = 3, ncol = 3, values=2, name = "A")

# Simple example: algebra B simply evaluates to the matrix A
B <- mxAlgebra(A, name = "B")

# Compute A + B
C <- mxAlgebra(A + B, name = "C")

# Compute sin(C)
D <- mxAlgebra(sin(C), name = "D")

# Make a model and evaluate the mxAlgebra object 'D'
A <- mxMatrix("Full", nrow = 3, ncol = 3, values=2, name = "A")
model <- mxModel(model="AlgebraExample", A, B, C, D )
fit   <- mxRun(model)
mxEval(D, fit)


# Numbers in mxAlgebras are upgraded to 1x1 matrices
# Example of Kronecker powering (%^%) and multiplication (%*%)
A  <- mxMatrix(type="Full", nrow=3, ncol=3, value=c(1:9), name="A")
m1 <- mxModel(model="kron", A, mxAlgebra(A \%^\% 2, name="KroneckerPower"))
mxRun(m1)$KroneckerPower

# Running kron 
# mxAlgebra 'KroneckerPower' 
# $formula:  A %^% 2 
# $result:
#      [,1] [,2] [,3]
# [1,]    1   16   49
# [2,]    4   25   64
# [3,]    9   36   81

}
