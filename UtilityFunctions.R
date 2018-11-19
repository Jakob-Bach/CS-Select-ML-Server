library(data.table)
library(ggplot2)

# Take any vector; if values are effectively boolean but type is not, convert
makeBoolean <- function(x) {
  if (is.numeric(x) && all(x %in% c(NA, 0, 1))) {
    storage.mode(x) <- "logical"
  }
  return(x)
}

# Take any vector; if boolean, convert to integer
makeBooleanInteger <- function(x) {
  if (is.logical(x)) {
    x <- as.integer(x)
  }
  return(x)
}

# Take any vector; if factor with NAs, make NAs an explicit level
makeNAFactor <- function(x) {
  if (is.factor(x) && any(is.na(x))) {
    x <- as.character(x)
    x[is.na(x)] <- "<N/A>"
    x <- factor(x)
  }
  return(x)
}

# Returns a named vector containing the median of the numeric columns;
# for integer columns, if the median falls between two values (is .5),
# it is rounded down
getColMedians <- function(dataset) {
  numericCols <- names(which(sapply(dataset, is.numeric)))
  return(sapply(dataset[, mget(numericCols)], function(x) {
    result <- median(x, na.rm = TRUE)
    if (is.integer(x)) {
      return(as.integer(result))
    } else {
      return(result)
    }
  }))
}

# Takes a data.table and a named list of replacement values; for each column,
# NAs are replaced with a value from "replacements" (name matching)
imputeColValues <- function(dataset, replacements) {
  stopifnot(length(unique(names(replacements))) == length(replacements))
  result <- copy(dataset)
  for (colName in names(replacements)) {
    replacementValue <- replacements[colName]
    if (colName %in% colnames(dataset) && !is.na(replacementValue)) {
      result[is.na(get(colName)), (colName) := replacementValue]
    }
  }
  return(result)
}

# Maps a vector of features (column names) to a list of column names used when
# creating an xgb.DMatrix (categorical features might result in several columns)
createXgbColMapping <- function(old, new) {
  result <- lapply(old, function(colName) grep(paste0("^", colName), new, value = TRUE))
  names(result) <- old
  stopifnot(all(sapply(result, length) > 0)) # each feature has to be mapped
  stopifnot(sum(sapply(result, length)) == length(new))
  return(result)
}

# Check if there are identical column names or one column name is prefix of another
areColNamesDistinct <- function(colNames) {
  if (length(unique(colNames)) != length(colNames)) {
    return(FALSE)
  }
  names1 <- rep(colNames, times = length(colNames))
  names2 <- rep(colNames, each = length(colNames))
  include <- names1 != names2 # exclude comparison of column to itself
  names1 <- names1[include]
  names2 <- names2[include]
  return(!any(startsWith(names1, names2)))
}

# Summarizes all features of a dataset, including description strings from the
# data.table "columnDescription"
createSummaryList <- function(dataset, featureNames, columnDescription) {
  result <- lapply(1:length(featureNames), function(i) {
    feature <- featureNames[[i]]
    featureSummary <- list()
    featureSummary[["id"]] <- i
    featureSummary[["name"]] <- feature
    featureSummary[["description"]] <- columnDescription[Feature == feature, Description]
    featureSummary[["NAs"]] <- dataset[, sum(is.na(get(feature))) / .N]
    featureSummary[["values"]] <- dataset[, as.character(unique(get(feature))[1:10])]
    featureSummary[["values"]] <- featureSummary[["values"]][!is.na(featureSummary[["values"]])]
    if (is.numeric(dataset[, get(feature)])) {
      featureSummary[["values"]] <- as.numeric(featureSummary[["values"]])
      stats <- summary(dataset[, get(feature)])[1:6]
      featureSummary[names(stats)] <- stats
    }
    return(featureSummary)
  })
  return(result)
}

# Creates and saves two plots for each features in a dataset: histogram/density
# and histogram/density against classes
createSummaryPlots <- function(dataset, featureNames, path) {
  progressBar <- txtProgressBar(max = ncol(dataset) - 1, style = 3)
  for (feature in featureNames) {
    if (is.numeric(dataset[, get(feature)]) && !(is.integer(dataset[, get(feature)]) &&
                                                 dataset[, uniqueN(get(feature)) <= 10])) {
      ggplot(data = dataset) +
        geom_density(aes(x = get(feature)), na.rm = TRUE) +
        labs(x = paste0("Feature: \"", feature, "\""), y = "Density")
      ggsave(filename = paste0(path, feature, ".png"), width = 4, height = 4)
      ggplot(data = dataset) +
        geom_density(aes(x = get(feature), fill = target),alpha = 0.5, na.rm = TRUE) +
        labs(x = paste0("Feature: \"", feature, "\""), y = "Density by class", fill = "Class") +
        theme(legend.position = "bottom")
      ggsave(filename = paste0(path, feature, "_class.png"), width = 4, height = 4)
    } else {# categorical, integer with 10 distinct values or less
      ggplot(data = dataset) +
        geom_bar(aes(x = get(feature))) +
        labs(x = paste0("Feature: \"", feature, "\""), y = "Count")
      ggsave(filename = paste0(path, feature, ".png"), width = 4, height = 4)
      ggplot(data = dataset) +
        geom_bar(aes(x = get(feature), fill = target), position = "dodge") +
        labs(x = paste0("Feature: \"", feature, "\""), y = "Count", fill = "Class") +
        theme(legend.position = "bottom")
      ggsave(filename = paste0(path, feature, "_class.png"), width = 4, height = 4)
    }
    setTxtProgressBar(progressBar, value = getTxtProgressBar(progressBar) + 1)
  }
  close(progressBar)
  return(TRUE)
}
