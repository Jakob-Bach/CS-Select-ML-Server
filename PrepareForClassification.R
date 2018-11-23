library(data.table)

source("UtilityFunctions.R")

# To specify by user
DATASET_NAME <- "populationGender"

#### Load data ####

# Read data
cat("Reading data ...\n")
dataset <- readRDS(file = paste0("datasets/", DATASET_NAME, ".rds"))
featureNames <- colnames(dataset)[-ncol(dataset)]
targetColumn <- colnames(dataset)[ncol(dataset)]
# Check target
stopifnot(dataset[, is.logical(get(targetColumn)) ||
    (is.factor(get(targetColumn))  && length(levels(get(targetColumn))) == 2)])
# Check that no column name prefix of another (important for xgboost factor encoding)
stopifnot(areColNamesDistinct(colnames(dataset)))

#### Prepare feature summary ####

# Read column description CSV
columnDescription <- data.table(read.csv(file = paste0("datasets/", DATASET_NAME, "_columns.csv"),
    header = TRUE, sep = "\t", as.is = TRUE))
stopifnot(length(intersect(featureNames, columnDescription$dataset_feature)) ==
            length(union(featureNames, columnDescription$dataset_feature)))
# Create and save summary JSON (feature descriptions, statistics, exemplary values)
cat("Creating feature summary JSON ...\n")
dir.create(paste0("datasets/", DATASET_NAME), showWarnings = FALSE)
jsonlite::write_json(createSummaryList(dataset = dataset, featureNames = featureNames,
    columnDescription = columnDescription),
    path = paste0("datasets/", DATASET_NAME, "/summary.json"), auto_unbox = TRUE)
# Create and save summary plots (distribution, distribution against classes)
cat("Creating feature summary plots ...\n")
createSummaryPlots(dataset = dataset, featureNames = featureNames,
    targetColumn = targetColumn, path = paste0("datasets/", DATASET_NAME, "/"))
# Zip feature summary data
cat("Zipping feature summary data ...\n")
oldWd <- getwd()
setwd(paste0(oldWd, "/datasets/", DATASET_NAME))
zip(zipfile = paste0("../", DATASET_NAME, ".zip"), files = list.files())
setwd(oldWd)

#### Prepare classification ####

cat("Preparing data classification ...\n")
# Convert boolean attributes to integer
dataset[, (colnames(dataset)) := lapply(.SD, makeBooleanInteger)]
# Handle NAs in categorical data
dataset[, (colnames(dataset)) := lapply(.SD, makeNAFactor)]
# Harmonize target column (name, encoding as 0/1)
if (is.factor(dataset[, get(targetColumn)])) {
    dataset[, target := as.integer(get(targetColumn)) - 1]
} else {
    dataset[, target := as.integer(get(targetColumn))]
}
dataset[, (targetColumn) := NULL]
# Train-test split (stratified)
set.seed(25)
target0Idx <- dataset[, which(target == 0)]
target1Idx <- dataset[, which(target == 1)]
trainTarget0 <- sample(target0Idx, size = round(0.8 * length(target0Idx)), replace = FALSE)
trainTarget1 <- sample(target1Idx, size = round(0.8 * length(target1Idx)), replace = FALSE)
trainData <- dataset[sort(c(trainTarget0, trainTarget1))]
testData <- dataset[-c(trainTarget0, trainTarget1)]
# Handle NAs in numerical data
naReplacements <- getColMedians(trainData)
trainData <- imputeColValues(trainData, replacements = naReplacements)
testData <- imputeColValues(testData, replacements = naReplacements)
# Convert for "xgboost"
xgbTrainData <- trainData[, -"target"]
xgbTrainPredictors <- Matrix::sparse.model.matrix(~ ., data = xgbTrainData)[, -1]
xgbTrainLabels <- trainData$target
xgbTrainData <- xgboost::xgb.DMatrix(xgbTrainPredictors, label = xgbTrainLabels)
xgbTestData <- testData[, -"target"]
xgbTestPredictors <- Matrix::sparse.model.matrix(~ ., data = xgbTestData)[, -1]
xgbTestLabels <- testData$target
# Save
saveRDS(xgbTrainPredictors, file = paste0("datasets/", DATASET_NAME, "_train_predictors.rds"))
saveRDS(xgbTrainLabels, file = paste0("datasets/", DATASET_NAME, "_train_labels.rds"))
saveRDS(xgbTestPredictors, file = paste0("datasets/", DATASET_NAME, "_test_predictors.rds"))
saveRDS(xgbTestLabels, file = paste0("datasets/", DATASET_NAME, "_test_labels.rds"))
saveRDS(createXgbColMapping(old = featureNames, new = colnames(xgbTrainData)),
    file = paste0("datasets/", DATASET_NAME, "_featureMap.rds"))
