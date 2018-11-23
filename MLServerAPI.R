#* Returns the current API version.
#*
#* @serializer unboxedJSON
#* @get /version
version <- function() {
  return(list(APIVersion = "0.1.4"))
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
  selFeatureIdx <- as.integer(strsplit(features, split = ",", fixed = TRUE)[[1]])
  selFeatureIdx <- get(paste0(dataset, "_featureMap"))[selFeatureIdx]
  if (any(sapply(selFeatureIdx, is.null))) {
    stop("At least one of the selected features does not exist.")
  }
  selFeatureIdx <- unlist(selFeatureIdx)
  xgbModel <- xgboost::xgboost(
    data = xgboost::xgb.DMatrix(
      label = get(paste0(dataset, "_train_labels")),
      data = get(paste0(dataset, "_train_predictors"))[, selFeatureIdx, drop = FALSE]),
    nrounds = 1, verbose = 0,
    params = list(objective = "binary:logistic", nthread = 1))
  prediction <- predict(xgbModel, newdata =
      get(paste0(dataset, "_test_predictors"))[, selFeatureIdx, drop = FALSE])
  mcc <- mcc(as.integer(prediction >= 0.5), get(paste0(dataset, "_test_labels")))
  return(0.5 * (1 + mcc)) # linear transformation from [-1,1] to [0,1]
}

# Matthews Correlation Coefficient for two binary numeric vectors (symmetric
# measure, so assignment order of params does not really matter)
mcc <- function(prediction, actual) {
  tp <- sum(prediction == 1 & actual == 1) * 1.0 # prevent integer overflow
  tn <- sum(prediction == 0 & actual == 0) * 1.0
  fp <- sum(prediction == 1 & actual == 0) * 1.0
  fn <- sum(prediction == 0 & actual == 1) * 1.0
  result <- (tp*tn - fp*fn) / sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn))
  if (is.na(result)) { # just one class in actual or prediction
    result <- 0
  }
  return(result)
}
