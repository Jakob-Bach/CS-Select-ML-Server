library(data.table)

# To specify by user
DATASET_NAME <- "populationGender"

#### Load data ####

# Read data
cat("Reading data ...\n")
dataset <- readRDS(file = paste0("datasets/", DATASET_NAME, ".rds"))
# Check that no column name prefix of another (important for xgboost factor encoding)
stopifnot(areColNamesDistinct(colnames(dataset)))

#### Prepare feature summary ####

# Read column description CSV
columnDescription <- data.table(read.csv(file = paste0("datasets/", DATASET_NAME, "_columns.csv"),
    header = TRUE, sep = "\t", as.is = TRUE))
featureNames <- setdiff(colnames(dataset), "target")
stopifnot(length(intersect(featureNames, columnDescription$Feature)) ==
            length(union(featureNames, columnDescription$Feature)))
# Create and save summary JSON (feature descriptions, statistics, exemplary values)
cat("Creating feature summary JSON ...\n")
dir.create(paste0("datasets/", DATASET_NAME), showWarnings = FALSE)
jsonlite::write_json(createSummaryList(dataset = dataset, columnDescription = columnDescription),
    path = paste0("datasets/", DATASET_NAME, "/summary.json"), auto_unbox = TRUE)
# Create and save summary plots (distribution, distribution against classes)
cat("Creating feature summary plots ...\n")
createSummaryPlots(dataset = dataset, path = paste0("datasets/", DATASET_NAME, "/"))
# Zip feature summary data
cat("Zipping feature summary data ...\n")
oldWd <- getwd()
setwd(paste0(oldWd, "/datasets/", DATASET_NAME))
zip(zipfile = paste0("../", DATASET_NAME, ".zip"), files = list.files())
setwd(oldWd)
