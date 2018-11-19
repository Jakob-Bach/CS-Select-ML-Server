#* Returns the current API version.
#*
#* @serializer unboxedJSON
#* @get /version
version <- function() {
  return(list(APIVersion = "0.1"))
}

#* Returns summary data and plots for all features of a dataset.
#*
#* @param dataset The dataset (which is stored on the ML server).
#* @serializer contentType list(type="application/zip")
#* @get /features
getFeatures <- function(dataset) {
  if (missing(dataset)) {
    stop("Param \"dataset\" is required.")
  }
  fileName <- paste0("datasets/", dataset, ".zip")
  if (file.exists(fileName)) {
    return(readBin(fileName, "raw", n = file.info(fileName)$size))
  } else {
    stop(paste0("Dataset \"", dataset, "\" not found on server."))
  }
}

#* Returns a classification score in [0,1] for a selection of features from a dataset.
#*
#* @param features The ids (numeric) of the features which are selected.
#* @param dataset The dataset (which is stored on the ML server).
#* @serializer unboxedJSON
#* @get /score
getScore <- function(dataset, features) {
  if (missing(dataset)) {
    stop("Param \"dataset\" is required.")
  }
  if (missing(features)) {
    stop("Param \"features\" is required.")
  }
  if (!exists(paste0(dataset, "_train_predictors")) || !exists(paste0(dataset, "_train_labels")) ||
      !exists(paste0(dataset, "_test_predictors")) || !exists(paste0(dataset, "_test_labels")) ||
      !exists(paste0(dataset, "_featureMap"))) {
    stop(paste0("Dataset \"", dataset, "\" not found on server."))
  }
  selFeatureIdx <- as.integer(strsplit(features, split = ",", fixed = TRUE))
  selFeatureIdx <- unlist(get(paste0(dataset, "featureMap"))[selFeatureIdx])
  if (any(is.na(selFeatureIdx))) {
    stop("At least one of the selected features does not exist.")
  }
  xgbModel <- xgboost::xgboost(
    data = xgboost::xgb.DMatrix(
      label = get(paste0(dataset, "_train_labels")),
      data = get(paste0(dataset, "_train_predictors"))[, selFeatureIdx]),
    nrounds = 1, verbose = 0,
    params = list(objective = "binary:logistic", nthread = 1))
  prediction <- predict(xgbModel, newdata = get(paste0(dataset, "_test_predictors"))[, selFeatureIdx])
  return(sum(get(paste0(dataset, "_test_labels")) == as.integer(prediction >= 0.5)) /
           length(prediction)) # accuracy
}
