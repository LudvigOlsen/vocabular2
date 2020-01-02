library(dplyr)

files_path <- "./inst/hamlet/"
paths <- list.files()files_path
hamlet <- plyr::ldply(paths, function(p){
  d <- read.csv(paste0(files_path, p), stringsAsFactors = FALSE, sep="\t", header = FALSE)
  colnames(d) <- "lines"
  d[["character"]] <- p
  d
})
  dplyr::mutate(character)
