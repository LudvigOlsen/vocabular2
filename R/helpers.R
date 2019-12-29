# Utils

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
  data <- data[,cols]
  if(!all(colnames(data) == cols))
    stop("Not all 'cols' were in 'data'.")
  data
}

