library(data.table)
library(ggplot2)

# Take any vector; if values are effectively boolean but type is not, convert
makeBoolean <- function(x) {
  if (is.numeric(x) && all(x %in% c(NA, 0, 1))) {
    storage.mode(x) <- "logical"
  }
  return(x)
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
createSummaryList <- function(dataset, columnDescription) {
  featureNames <- setdiff(colnames(dataset), "target")
  result <- lapply(featureNames, function(feature) {
    featureSummary <- list()
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
  names(result) <- featureNames
  return(result)
}

# Creates and saves two plots for each features in a dataset: histogram/density
# and histogram/density against classes
createSummaryPlots <- function(dataset, path) {
  progressBar <- txtProgressBar(max = ncol(dataset) - 1, style = 3)
  for (feature in setdiff(colnames(dataset), "target")) {
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
