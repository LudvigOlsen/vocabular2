library(dplyr)

files_path <- "./inst/hamlet/"
paths <- list.files(files_path)
hamlet <- plyr::ldply(paths, function(p){
  d <- read.csv(paste0(files_path, p), stringsAsFactors = FALSE, sep="\t", header = FALSE)
  colnames(d) <- "Line"
  d[["Character"]] <- p
  d
}) %>% dplyr::as_tibble() %>%
  dplyr::mutate(Character = stringr::str_replace_all(Character, ".csv", ""),
                Character = tools::toTitleCase(Character)) %>%
  dplyr::filter(stringr::str_detect(Line, stringr::fixed("["), negate=TRUE))

# usethis::use_data(hamlet, overwrite = TRUE)
