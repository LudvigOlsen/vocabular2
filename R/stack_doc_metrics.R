

#' @title Get the metrics for all documents
#' @description Extracts the nested metrics for each document and concatenates them.
#' @param word_scores Scores tibble from \code{compare_vocabs()}.
#' @param remove_zero_counts Whether to filter out the words
#'  that were not in a document from that document's results. (Logical)
#'
#'  Often reduces the size of the output but may hinder some downstream analyses.
#' @author Ludvig Renbo Olsen, \email{r-pkgs@@ludvigolsen.dk}
#' @export
stack_doc_metrics <- function(word_scores, remove_zero_counts = TRUE){

  docs <- colnames(word_scores[,-c(1:2)])
  plyr::ldply(docs, function(d){
    get_doc_metrics(word_scores = word_scores,
                    doc = d,
                    remove_zero_counts = remove_zero_counts)
  }) %>% dplyr::as_tibble()

}
