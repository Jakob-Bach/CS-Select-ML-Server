library(data.table)

#### Explore datasets ####

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
