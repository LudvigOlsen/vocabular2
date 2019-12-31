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
