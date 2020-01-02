library(dplyr)

files_path <- "./inst/hamlet/"
paths <- list.files(files_path)
hamlet <- plyr::ldply(paths, function(p){
  d <- read.csv(paste0(files_path, p), stringsAsFactors = FALSE, sep="\t", header = FALSE)
  colnames(d) <- "lines"
  d[["character"]] <- p
  d
}) %>% dplyr::as_tibble() %>%
  dplyr::mutate(character = stringr::str_replace_all(character, ".csv", ""),
                character = tools::toTitleCase(character)) %>%
  dplyr::filter(stringr::str_detect(lines, stringr::fixed("["), negate=TRUE))

usethis::use_data(hamlet)
