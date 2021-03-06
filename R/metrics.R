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
  rtf <- sum_rest_populations(freqs)

  # Normalize row sums
  # As each column sums to one, the row sums will sum to the number of columns in "rest"
  nrtf <- rtf / (ncol(freqs)-1)

  # Max row frequency in rest
  mrtf <- max_rest_populations(freqs)

  ## Inverse Document Frequencies
  idf <- calculate_idf(n_docs, doc_counts)

  # Inverse Rest Frequencies
  irf <- calculate_irf(doc_contains)

  # Ensure column orders are the same
  # (they should already be so, but this is vital when we subtract the two dfs)
  freqs <- ensure_col_order(freqs, doc_names)
  rtf <- ensure_col_order(rtf, doc_names)
  nrtf <- ensure_col_order(nrtf, doc_names)
  mrtf <- ensure_col_order(mrtf, doc_names)
  irf <- ensure_col_order(irf, doc_names)

  #### Calculate metrics ####

  # Subtract the population sum freqs from the condition freqs
  # This will be positive if the normalized term frequency is larger
  # than the sum of the normalized term frequency in all other conditions
  tf_rtf_scores <- freqs - rtf

  # Subtract the population normalized freqs from the condition freqs
  # This will be positive if the term frequency is larger
  # than the mean of the term frequency in all other conditions
  tf_nrtf_scores <- freqs - nrtf

  # Subtract the population max freqs from the condition freqs
  # This will be positive if the term frequency is larger
  # than the maximum term frequency in all other conditions
  tf_mrtf_scores <- freqs - mrtf

  # Divide the tf_nrtf (difference between freqs and normalized rest freqs)
  # with the normalized rest freqs
  # and multiply by term frequency
  rel_tf_nrtf_scores <- calculate_relative_score(
    freqs = freqs,
    difference = tf_nrtf_scores,
    population = nrtf,
    epsilons = epsilons,
    log_denominator = TRUE,
    beta = rel_tf_nrtf_beta)

  # Divide the tf_mrtf (difference between freqs and max rest freqs)
  # with the max rest freqs
  # and multiply by term frequency
  rel_tf_mrtf_scores <- calculate_relative_score(
    freqs = freqs,
    difference = tf_mrtf_scores,
    population = mrtf,
    epsilons = epsilons,
    log_denominator = TRUE,
    beta = rel_tf_nrtf_beta)

  # Term frequency * log inverse document frequency
  tf_idf_scores <- dplyr::mutate_all(freqs, list(function(x){x * idf[["IDF"]]}))

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
    "rtf" = add_colnames_suffix(rtf, "_RTF"),
    "nrtf" = add_colnames_suffix(nrtf, "_NRTF"),
    "mrtf" = add_colnames_suffix(mrtf, "_MRTF"),
    "tf_rtf" = add_colnames_suffix(tf_rtf_scores, "_TF_RTF"),
    "tf_nrtf" = add_colnames_suffix(tf_nrtf_scores, "_TF_NRTF"),
    "tf_mrtf" = add_colnames_suffix(tf_mrtf_scores, "_TF_MRTF"),
    "rel_tf_nrtf" = add_colnames_suffix(rel_tf_nrtf_scores, "_REL_TF_NRTF"),
    "rel_tf_mrtf" = add_colnames_suffix(rel_tf_mrtf_scores, "_REL_TF_MRTF"),
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
  output[["IDF"]] <- idf

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
    colnames(idf) <- "IDF"
  }

  idf
}

# For each condition,
#   log of num rest divided by number of rest with the word (+1 to avoid /0)
calculate_irf <- function(doc_contains){
  # Get doc counts for each rest population
  doc_count_rest <- sum_rest_populations(doc_contains)
  calculate_idf(ncol(doc_contains)-1, doc_count_rest, keep_col_names = TRUE)
}

# Note: highest score -> highest rank number
calculate_rank <- function(scores){
  scores %>%
    dplyr::mutate_all(list(rank))
}


# If a word is only in one document, we want to reward that
# but it shouldn't drown the impact of the term frequency
# One of two formulas, depending on 'log_denominator'
#   formula 1: (tf_nrtf / log(1 + nrtf + epsilon)) * (freqs^beta)
#   formula 2: (tf_nrtf / (nrtf + epsilon)) * (freqs^beta)
# Set beta to 0 to not multiply by freqs
# @param difference: like tf_nrtf (difference from population mean/max/...)
# @param population: like nrtf (population mean/max/...)
calculate_relative_score <- function(freqs,
                                     difference,
                                     population,
                                     epsilons,
                                     log_denominator = TRUE,
                                     beta = 1) {

  # Add the epsilons
  epsilons <- epsilons %>%
    dplyr::slice(rep(1, each=nrow(population)))
  population <- population + epsilons
  # Ensure it's capped at 1
  population[population > 1] <- 1

  # Both difference and population are between 0 and 1

  # Find relative difference between
  # difference and the normalized rest
  if (isTRUE(log_denominator)){
    rel <- difference / log(1 + population)
  } else {
    rel <- difference / population
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
