# TODO Rename Condition to Document

# tc_dfs: List of Term Counts data frame
compare_vocabs <- function(tc_dfs,
                           word_col = "Word",
                           counts_col = "Count",
                           weighting_fn = function(x){log(x+1)},
                           zero_negatives = TRUE){

  #### Check and prepare inputs ####

  # Sanity check
  # In a package, I would create a unique name for condition instead
  if ("Condition" %in% c(word_col, counts_col))
    stop("Neither 'word_col' or 'counts_col' can be named 'Condition'.")

  # Extract conditions
  conditions <- names(tc_dfs)
  # Test list was named correctly
  if (is.null(conditions) ||
      length(conditions) != length(tc_dfs) ||
      length(unique(conditions)) != length(tc_dfs)
  ){
    stop("'tc_dfs' must be a named list with a unique name for each element.")
  }

  # Combine the term-counts dataframes
  term_counts <- tc_dfs %>%
    dplyr::bind_rows(.id = "Condition") %>%
    tidyr::spread(key = "Condition", value = counts_col)

  # Words that are not in a condition's vocabulary
  # will have an NA in Count when we use spread
  # Set NAs to zero
  term_counts[is.na(term_counts)] <- 0

  # Separate the counts and word columns
  counts <- term_counts[, conditions]
  words <- term_counts[, word_col]

  # In case we don't wan't to weight the counts
  if (is.null(weighting_fn))
    weighting_fn <- identity

  # Weight counts column-wise
  weighted_counts <- counts %>%
    dplyr::mutate_all(.funs = list(weighting_fn))

  # Normalize counts column-wise
  freqs <- counts %>%
    dplyr::mutate_all(.funs = list(normalize))

  # Normalize weighted counts column-wise
  weighted_freqs <- weighted_counts %>%
    dplyr::mutate_all(.funs = list(normalize))

  #### Calculate parts for the metrics ####

  # For each condition, compute the
  # row sum of the other conditions
  sum_rest <- sum_rest_populations(freqs, conditions)
  sum_weighted_rest <- sum_rest_populations(weighted_freqs, conditions)

  # Normalize row sums
  # As each column sums to one, the row sums will sum to the number of columns in "rest"
  normalized_rest <- sum_rest / (ncol(freqs)-1)
  normalized_weighted_rest <- sum_weighted_rest / (ncol(weighted_freqs)-1)

  ## Inverse Document Frequencies

  # Unary - Is the word in the condition?
  unary_doc_freqs <- counts
  unary_doc_freqs[unary_doc_freqs > 0] <- 1
  unary_scores <- tibble::enframe(rowSums(unary_doc_freqs),
                                  name = NULL, value = "in_n_docs")

  # log of num docs divided by number of docs with the word (+1 to avoid /0)
  calculate_idf <- function(n_conditions, unary_scores){
    log(n_conditions / (1 + unary_scores))
  }
  idf <- calculate_idf(length(conditions), unary_scores) %>%
    dplyr::as_tibble()
  colnames(idf) <- "idf"

  # Inverse Rest Frequencies

  # Get unary score of rest for each condition
  unary_scores_rest <- sum_rest_populations(unary_doc_freqs,
                                            conditions = conditions)
  # For each condition,
  #   log of num rest divided by number of rest with the word (+1 to avoid /0)
  irfs <- calculate_idf(length(conditions)-1, unary_scores_rest)

  #### Ensure column orders ####

  # Ensure column orders are the same
  # (they should already be so, but this vital when we subtract the two dfs)
  counts <- ensure_col_order(counts, conditions)
  freqs <- ensure_col_order(freqs, conditions)
  weighted_freqs <- ensure_col_order(weighted_freqs, conditions)
  sum_rest <- ensure_col_order(sum_rest, conditions)
  sum_weighted_rest <- ensure_col_order(sum_weighted_rest, conditions)
  normalized_rest <- ensure_col_order(normalized_rest, conditions)
  normalized_weighted_rest <- ensure_col_order(normalized_weighted_rest, conditions)
  irfs <- ensure_col_order(irfs, conditions)

  #### Calculate metrics ####

  # Subtract the population sum freqs from the condition freqs
  # This will be positive if the normalized term frequency is larger
  # than the sum of the normalized term frequency in all other conditions
  tf_rtf_scores <- freqs - sum_rest
  wtf_rwtf_scores <- weighted_freqs - sum_weighted_rest

  # Subtract the population normalized freqs from the condition freqs
  # This will be positive if the term frequency is larger
  # than the mean of the term frequency in all other conditions
  tf_nrtf_scores <- freqs - normalized_rest
  wtf_nrwtf_scores <- weighted_freqs - normalized_weighted_rest

  # Term frequency * log inverse document frequency
  tf_idf_scores <- dplyr::mutate_all(freqs, list(function(x){x * idf[["idf"]]}))
  wtf_idf_scores <- dplyr::mutate_all(weighted_freqs, list(function(x){x * idf[["idf"]]}))
  # Term frequency * log inverse rest frequency
  tf_irf_scores <- freqs * irfs
  wtf_irf_scores <- weighted_freqs * irfs

  # Ensemble Rank scores
  # Rank the words on each score and find the words
  # that are important in most scores
  # Perhaps set an option to weight the metrics?

  # For each metric, find ranks
  # TODO Consider changing to frank in data.table for speed

  # Note: highest score -> highest rank number
  calculate_rank <- function(scores){
    scores %>%
      dplyr::mutate_all(list(rank))
  }

  # Find ranks for each metric
  tf_rtf_ranks <- calculate_rank(tf_rtf_scores)
  tf_nrtf_ranks <- calculate_rank(tf_nrtf_scores)
  tf_irf_ranks <- calculate_rank(tf_irf_scores)
  wtf_rwtf_ranks <- calculate_rank(wtf_rwtf_scores)
  wtf_nrwtf_ranks <- calculate_rank(wtf_nrwtf_scores)
  wtf_irf_ranks <- calculate_rank(wtf_irf_scores)

  # Add rank dfs together
  nonweighted_rank_sums <- tf_rtf_ranks + tf_nrtf_ranks + tf_irf_ranks
  weighted_rank_sums <- wtf_rwtf_ranks + wtf_nrwtf_ranks + wtf_irf_ranks
  overall_rank_sums <- nonweighted_rank_sums + weighted_rank_sums

  # Calculate
  nonweighted_ensemble_ranks <- calculate_rank(nonweighted_rank_sums)
  weighted_ensemble_ranks <- calculate_rank(weighted_rank_sums)
  overall_ensemble_ranks <- calculate_rank(overall_rank_sums)

  # Set negative uniquess scores to zero
  if (isTRUE(zero_negatives)){
    tf_rtf_scores[tf_rtf_scores < 0] <- 0
    wtf_rwtf_scores[wtf_rwtf_scores < 0] <- 0
    tf_nrtf_scores[tf_nrtf_scores < 0] <- 0
    wtf_nrwtf_scores[wtf_nrwtf_scores < 0] <- 0
  }

  #### Prepare output ####

  # Rename columns
  colnames(counts) <- paste0(colnames(counts), "_Count")
  colnames(freqs) <- paste0(colnames(freqs), "_Freq")
  colnames(weighted_freqs) <- paste0(colnames(weighted_freqs), "_WeightedFreq")
  colnames(tf_rtf_scores) <- paste0(colnames(tf_rtf_scores), "_tf_rtf")
  colnames(wtf_rwtf_scores) <- paste0(colnames(wtf_rwtf_scores), "_wtf_rwtf")
  colnames(tf_nrtf_scores) <- paste0(colnames(tf_nrtf_scores), "_tf_nrtf")
  colnames(wtf_nrwtf_scores) <- paste0(colnames(wtf_nrwtf_scores), "_wtf_nrwtf")
  colnames(tf_idf_scores) <- paste0(colnames(tf_idf_scores), "_tf_idf")
  colnames(tf_irf_scores) <- paste0(colnames(tf_irf_scores), "_tf_irf")
  colnames(wtf_idf_scores) <- paste0(colnames(wtf_idf_scores), "_wtf_idf")
  colnames(wtf_irf_scores) <- paste0(colnames(wtf_irf_scores), "_wtf_irf")
  colnames(nonweighted_ensemble_ranks) <- paste0(colnames(nonweighted_ensemble_ranks), "_nwe_ranks")
  colnames(weighted_ensemble_ranks) <- paste0(colnames(weighted_ensemble_ranks), "_we_ranks")
  colnames(overall_ensemble_ranks) <- paste0(colnames(overall_ensemble_ranks), "_e_ranks")

  # combine scores
  metrics <- dplyr::bind_cols(
    tf_rtf_scores,
    tf_nrtf_scores,
    wtf_rwtf_scores,
    wtf_nrwtf_scores,
    tf_idf_scores,
    wtf_idf_scores,
    tf_irf_scores,
    wtf_irf_scores,
    nonweighted_ensemble_ranks,
    weighted_ensemble_ranks,
    overall_ensemble_ranks
  )

  # Nest metrics by condition
  nested_metrics <- plyr::llply(conditions, function(cond){
    metrics[,grepl(cond, colnames(metrics))] %>%
      nest_rowwise() %>%
      tibble::enframe(name=NULL, value=cond)
  }) %>% dplyr::bind_cols()

  # Combine the computed columns
  dplyr::bind_cols(
    words,
    unary_scores,
    idf,
    nested_metrics,
    counts,
    freqs,
    weighted_freqs
  )

}
