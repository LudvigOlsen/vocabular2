library(cvms)
context("*_rest_populations()")


test_that("sum_rest_populations() works as expected",{

  df <- tibble::tibble("a" = c(1,1,1),
                       "b" = c(10,10,10),
                       "c" = c(100,100,100))

  # # Test sum_rest_populations
  # # Rows should be 110, 101, 11
  expect_identical(sum_rest_populations(df),
               tibble::tibble("a" = c(110,110,110),
                              "b" = c(101,101,101),
                              "c" = c(11,11,11)))

})


test_that("max_rest_populations() works as expected",{

  df <- tibble::tibble("a" = c(32,11,99),
                       "b" = c(-100,22,33),
                       "c" = c(44,-22,47))

  # # Test sum_rest_populations
  # # Rows should be 110, 101, 11
  expect_identical(max_rest_populations(df),
                   tibble::tibble("a" = c(44,22,47),
                                  "b" = c(44,11,99),
                                  "c" = c(32,22,99)))

})

test_that("max_rest_populations() works as expected",{

  set_seed_for_R_compatibility(1)
  freqs <- tibble::tibble(
    "C1" = normalize(runif(10)),
    "C2" = normalize(runif(10)),
    "C3" = normalize(runif(10))
  )
  freqs[freqs > 0.15 & freqs < 0.3] <- 0
  freqs[freqs > 0.036 & freqs < 0.04] <- 0

  norm_rest <- sum_rest_populations(freqs) / (ncol(freqs)-1)
  tf_nrtf <- freqs - norm_rest

  max_rest <- max_rest_populations(freqs)
  tf_mrtf <- freqs - max_rest

  # This should have been from the counts, but doesn't matter
  # for the test (right?)
  epsilons <- sum_rest_populations(freqs) %>%
    dplyr::summarise_all(.f = list(function(x) {
      1 / sum(x)
    }))

  rel_tf_nrtf <- calculate_relative_score(
    freqs = freqs,
    difference = tf_nrtf,
    population = norm_rest,
    epsilons = epsilons,
    log_denominator = TRUE,
    beta = 1)

  rel_tf_mrtf <- calculate_relative_score(
    freqs = freqs,
    difference = tf_mrtf,
    population = max_rest,
    epsilons = epsilons,
    log_denominator = TRUE,
    beta = 1)

  # # Test sum_rest_populations
  # # Rows should be 110, 101, 11
  expect_identical(max_rest_populations(df),
                   tibble::tibble("a" = c(44,22,47),
                                  "b" = c(44,11,99),
                                  "c" = c(32,22,99)))

})

