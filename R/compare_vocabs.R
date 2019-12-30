# TODO Rename Condition to Document

# tc_dfs: List of Term Counts data frame
#' @title Compare vocabularies
#' @param tc_dfs Named list of Term Counts data frames.
#'
#'  Each data frame must contain a column with the words and a column with their counts.
#'
#'  Each document must be uniquely named.
#' @param weighting_fn Function for weighting the count column before normalizing to frequency.
#'  The metrics using the weighting function will be named with a "_weighted" suffix.
#'
#'  NOTE: This is experimental. The metrics have not been thought through and some may not be meaningful.
#' @keywords internal
#' @importFrom dplyr %>%
#' @import data.table
compare_vocabs <- function(tc_dfs,
                           word_col = "Word",
                           counts_col = "Count",
                           weighting_fn = function(x){log(x+1)},
                           rel_tf_nrtf_beta = 1,
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
  counts <- base_select(term_counts, conditions)
  words <- base_select(term_counts, word_col)

  # Document counts
  # list with two elements
  #   'contains' is a one hot - word in doc?
  #   'counts' are rowsums of 'contains'
  doc_counts <- document_count(counts)

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

  # Calculate epsilons (1/sum(counts_rest))
  # These are used to add +1 smoothing in some metrics
  epsilons <- sum_rest_populations(counts) %>%
    dplyr::summarise_all(.f = list(function(x) {
      1 / sum(x)
    }))

  # Weight the epsilons
  weighted_epsilons <- epsilons %>%
    dplyr::mutate_all(.funs = list(weighting_fn))

  #### Calculate metrics ####

  metrics <- calculate_metrics(
    counts = counts,
    freqs = freqs,
    doc_counts = doc_counts,
    epsilons = epsilons,
    rel_tf_nrtf_beta = rel_tf_nrtf_beta,
    zero_negatives = zero_negatives
  )
  idf <- metrics[["idf"]]
  metrics[["idf"]] <- NULL

  weighted_metrics <- calculate_metrics(
    counts = weighted_counts,
    freqs = weighted_freqs,
    doc_counts = doc_counts,
    epsilons = weighted_epsilons,
    rel_tf_nrtf_beta = rel_tf_nrtf_beta,
    zero_negatives = zero_negatives,
    metric_suffix = "_weighted"
  )
  weighted_metrics[["idf"]] <- NULL
  weighted_metrics[["irf"]] <- NULL

  metrics <- dplyr::bind_cols(
    c(
    metrics,
    weighted_metrics
    )
  )

  #### Prepare output ####

  # Rename columns
  counts <- add_colnames_suffix(counts, "_Count")
  freqs <- add_colnames_suffix(freqs, "_Freq")
  weighted_freqs <- add_colnames_suffix(weighted_freqs, "_WeightedFreq")

  # Nest metrics by condition
  nested_metrics <- plyr::llply(conditions, function(cond){
    metrics %>%
      base_select(cols = grepl(cond, colnames(metrics))) %>%
      nest_rowwise() %>%
      tibble::enframe(name=NULL, value=cond)
  }) %>% dplyr::bind_cols()

  # Combine the computed columns
  dplyr::bind_cols(
    words,
    doc_counts[["counts"]],
    idf,
    nested_metrics,
    counts,
    freqs,
    weighted_freqs
  )

}
