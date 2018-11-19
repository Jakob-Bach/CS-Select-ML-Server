library(data.table)

# Take any vector; if values are effectively boolean but type is not, convert
makeBoolean <- function(x) {
  if (is.numeric(x) && all(x %in% c(NA, 0, 1))) {
    storage.mode(x) <- "logical"
  }
  return(x)
}
