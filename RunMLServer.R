library(plumber)

# Load datasets
for (fileName in list.files("datasets/", pattern = ".rds$")) {
  assign(gsub(".rds$", "", fileName), value = readRDS(paste0("datasets/", fileName)))
}

# Start server
plumber <- plumb("MLServerAPI.R")
plumber$run(host = "0.0.0.0", port = 8000, swagger = TRUE) # this host is necessary for Docker
