library(plumber)

# Load datasets (might not work here, maybe only in API file, as separate environment)

# Start server
plumber <- plumb("MLServerAPI.R")
plumber$run(port = 8000, swagger = TRUE)
