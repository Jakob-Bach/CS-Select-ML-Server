library(data.table)

#### Overview of all available datasets ####

allDatasets <- data(package = .packages(all.available = TRUE))$results
datasetOverview <- rbindlist(lapply(1:nrow(allDatasets), function(i) {
  tryCatch({# there might be problems with some packages
    datasetPackage <- allDatasets[i, 1]
    datasetName <- allDatasets[i, 3]
    datasetTitle <- allDatasets[i, 4]
    env <- new.env()
    data(list = datasetName, package = datasetPackage, envir = env) # load to env
    dataset <- env[[datasetName]]
    if (is.data.frame(dataset)) {
      return(list(Package = datasetPackage, DatasetName = datasetName,
          DatasetTitle = datasetTitle, Objects = nrow(dataset), Features = ncol(dataset)))
    } else {
      return(NULL)
    }
  }, error = function(e) NULL)
})) # some warnings might be displayed
View(datasetOverview[Objects > 500 & Features > 30])

#### Prepare single datasets for classification ####

# kernlab::spam
data(spam, package = "kernlab")
dataset <- data.table(spam)
rm(spam)
dataset[, target := factor(as.integer(type == "spam"))]
dataset[, type := NULL]

# kernlab::ticdata
data(ticdata, package = "kernlab")
dataset <- data.table(ticdata)
rm(ticdata)
dataset[, target := factor(as.integer(CARAVAN == "insurance"))]
dataset[, CARAVAN := NULL]

# randomForestSRC::housing
data(housing, package = "randomForestSRC")
dataset <- data.table(housing)
rm(housing)
dataset[, target := factor(as.integer(SalePrice >= 160))]
dataset[, SalePrice := NULL]
