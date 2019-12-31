# Given a data frame with n columns
# For each c in n:
#   Remove c from data frame
#   Calculate row sum for rest
sum_rest_populations <- function(freqs_df){
  # For each document, compute the
  # row sum of the other docs
  summarize_rest_populations(freqs_df, fn = rowSums)
}

max_rest_populations <- function(freqs_df){
  # For each document, compute the
  # row max of the other docs
  summarize_rest_populations(freqs_df, fn = function(df){
    df %>%
      dplyr::mutate(.__m__ = pmax(!!!rlang::syms(colnames(df)))) %>%
      dplyr::pull(.data$.__m__)
  })
}


# rowwise summarization of rest populations
summarize_rest_populations <- function(freqs_df, fn){
  docs <- colnames(freqs_df)
  plyr::llply(docs, function(d){
    # Remove the column for current document
    rest <- base_deselect(freqs_df, cols = d)
    # Return row sums
    tibble::enframe(fn(rest),
                    name=NULL, value=d)
  }) %>%
    dplyr::bind_cols()

}
