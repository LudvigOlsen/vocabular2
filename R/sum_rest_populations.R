# Given a data frame with n columns
# For each c in n:
#   Remove c from data frame
#   Calculate row sum for rest
sum_rest_populations <- function(freqs_df){
  # For each document, compute the
  # row sum of the other docs
  docs <- colnames(freqs_df)
  plyr::llply(docs, function(d){
    # Remove the column for current document
    rest <- base_deselect(freqs_df, cols = d)
    # Return row sums
    tibble::enframe(rowSums(rest), name=NULL, value=d)
  }) %>%
    dplyr::bind_cols()
}

# # Test sum_rest_populations
# # Rows should be 110, 101, 11
# tibble::tibble("a" = c(1,1,1),
#                "b" = c(10,10,10),
#                "c" = c(100,100,100)) %>%
#   sum_rest_populations(c("a","b","c"))

