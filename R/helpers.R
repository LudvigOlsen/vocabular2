# Utils

# Get all lists in a list with a certain name
# Use: list_of_lists %c% 'list_name'
`%c%` <- function(x, n) lapply(x, `[[`, n)
# From http://stackoverflow.com/questions/5935673/accessing-same-named-list-elements-of-the-list-of-lists-in-r/5936077#5936077

# Not in
`%ni%` <- function(x, table) {
  return(!(x %in% table))

}

# Add underscore until var name is unique
create_tmp_var <- function(data, tmp_var = ".tmp_index_"){
  while (tmp_var %in% colnames(data)){
    tmp_var <- paste0(tmp_var, "_")
  }
  tmp_var
}

# Nest all columns rowwise
nest_rowwise <- function(data){
  n_cols <- ncol(data)
  tmp_index <- create_tmp_var(data)
  data[[tmp_index]] <- seq_len(nrow(data))
  data %>%
    dplyr::group_by(!!as.name(tmp_index)) %>%
    dplyr::group_nest() %>%
    dplyr::pull(.data$data)
}

# Function for normalizing vector
# Elements will sum to 1
normalize <- function(x, avoid_zero_div = FALSE){
  if (isTRUE(avoid_zero_div) && sum(x) == 0){
    # In case a column is all 0s
    # Avoid zero-division
    return(x * 0)
  }
  x / sum(x)
}

# All values will be between 0 and 1
minMaxScaler <- function(x, lower=NULL, upper=NULL){
  if (is.null(lower)) lower <- min(x)
  if (is.null(upper)) upper <- max(x)
  (x - lower) / (upper - lower)
}

# Order data by cols (excluding any columns not in cols)
# Throw error if some cols are not in data
ensure_col_order <- function(data, cols){
  data <- base_select(data = data, cols = cols)
  if(!all(colnames(data) == cols))
    stop("Not all 'cols' were in 'data'.")
  data
}

# Divides x by y
# Optionally,
#   replaces resulting NaNs with 'na_fill'
#   replaced resulting INFs with 'inf_fill'
safe_division <- function(x, y, na_fill = NULL, inf_fill = NULL) {
  res <- x / y
  if (!is.null(na_fill)){
    res[is.na(res)] <- na_fill
  }
  if (!is.null(inf_fill)){
    res[is.infinite(res)] <- inf_fill
  }

  res
}

# Add suffix to all colnames
add_colnames_suffix <- function(df, suffix){
  colnames(df) <- paste0(colnames(df), suffix)
  df
}

base_rename <- function(data, before, after,
                        warn_at_overwrite = FALSE){

  #
  # Replaces name of column in data frame
  #

  # Check names
  if (!is.character(before) || !is.character(after)){
    stop("'before' and 'after' must both be of type character.")
  }
  if (length(before) != 1 || length(before) != 1){
    stop("'before' and 'after' must both have length 1.")
  }

  if (before == after){
    message("'before' and 'after' were identical.")
    return(data)
  }
  # If after is already a column in data
  # remove it, so we don't have duplicate column names
  if (after %in% colnames(data)){
    if (isTRUE(warn_at_overwrite)){
      warning("'after' already existed in 'data' and will be replaced.")
    }
    data[[after]] <- NULL
  }
  colnames(data)[names(data) == before] <- after
  return(data)

}

# Cols should be col names
base_select <- function(data, cols){
  if (is.numeric(cols)) stop("cols must be names")

  if (length(cols) == 1 && !tibble::is_tibble(data)){
    warning(paste0("Selecting a single column with base_select ",
                   "on a data frame (not tibble) might not keep ",
                   "the data frame structure."))
  }

  if(is.data.table(data)){
    return(data[, cols, with = FALSE])
  }

  data[, cols]
}

# Cols should be col names
base_deselect <- function(data, cols){
  if (is.numeric(cols)) stop("cols must be names")

  base_select(data = data, cols = setdiff(names(data), cols))
}

# Apply function to each data frame in a list
# Might be possible with purrr as well?
dmap <- function(ld, fn){
  ld_names <- names(ld)
  output <- plyr::llply(ld, function(d){
    fn(d)
  })
  names(output) <- ld_names
  output
}

# Get R version
check_R_version <- function(){
  major <- as.integer(R.Version()$major)
  minor <- as.numeric(strsplit(R.Version()$minor, ".", fixed = TRUE)[[1]][[1]])
  list("major" = major, "minor" = minor)
}

# Skips testthat test, if the R version is below 3.6.0
# WHY? Due to the change in the random sampling generator
# tests fail on R versions below 3.6.0.
# It is possible to fix this by using the old generator for
# unit tests, but that would take a long time to convert,
# and most likely the code works the same on v3.5
skip_test_if_old_R_version <- function(min_R_version = "3.6"){
  if(check_R_version()[["minor"]] < strsplit(min_R_version, ".", fixed = TRUE)[[1]][[2]]){
    testthat::skip(message = paste0("Skipping test as R version is < ", min_R_version, "."))
  }
}

# Wrapper for setting seed with the sample generator for R versions <3.6
# Used for unittests
# Partly contributed by R. Mark Sharp
set_seed_for_R_compatibility <- function(seed = 1) {
  version <- check_R_version()
  if ((version[["major"]] == 3 && version[["minor"]] >= 6) || version[["major"]] > 3) {
    args <- list(seed, sample.kind = "Rounding")
  } else {
    args <- list(seed)
  }
  suppressWarnings(do.call(set.seed, args))
}

