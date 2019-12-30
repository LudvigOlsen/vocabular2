calculate_metrics <- function(counts,
                              freqs,
                              doc_counts,
                              epsilons,
                              rel_tf_nrtf_beta = 2,
                              zero_negatives = FALSE,
                              metric_suffix = "") {

  #### Process inputs ####

  # Unpack doc_counts
  doc_contains <- doc_counts[["contains"]]
  doc_counts <- doc_counts[["counts"]]

  if (!is.data.frame(doc_counts) || "In Docs" %ni% colnames(doc_counts)){
    stop("'doc_counts' was not properly unpacked or have changed.")
  }

  # Get the document names
  doc_names <- colnames(freqs)
  n_docs <- length(doc_names)

  if (length(unique(doc_names)) < length(doc_names)){
    stop("'freqs' must contain unique column names only.")
  }

  if (ncol(freqs) != ncol(counts) ||
      nrow(freqs) != nrow(counts)){
    stop("'freqs' and 'counts' must have same shape.")
  }

  if (ncol(freqs) != ncol(doc_contains) ||
      nrow(freqs) != nrow(doc_contains)){
    stop("'freqs' and 'doc_counts$contains' must have same shape.")
  }

  if (ncol(freqs) != ncol(epsilons)){
    stop("'freqs' and 'epsilons' must have same number of columns.")
  }

  if (!all(colnames(counts) == doc_names))
    stop("'freqs' and 'counts' must have same column names.")

  if (!all(colnames(doc_contains) == doc_names))
    stop("'freqs' and 'doc_counts$contains' must have same column names.")

  if (!all(colnames(epsilons) == doc_names))
    stop("'freqs' and 'epsilons' must have same column names.")

  #### Calculate terms ####

  # For each condition, compute the
  # row sum of the other conditions
  sum_rest <- sum_rest_populations(freqs)

  # Normalize row sums
  # As each column sums to one, the row sums will sum to the number of columns in "rest"
  normalized_rest <- sum_rest / (ncol(freqs)-1)

  ## Inverse Document Frequencies
  idf <- calculate_idf(n_docs, doc_counts)

  # Inverse Rest Frequencies
  irf <- calculate_irf(doc_contains)

  # Ensure column orders are the same
  # (they should already be so, but this vital when we subtract the two dfs)
  freqs <- ensure_col_order(freqs, doc_names)
  sum_rest <- ensure_col_order(sum_rest, doc_names)
  normalized_rest <- ensure_col_order(normalized_rest, doc_names)
  irf <- ensure_col_order(irf, doc_names)

  #### Calculate metrics ####

  # Subtract the population sum freqs from the condition freqs
  # This will be positive if the normalized term frequency is larger
  # than the sum of the normalized term frequency in all other conditions
  tf_rtf_scores <- freqs - sum_rest

  # Subtract the population normalized freqs from the condition freqs
  # This will be positive if the term frequency is larger
  # than the mean of the term frequency in all other conditions
  tf_nrtf_scores <- freqs - normalized_rest

  # Divide the tf_nrtf (difference between freqs and normalized rest freqs)
  # with the normalized rest freqs
  # and multiply by term frequency
  rel_tf_nrtf_scores <- calculate_rel_tf_nrtf(
    freqs = freqs,
    tf_nrtf = tf_nrtf_scores,
    normalized_rest = normalized_rest,
    epsilons = epsilons,
    log_denominator = TRUE,
    beta = rel_tf_nrtf_beta)

  # Multiply the relative score with the absolute score
  # This will ensure that term frequency actually matters as well?

  # Term frequency * log inverse document frequency
  tf_idf_scores <- dplyr::mutate_all(freqs, list(function(x){x * idf[["idf"]]}))

  # Term frequency * log inverse rest frequency
  tf_irf_scores <- freqs * irf

  # Find ranks for each metric
  # Note: As idf and irf are highly correlated, we only use the irf metric
  # TODO: Perhaps it's better to stick with the common idf measure?
  tf_rtf_ranks <- calculate_rank(tf_rtf_scores)
  tf_nrtf_ranks <- calculate_rank(tf_nrtf_scores)
  tf_irf_ranks <- calculate_rank(tf_irf_scores)
  tf_rel_tf_nrtf_rank <- calculate_rank(rel_tf_nrtf_scores)

  rank_sums <- tf_rtf_ranks + tf_nrtf_ranks + tf_irf_ranks + tf_rel_tf_nrtf_rank
  rank_ensemble <- calculate_rank(rank_sums)

  #### Prepare output ####

  # Metrics that we might want to zero negatives in
  output <- list(
    "tf_rtf" = add_colnames_suffix(tf_rtf_scores, "_TF_RTF"),
    "tf_nrtf" = add_colnames_suffix(tf_nrtf_scores, "_TF_NRTF"),
    "rel_tf_nrtf" = add_colnames_suffix(rel_tf_nrtf_scores, "_REL_TF_NRTF"),
    "rank_ensemble" = add_colnames_suffix(rank_ensemble, "_RANK_ENS")
  )

  # Set negative scores to zero
  if (isTRUE(zero_negatives)){
    output <- dmap(output, fn = function(x){
      x[x < 0] <- 0
      x
    })
  }

  # Add metrics that also needs the metric suffix (e.g. _weighted)
  output <- c(
    output,
    list(
    "irf" = add_colnames_suffix(irf, "_IRF"),
    "tf_idf" = add_colnames_suffix(tf_idf_scores, "_TF_IDF"),
    "tf_irf" = add_colnames_suffix(tf_irf_scores, "_TF_IRF")
    )
  )

  # Add metric suffix
  if (nchar(metric_suffix) > 0){
    output <- dmap(output, fn = function(x){
      add_colnames_suffix(x, suffix = metric_suffix)
    })
  }

  # Add the IDF tibble
  output[["idf"]] <- idf

  output


}

# log of num docs divided by number of docs with the word (+1 to avoid /0)
calculate_idf <- function(n_docs, doc_count, keep_col_names = FALSE){
  if (!is.data.frame(doc_count))
    doc_count <- dplyr::as_tibble(doc_count)

  # Calculate idf
  idf <- log(n_docs / (1 + doc_count))

  # Rename to idf
  if (!isTRUE(keep_col_names)){
    colnames(idf) <- "idf"
  }

  idf
}

# For each condition,
#   log of num rest divided by number of rest with the word (+1 to avoid /0)
calculate_irf <- function(doc_contains){
  # Get doc counts for each rest population
  doc_count_rest <- sum_rest_populations(doc_contains)
  calculate_idf(nrow(doc_contains)-1, doc_count_rest, keep_col_names = TRUE)
}

# Note: highest score -> highest rank number
calculate_rank <- function(scores){
  scores %>%
    dplyr::mutate_all(list(rank))
}


# If a word is only in one document, we want to reward that
# but it shouldn't drown the impact of the term frequency
# One of two formulas, depending on 'log_denominator'
#   formula 1: (tf_nrtf / log(1 + normalized_rest + epsilon)) * (freqs^beta)
#   formula 2: (tf_nrtf / (normalized_rest + epsilon)) * (freqs^beta)
# Set beta to 0 to not multiply by freqs
calculate_rel_tf_nrtf <- function(freqs,
                                  tf_nrtf,
                                  normalized_rest,
                                  epsilons,
                                  log_denominator = TRUE,
                                  beta = 1) {

  # Add the epsilons
  epsilons <- epsilons %>%
    dplyr::slice(rep(1, each=nrow(normalized_rest)))
  normalized_rest <- normalized_rest + epsilons
  # Ensure it's capped at 1
  normalized_rest[normalized_rest > 1] <- 1

  # Both tf_nrtf and normalized_rest are between 0 and 1

  # Find relative difference between
  # tf_nrtf and the normalized rest
  if (isTRUE(log_denominator)){
    rel <- tf_nrtf / log(1 + normalized_rest)
  } else {
    rel <- tf_nrtf / normalized_rest
  }

  rel*(freqs^beta)

}

# 'contains' is a one-hot tibble with
#   1 if the word is contained in the document
#   0 otherwise
# 'counts' is a single-column tibble with the rowsums of 'contains'
document_count <- function(counts){

  # Is the word in the condition?
  doc_contains <- counts
  doc_contains[doc_contains > 0] <- 1
  doc_counts <- rowSums(doc_contains)
  doc_counts <- tibble::enframe(
    doc_counts, name = NULL, value = "In Docs")

  list(
    "contains" = doc_contains,
    "counts" = doc_counts
  )

}
