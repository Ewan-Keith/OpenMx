# http://openmx.psyc.virginia.edu/issue/2014/05/memory-leak-when-running-ram-model-constraint

library(OpenMx)

#mxOption(NULL, "Default optimizer", 'SLSQP')

data(demoOneFactor)
manifests <- names(demoOneFactor)
latents <- c("G")
factorModelPath <- mxModel("OneFactorPath",
                           type="RAM",
                           manifestVars = manifests,
                           latentVars = latents,
                           mxPath(from=latents, to=manifests,
                                  labels=paste("l",1:5,sep="")),
                           mxPath(from=manifests, arrows=2),
                           mxPath(from=latents, arrows=2,
                                  free=FALSE, values=1.0),
                           mxData(cov(demoOneFactor), type="cov",
                                  numObs=500),
                           mxAlgebra(S[6,6],name="GV"),
                           mxConstraint(GV-1==0,name="pointless"),
                           mxConstraint(GV>0,name="morePointless"))
#factorModelPath <- mxOption(factorModelPath,"Checkpoint Directory","C:/Work/OpenMx_dev/")
#factorModelPath <- mxOption(factorModelPath,"Checkpoint Units","evaluations")
#factorModelPath <- mxOption(factorModelPath,"Checkpoint Count",1)
factorFit <- mxRun(factorModelPath, silent = TRUE)

omxCheckEquals(factorFit$output$status$code, 0)

if (mxOption(NULL, "Default optimizer") != 'NPSOL') {
	# Any constraints that show up here by mistake will have a zero gradient.
	omxCheckTrue(all(factorFit$output$gradient != 0))
}
omxCheckCloseEnough(sqrt(sum(factorFit$output$gradient^2)), 0, .021)


if (mxOption(NULL, "Default optimizer") != 'CSOLNP') {  # TODO
	broken <- mxModel(factorModelPath, remove=TRUE, names(factorModelPath$constraints))
	broken <- mxModel(broken, mxConstraint(GV>2, "infeasible"));
	broken <- omxCheckWarning(mxRun(broken, silent=TRUE),
				  "In model 'OneFactorPath' Optimizer returned a non-zero status code 3. The nonlinear constraints and bounds could not be satisfied. The problem may have no feasible solution.")
	omxCheckEquals(broken$output$status$code, 3)
}
