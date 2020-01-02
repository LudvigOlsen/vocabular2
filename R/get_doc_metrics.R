
#' @title Get the metrics for one of the documents
#' @description Extracts the nested columns for one of the documents.
#' @param word_scores Scores tibble from \code{compare_vocabs()}.
#' @param doc Name of document to retrieve metrics for.
#' @param remove_zero_counts Whether to filter out words
#'  that were not in the document. (Logical)
#' @author Ludvig Renbo Olsen, \email{r-pkgs@@ludvigolsen.dk}
#' @export
get_doc_metrics <- function(word_scores, doc, remove_zero_counts = TRUE){

  cols_to_get <- intersect(colnames(word_scores),
                           c("Word", "In Docs", "IDF", doc))

  # Get relevant columns
  doc_cols <- word_scores %>%
    base_select(cols = cols_to_get)

  # Unnest the metrics
  doc_cols <- doc_cols %>% tidyr::unnest(cols = doc)
  # Clean up the column names
  colnames(doc_cols) <- stringr::str_replace_all(colnames(doc_cols),
                                                 paste0(doc,"_"), "")
  # Add the document name
  doc_cols <- tibble::add_column(doc_cols, Doc = doc, .before = cols_to_get[[1]])

  # Remove rows where Count is 0
  if (isTRUE(remove_zero_counts))
    doc_cols <- doc_cols[doc_cols[["Count"]] > 0,]

  doc_cols
}
