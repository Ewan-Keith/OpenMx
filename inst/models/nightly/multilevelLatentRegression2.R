library(OpenMx)

set.seed(1)

numIndicators <- 4

numDistricts <- 1
numSchools <- 4
numTeachers <- 3
numStudents <- 5

genData <- function(upper, fanout, keyname) {
	lowerData <- NULL
	for (sx in 1:nrow(upper)) {
		extraFanout <- sample.int(fanout, 1)
#		extraFanout <- 0L
		lowerData <- rbind(lowerData, data.frame(
		    upper=upper[sx,1], skill=rnorm(fanout + extraFanout, mean=upper[sx, 'skill'])))
	}
	colnames(lowerData)[[1]] <- colnames(upper)[[1]]
	lowerData[[keyname]] <- 1:nrow(lowerData)
	lowerData <- lowerData[,c(3,1,2)]
	lowerData
}

districtData <- data.frame(districtID=1:numDistricts, skill=rnorm(numDistricts))
schoolData <- genData(districtData, numSchools, 'schoolID')
teacherData <- genData(schoolData, numTeachers, 'teacherID')
studentData <- genData(teacherData, numStudents, 'studentID')

createIndicators <- function(latentSkill, indicatorVariance) {
	if (missing(indicatorVariance)) {
		indicatorVariance <- rep(1, numIndicators) #rlnorm(numIndicators) / 8
	}
	ind <- matrix(NA, length(latentSkill), length(indicatorVariance))
	for (ix in 1:length(latentSkill)) {
		ind[ix,] <- sapply(indicatorVariance,
				   function(sd) rnorm(1, mean=latentSkill[ix], sd=sd))
	}
	# per indicator mean
#	ind <- t(t(ind) + runif(numIndicators,min=-1,max=1))
	colnames(ind) <- paste0('i', 1:length(indicatorVariance))
	as.data.frame(ind)
}

districtData <- cbind(districtData, createIndicators(districtData$skill))
schoolData <- cbind(schoolData, createIndicators(schoolData$skill))
teacherData <- cbind(teacherData, createIndicators(teacherData$skill))
studentData <- cbind(studentData, createIndicators(studentData$skill))

studentData$i4[runif(nrow(studentData)) > .8] <- NA
#teacherData$i4[runif(nrow(teacherData)) > .8] <- NA

mkSingleFactor <- function(latent=c()) {
	mxModel('template', type='RAM',
		manifestVars = paste0('i', 1:numIndicators),
		latentVars = c("skill",latent),
		mxPath('skill', arrows=2, labels="Var", values=rlnorm(1), lbound=.01),
		mxPath(paste0('i',1:numIndicators), arrows=2,
		       values=rlnorm(1), labels="Err", lbound=.01),
		mxPath("one", paste0('i',1:numIndicators), free=TRUE, values=rnorm(4)),
		mxPath('skill', paste0('i',1:numIndicators),
		       labels=paste0('L',1:numIndicators), lbound=0,
		       values=c(1, runif(numIndicators-1, .5,1.5)),
		       free=c(FALSE, rep(TRUE,numIndicators-1)))
		)
}

singleFactor <- mkSingleFactor(NULL)
			
relabel <- function(m, prefix) {
  for (mat in c("A","S")) {
    lab <- m@matrices[[mat]]@labels
    lab[!is.na(lab)] <- paste0(prefix, lab[!is.na(lab)])
    m@matrices[[mat]]@labels <- lab
  }
  mxModel(m, name=prefix)
}

dMod <- mxModel(relabel(mkSingleFactor(), "district"),
		mxData(type="raw", observed=districtData, primaryKey="districtID", sort=FALSE))

schMod <- mxModel(relabel(mkSingleFactor(), "school"), dMod,
		  mxData(type="raw", observed=schoolData, primaryKey="schoolID", sort=FALSE),
		  mxPath('district.skill', 'skill', joinKey="districtID", values=runif(1)))

tMod <- mxModel(relabel(singleFactor, "teacher"), schMod,
		  mxData(type="raw", observed=teacherData, primaryKey="teacherID", sort=FALSE),
		  mxPath('school.skill', 'skill', joinKey="schoolID", values=runif(1)))

if (0) {
	options(width=120)
	plan <- mxComputeSequence(list(
	    mxComputeOnce('fitfunction', 'fit'),
	    mxComputeNumericDeriv(checkGradient=FALSE, hessian=FALSE, iterations=2),
	    mxComputeReportDeriv(),
	    mxComputeReportExpectation()
	))

	tMod$expectation$rampart <- 0L
	square <- mxRun(mxModel(tMod, plan))

	tMod$expectation$rampart <- 2L
	rotated <- mxRun(mxModel(tMod, plan))
	
	ex <- rotated$expectation
	eo <- ex$output
	ed <- ex$debug
#	print(ed$layout)
	print(ed$rampartUsage)
	#print(round(ed$A[1:20,1:20],2))
	#print(round(ed$rA[1:20,1:20],2))
					#print(ed$mean)

					#omxCheckCloseEnough(ed$rampartUsage, c(11064L, 317L, 198L, 2L), 1L)
	print(abs(rotated$output$fit - square$output$fit))
	print(max(abs(rotated$output$gradient - square$output$gradient)))
#	omxCheckCloseEnough(rotated$output$gradient, square$output$gradient, 1e-4)
}

sMod <- mxModel(relabel(singleFactor, "student"), tMod,
		  mxData(type="raw", observed=studentData, primaryKey="studentID", sort=FALSE),
		  mxPath('teacher.skill', 'skill', joinKey="teacherID", values=runif(1)))

if (1) {
	options(width=120)
plan <- mxComputeSequence(list(
    mxComputeOnce('fitfunction', 'fit'),
    mxComputeNumericDeriv(checkGradient=FALSE, hessian=FALSE, iterations=2),
    mxComputeReportDeriv(),
    mxComputeReportExpectation()
))

sMod$expectation$rampart <- 0L
square <- mxRun(mxModel(sMod, plan))

sMod$expectation$rampart <- 4L
rotated <- mxRun(mxModel(sMod, plan))

ex <- rotated$expectation
eo <- ex$output
ed <- ex$debug
print(ed$rampartUsage)
#print(ed$layout)
#print(round(ed$A[1:20,1:20],2))
#print(round(ed$rA[1:20,1:20],2))
#print(ed$mean)

	print(abs(rotated$output$fit - square$output$fit))
	print(max(abs(rotated$output$gradient - square$output$gradient)))
omxCheckCloseEnough(ed$rampartUsage, c(209, 25, 5), 1L)
#round(rotated$output$gradient - square$output$gradient, 2)
omxCheckCloseEnough(rotated$output$fit, square$output$fit, 3)
omxCheckCloseEnough(rotated$output$gradient, square$output$gradient, 32)
}