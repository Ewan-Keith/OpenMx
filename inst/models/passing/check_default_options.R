library(OpenMx)

omxCheckEquals(imxDetermineDefaultOptimizer(), "CSOLNP")

omxCheckEquals(options()[['mxCondenseMatrixSlots']], FALSE)
