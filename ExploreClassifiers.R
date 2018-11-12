library(data.table)

#### Prepare ####

# Make NA explicit factor level for categorical data if necessary
naFactorCols <- names(which(sapply(dataset, function(col) is.factor(col) && any(is.na(col)))))
dataset[, (naFactorCols) := lapply(.SD, function(col) {
  col <- as.character(col)
  col[is.na(col)] <- "<NA>"
  return(factor(col))
}), .SDcols = naFactorCols]
# Stratified train-test split
set.seed(25)
target0 <- dataset[, which(target == "0")]
target1 <- dataset[, which(target == "1")]
trainTarget0 <- sample(target0, size = round(0.8 * length(target0)), replace = FALSE)
trainTarget1 <- sample(target1, size = round(0.8 * length(target1)), replace = FALSE)
trainData <- dataset[sort(c(trainTarget0, trainTarget1))]
testData <- dataset[-c(trainTarget0, trainTarget1)]
# Impute missing numeric values if necessary
preprocModel <- caret::preProcess(trainData, method = "medianImpute")
trainData <- predict(preprocModel, trainData)
testData <- predict(preprocModel, testData)

#### Train ####

# Decision tree [rpart]
rpartModel <- rpart::rpart(formula = target ~ ., data = trainData,
                           method = "class", control = list(cp = 0.001))
prediction <- predict(rpartModel, newdata = testData, type = "prob")[, 2]

# Decision tree [C50]
c50Model <- C50::C5.0(target ~ ., data = trainData)
prediction <- predict(c50Model, newdata = testData, type = "prob")[, 2]

# Conditional inference tree [party]
ctreeModel <- party::ctree(target ~ ., data = trainData)
prediction <- sapply(predict(ctreeModel, newdata = testData, type = "prob"), function(x) x[2])

# Random forest [ranger]
rfModel <- ranger::ranger(formula = target ~ ., data = trainData, num.trees = 1,
    replace = FALSE, sample.fraction = 1, verbose = FALSE, probability = TRUE,
    seed = 25, num.threads = 1)
prediction <- predict(rfModel, data = testData, type = "response")$predictions[, 2]

# Boosted trees [xgboost]
xgbTrainData <- trainData[, -"target"]
xgbTrainPredictors <- Matrix::sparse.model.matrix(~ ., data = xgbTrainData)[, -1]
xgbTrainLabels <- trainData[, as.integer(target) - 1] # factor->integer yields 1/2 instead of 0/1
xgbTrainData <- xgboost::xgb.DMatrix(data = xgbTrainPredictors, label = xgbTrainLabels)
xgbTestData <- testData[, -"target"]
xgbTestPredictors <- Matrix::sparse.model.matrix(~ ., data = xgbTestData)[, -1]
xgbTestLabels <- testData[, as.integer(target) - 1]
xgbTestData <- xgboost::xgb.DMatrix(data = xgbTestPredictors, label = xgbTestLabels)
xgbModel <- xgboost::xgboost(data = xgbTrainData, nrounds = 1, verbose = 0,
    params = list(objective = "binary:logistic", nthread = 1))
prediction <- predict(xgbModel, newdata = xgbTestPredictors)

#### Evaluate ####

caret::confusionMatrix(data = factor(as.integer(prediction >= 0.5)),
    reference = testData$target, mode = "everything", positive = "1")
