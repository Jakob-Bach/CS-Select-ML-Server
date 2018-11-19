library(data.table)

source("UtilityFunctions.R")

dataset <- data.table(VGAMdata::xs.nz)
dataset[, target := factor(as.integer(sex == "F"))]
dataset[, c("regnum", "study1", "sex", "pregnant", "pregfirst", "preglast", "babies") := NULL]
numericCols <- c("fh.age", "smokeagequit")
dataset[, (numericCols) := lapply(.SD, as.numeric), .SDcols = numericCols]
dataset[, (colnames(dataset)) := lapply(.SD, makeBoolean)]
saveRDS(dataset, "data/populationGender.rds")
