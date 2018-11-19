library(plumber)

# Load datasets
for (fileName in list.files("datasets/", pattern = ".rds$")) {
  assign(gsub(".rds$", "", fileName), value = readRDS(paste0("datasets/", fileName)))
}

# Start server
plumber <- plumb("MLServerAPI.R")
plumber$run(port = 8000, swagger = TRUE)
