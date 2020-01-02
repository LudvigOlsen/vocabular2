
<!-- README.md is generated from README.Rmd. Please edit that file -->

# vocabular2

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- [![CRAN status](https://www.r-pkg.org/badges/version/vocabr)](https://CRAN.R-project.org/package=vocabr) -->
<!-- badges: end -->

The goal of vocabular2 is to compare vocabularies on a set of metrics.
There’s currently no clear development path for the package. It may
become usable in the future, but for now it’s not adviced to use the
code for your projects.

## Installation

You can install the development version with:

``` r
devtools::install_github("ludvigolsen/vocabular2")
```

## Simple Example

``` r
library(vocabular2)
library(tm)
library(tidyverse)
library(knitr)
```

``` r
txt_1 <- "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec at tincidunt ligula. Suspendisse sed dolor eu libero ultrices dignissim. Sed eget est magna. Quisque molestie a enim ut tristique. Vivamus molestie vehicula augue in maximus. Integer imperdiet ligula at condimentum luctus. Integer facilisis id ex eu dapibus. Quisque maximus ex arcu, quis auctor nisl rhoncus quis. Nulla ultrices libero a ultrices tincidunt. Donec gravida viverra odio, quis posuere est pellentesque quis."

txt_2 <- " Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer pulvinar nibh justo, vel vestibulum velit vulputate a. Vestibulum urna lorem, dapibus at vulputate porttitor, eleifend a turpis. Praesent ultrices quam vitae sollicitudin gravida. Donec eu tincidunt orci. Aliquam placerat ligula at lobortis viverra. Aenean sed ligula tincidunt, volutpat dui id, gravida lacus. Praesent mattis, nibh eu convallis sagittis, tortor erat pretium nulla, nec ullamcorper nisl lorem in arcu. Praesent convallis imperdiet libero, aliquet hendrerit augue gravida eu. Fusce tristique risus quam, vel tincidunt tortor sagittis eu."
```

``` r
# Create a term-count tibble

count_terms <- function(t){
  docs <- Corpus(VectorSource(t))
  # do things like removing stopwords, lemmatization, etc.
  docs <- tm_map(docs, removeWords, stopwords("english"))
  dtm <- TermDocumentMatrix(docs)
  m <- as.matrix(dtm)
  v <- sort(rowSums(m), decreasing=TRUE)
  d <- tibble::tibble(Word = names(v), Count=v)
  d
}

txt_1_tc <- count_terms(txt_1)
txt_2_tc <- count_terms(txt_2)
```

``` r
scores <- compare_vocabs(tc_dfs = list("txt_1" = txt_1_tc,
                                       "txt_2" = txt_2_tc))
scores
#> # A tibble: 96 x 4
#>    Word        `In Docs` txt_1             txt_2            
#>    <chr>           <dbl> <list>            <list>           
#>  1 adipiscing          2 <tibble [1 × 11]> <tibble [1 × 11]>
#>  2 aenean              1 <tibble [1 × 11]> <tibble [1 × 11]>
#>  3 aliquam             1 <tibble [1 × 11]> <tibble [1 × 11]>
#>  4 aliquet             1 <tibble [1 × 11]> <tibble [1 × 11]>
#>  5 amet,               2 <tibble [1 × 11]> <tibble [1 × 11]>
#>  6 arcu,               1 <tibble [1 × 11]> <tibble [1 × 11]>
#>  7 arcu.               1 <tibble [1 × 11]> <tibble [1 × 11]>
#>  8 auctor              1 <tibble [1 × 11]> <tibble [1 × 11]>
#>  9 augue               2 <tibble [1 × 11]> <tibble [1 × 11]>
#> 10 condimentum         1 <tibble [1 × 11]> <tibble [1 × 11]>
#> # … with 86 more rows
```

``` r
get_doc_metrics(scores, "txt_1") %>% 
  arrange(desc(REL_TF_NRTF)) %>% 
  head(10) %>% 
  kable()
```

| Doc    | Word     | In Docs |   TF\_RTF |  TF\_NRTF |  TF\_MRTF | REL\_TF\_NRTF | REL\_TF\_MRTF | RANK\_ENS |         IRF |     TF\_IDF |     TF\_IRF | Count |        TF |
| :----- | :------- | ------: | --------: | --------: | --------: | ------------: | ------------: | --------: | ----------: | ----------: | ----------: | ----: | --------: |
| txt\_1 | est      |       1 | 0.0333333 | 0.0333333 | 0.0333333 |     0.0883322 |     0.0883322 |      93.5 |   0.0000000 |   0.0000000 |   0.0000000 |     2 | 0.0333333 |
| txt\_1 | libero   |       1 | 0.0333333 | 0.0333333 | 0.0333333 |     0.0883322 |     0.0883322 |      93.5 |   0.0000000 |   0.0000000 |   0.0000000 |     2 | 0.0333333 |
| txt\_1 | molestie |       1 | 0.0333333 | 0.0333333 | 0.0333333 |     0.0883322 |     0.0883322 |      93.5 |   0.0000000 |   0.0000000 |   0.0000000 |     2 | 0.0333333 |
| txt\_1 | quis     |       1 | 0.0333333 | 0.0333333 | 0.0333333 |     0.0883322 |     0.0883322 |      93.5 |   0.0000000 |   0.0000000 |   0.0000000 |     2 | 0.0333333 |
| txt\_1 | quis.    |       1 | 0.0333333 | 0.0333333 | 0.0333333 |     0.0883322 |     0.0883322 |      93.5 |   0.0000000 |   0.0000000 |   0.0000000 |     2 | 0.0333333 |
| txt\_1 | quisque  |       1 | 0.0333333 | 0.0333333 | 0.0333333 |     0.0883322 |     0.0883322 |      93.5 |   0.0000000 |   0.0000000 |   0.0000000 |     2 | 0.0333333 |
| txt\_1 | ultrices |       2 | 0.0373418 | 0.0373418 | 0.0373418 |     0.0746797 |     0.0746797 |      90.0 | \-0.6931472 | \-0.0202733 | \-0.0346574 |     3 | 0.0500000 |
| txt\_1 | dolor    |       2 | 0.0206751 | 0.0206751 | 0.0206751 |     0.0275654 |     0.0275654 |      63.5 | \-0.6931472 | \-0.0135155 | \-0.0231049 |     2 | 0.0333333 |
| txt\_1 | donec    |       2 | 0.0206751 | 0.0206751 | 0.0206751 |     0.0275654 |     0.0275654 |      63.5 | \-0.6931472 | \-0.0135155 | \-0.0231049 |     2 | 0.0333333 |
| txt\_1 | integer  |       2 | 0.0206751 | 0.0206751 | 0.0206751 |     0.0275654 |     0.0275654 |      63.5 | \-0.6931472 | \-0.0135155 | \-0.0231049 |     2 | 0.0333333 |

``` r
get_doc_metrics(scores, "txt_2") %>% 
  arrange(desc(REL_TF_NRTF)) %>% 
  head(10) %>% 
  kable()
```

| Doc    | Word       | In Docs |   TF\_RTF |  TF\_NRTF |  TF\_MRTF | REL\_TF\_NRTF | REL\_TF\_MRTF | RANK\_ENS | IRF | TF\_IDF | TF\_IRF | Count |        TF |
| :----- | :--------- | ------: | --------: | --------: | --------: | ------------: | ------------: | --------: | --: | ------: | ------: | ----: | --------: |
| txt\_2 | praesent   |       1 | 0.0379747 | 0.0379747 | 0.0379747 |     0.0872436 |     0.0872436 |      96.0 |   0 |       0 |       0 |     3 | 0.0379747 |
| txt\_2 | convallis  |       1 | 0.0253165 | 0.0253165 | 0.0253165 |     0.0387750 |     0.0387750 |      92.0 |   0 |       0 |       0 |     2 | 0.0253165 |
| txt\_2 | eu.        |       1 | 0.0253165 | 0.0253165 | 0.0253165 |     0.0387750 |     0.0387750 |      92.0 |   0 |       0 |       0 |     2 | 0.0253165 |
| txt\_2 | nibh       |       1 | 0.0253165 | 0.0253165 | 0.0253165 |     0.0387750 |     0.0387750 |      92.0 |   0 |       0 |       0 |     2 | 0.0253165 |
| txt\_2 | tortor     |       1 | 0.0253165 | 0.0253165 | 0.0253165 |     0.0387750 |     0.0387750 |      92.0 |   0 |       0 |       0 |     2 | 0.0253165 |
| txt\_2 | vel        |       1 | 0.0253165 | 0.0253165 | 0.0253165 |     0.0387750 |     0.0387750 |      92.0 |   0 |       0 |       0 |     2 | 0.0253165 |
| txt\_2 | vestibulum |       1 | 0.0253165 | 0.0253165 | 0.0253165 |     0.0387750 |     0.0387750 |      92.0 |   0 |       0 |       0 |     2 | 0.0253165 |
| txt\_2 | vulputate  |       1 | 0.0253165 | 0.0253165 | 0.0253165 |     0.0387750 |     0.0387750 |      92.0 |   0 |       0 |       0 |     2 | 0.0253165 |
| txt\_2 | aenean     |       1 | 0.0126582 | 0.0126582 | 0.0126582 |     0.0096937 |     0.0096937 |      68.5 |   0 |       0 |       0 |     1 | 0.0126582 |
| txt\_2 | aliquam    |       1 | 0.0126582 | 0.0126582 | 0.0126582 |     0.0096937 |     0.0096937 |      68.5 |   0 |       0 |       0 |     1 | 0.0126582 |

## Metrics

### TF-IDF and TF-IRF (Term Frequency - Inverse Rest Frequency)

These are highly correlated (\>0.999).

\[ tf(t,d)=\frac{f_{t,d}}{\sum_{t'}^{d}f_{t',d}} \]
\[ idf(t,D)=\log{\frac{|D|}{1+|\{d \in D:t \in d\}|}} \]
\[ irf(t,d,D)=\log{\frac{|D|-1}{1+|\{d \in D:t \in d \land d' \not = d \}|}} \]
\[ tfidf(t,d,D) = tf(t,d) \cdot idf(t,D) \]
\[ tfirf(t,d,D) = tf(t,d) \cdot irf(t,d,D) \]

### TF-RTF (Term Frequency - Rest Term Frequency)

TF-RTF is positive when the term frequency is higher in the current
document than the sum of the term frequencies in the rest of the corpus.

\[ rtf(t,d,D) = \sum_{d' \not = d}^{D}tf(t,d') \]
\[ tfrtf(t,d,D) = tf(t,d)-rtf(t,d,D) \]

### TF-NRTF (Term Frequency - Normalized Rest Term Frequency)

As our selected TF function ensures that frequencies add up to 1
document-wise, the NRTF (Normalized Rest Term Frequency) is simply the
average term frequency in the other documents, instead of the sum as in
RTF.

\[ nrtf(t,d,D) = \frac{rtf(t,d,D)}{|D|-1} \]
\[ tfnrtf(t,d,D) = tf(t,d)-nrtf(t,d,D) \]

### TF-MRTF (Term Frequency - Maximum Rest Term Frequency)

Instead of the normalized/average rest term frequency, we instead use
the maximum rest term
frequency.

\[ Mrtf(t,d,D) = \frac{\max{\{tf(t,d'):d' \in D \land d' \not = d\}}}{|D|-1} \]

\[ tfMrtf(t,d,D) = tf(t,d)-Mrtf(t,d,D) \]

### Rel TF-NRTF (Relative Term Frequency - Normalized Rest Term Frequency)

\[ \epsilon(t,d,D) = \frac{1}{\sum_{d' \not = d}^{D}f_{t,d'}} \]

\[ rel\_tfnrtf(t,d,D) = tf(t,d)^{\beta}\frac{tfnrtf(t,d,D)}{\log(1 + nrtf(t,d,D) + \epsilon(t,d,D))} \]
Epsilon (ε) is added to avoid zero-division. It is calculated to
resemble +1 smoothing in the rest population.

The beta (β) exponentiator allows us to control the influence of the
term frequency. By setting it to 0, we get the relative difference (log
scaled).

### Rel TF-MRTF (Relative Term Frequency - Maximum Rest Term Frequency)

\[ rel\_tfMrtf(t,d,D) = tf(t,d)^{\beta}\frac{tfMrtf(t,d,D)}{\log(1 + Mrtf(t,d,D) + \epsilon(t,d,D))} \]
