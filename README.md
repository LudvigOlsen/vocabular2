
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

Note: By default, negative values are set to 0 for most of the metrics
(not TD-IDF and TF-IRF).

``` r
library(vocabular2)
library(tm)
library(tidyverse)
library(knitr)
```

``` r
data <- hamlet %>% 
  dplyr::group_by(character) %>% 
  dplyr::summarise(txt = paste0(lines, collapse = " "))

claudius <- data[1, "txt"][[1]]
gertrude <- data[2, "txt"][[1]]
hamlet <- data[3, "txt"][[1]]
horatio <- data[4, "txt"][[1]]
ophelia <- data[5, "txt"][[1]]
```

``` r
# Create a term-count tibble

count_terms <- function(t){
  docs <- Corpus(VectorSource(t))
  # do things like removing stopwords, lemmatization, etc.
  docs <- tm_map(docs, removeWords, stopwords("english"))
  docs <- tm_map(docs, removePunctuation, preserve_intra_word_dashes = TRUE)
  dtm <- TermDocumentMatrix(docs)
  m <- as.matrix(dtm)
  v <- sort(rowSums(m), decreasing=TRUE)
  d <- tibble::tibble(Word = names(v), Count=v)
  d
}

claudius_tc <- count_terms(claudius)
gertrude_tc <- count_terms(gertrude)
hamlet_tc <- count_terms(hamlet)
horatio_tc <- count_terms(horatio)
ophelia_tc <- count_terms(ophelia)
```

``` r
scores <- compare_vocabs(tc_dfs = list("claudius" = claudius_tc,
                                       "gertrude" = gertrude_tc,
                                       "hamlet" = hamlet_tc,
                                       "horatio" = horatio_tc,
                                       "ophelia" = ophelia_tc))
scores
#> # A tibble: 887 x 7
#>    Word     `In Docs` claudius     gertrude     hamlet     horatio    ophelia   
#>    <chr>        <dbl> <list>       <list>       <list>     <list>     <list>    
#>  1 ability          1 <tibble [1 … <tibble [1 … <tibble [… <tibble [… <tibble […
#>  2 aboard           1 <tibble [1 … <tibble [1 … <tibble [… <tibble [… <tibble […
#>  3 acquitt…         1 <tibble [1 … <tibble [1 … <tibble [… <tibble [… <tibble […
#>  4 act              1 <tibble [1 … <tibble [1 … <tibble [… <tibble [… <tibble […
#>  5 admirat…         1 <tibble [1 … <tibble [1 … <tibble [… <tibble [… <tibble […
#>  6 affecti…         1 <tibble [1 … <tibble [1 … <tibble [… <tibble [… <tibble […
#>  7 affecti…         1 <tibble [1 … <tibble [1 … <tibble [… <tibble [… <tibble […
#>  8 affrigh…         1 <tibble [1 … <tibble [1 … <tibble [… <tibble [… <tibble […
#>  9 aha              1 <tibble [1 … <tibble [1 … <tibble [… <tibble [… <tibble […
#> 10 air              2 <tibble [1 … <tibble [1 … <tibble [… <tibble [… <tibble […
#> # … with 877 more rows
```

``` r
get_doc_metrics(scores, "claudius") %>% 
  arrange(desc(REL_TF_NRTF)) %>% 
  head(10) %>% 
  kable()
```

| Doc      | Word     | In Docs | Count |        TF |       IRF |       RTF |      NRTF |      MRTF |   TF\_IDF |   TF\_IRF |   TF\_RTF |  TF\_NRTF |  TF\_MRTF | REL\_TF\_NRTF | REL\_TF\_MRTF | RANK\_ENS |
| :------- | :------- | ------: | ----: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | ------------: | ------------: | --------: |
| claudius | give     |       2 |     7 | 0.0132075 | 0.6931472 | 0.0022472 | 0.0005618 | 0.0022472 | 0.0067468 | 0.0091548 | 0.0109604 | 0.0126457 | 0.0109604 |     0.1314895 |     0.0490369 |     886.0 |
| claudius | gertrude |       1 |     5 | 0.0094340 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0086443 | 0.0130782 | 0.0094340 | 0.0094340 | 0.0094340 |     0.1255340 |     0.1255340 |     885.0 |
| claudius | laertes  |       2 |     9 | 0.0169811 | 0.6931472 | 0.0059880 | 0.0014970 | 0.0059880 | 0.0086744 | 0.0117704 | 0.0109931 | 0.0154841 | 0.0109931 |     0.1193114 |     0.0279667 |     887.0 |
| claudius | leave    |       1 |     3 | 0.0056604 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0051866 | 0.0078469 | 0.0056604 | 0.0056604 | 0.0056604 |     0.0451922 |     0.0451922 |     883.5 |
| claudius | polonius |       1 |     3 | 0.0056604 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0051866 | 0.0078469 | 0.0056604 | 0.0056604 | 0.0056604 |     0.0451922 |     0.0451922 |     883.5 |
| claudius | hamlet   |       3 |    15 | 0.0283019 | 0.2876821 | 0.0428010 | 0.0107002 | 0.0359281 | 0.0063154 | 0.0081419 | 0.0000000 | 0.0176016 | 0.0000000 |     0.0439106 |     0.0000000 |     673.0 |
| claudius | time     |       2 |     4 | 0.0075472 | 0.6931472 | 0.0022472 | 0.0005618 | 0.0022472 | 0.0038553 | 0.0052313 | 0.0053000 | 0.0069854 | 0.0053000 |     0.0415048 |     0.0135499 |     882.0 |
| claudius | father   |       4 |     6 | 0.0113208 | 0.0000000 | 0.0081824 | 0.0020456 | 0.0029940 | 0.0000000 | 0.0000000 | 0.0031384 | 0.0092752 | 0.0083267 |     0.0381682 |     0.0255019 |     697.0 |
| claudius | thine    |       2 |     4 | 0.0075472 | 0.6931472 | 0.0029940 | 0.0007485 | 0.0029940 | 0.0038553 | 0.0052313 | 0.0045532 | 0.0067987 | 0.0045532 |     0.0352249 |     0.0092965 |     881.0 |
| claudius | must     |       3 |     6 | 0.0113208 | 0.2876821 | 0.0091200 | 0.0022800 | 0.0068729 | 0.0025262 | 0.0032568 | 0.0022007 | 0.0090407 | 0.0044479 |     0.0342901 |     0.0066663 |     880.0 |

``` r
get_doc_metrics(scores, "gertrude") %>% 
  arrange(desc(REL_TF_NRTF)) %>% 
  head(10) %>% 
  kable()
```

| Doc      | Word    | In Docs | Count |        TF |       IRF |       RTF |      NRTF |      MRTF |   TF\_IDF |   TF\_IRF |   TF\_RTF |  TF\_NRTF |  TF\_MRTF | REL\_TF\_NRTF | REL\_TF\_MRTF | RANK\_ENS |
| :------- | :------ | ------: | ----: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | ------------: | ------------: | --------: |
| gertrude | drownd  |       1 |     3 | 0.0089820 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0082302 | 0.0124517 | 0.0089820 | 0.0089820 | 0.0089820 |     0.1296075 |     0.1296075 |     887.0 |
| gertrude | hamlet  |       3 |    12 | 0.0359281 | 0.2876821 | 0.0351747 | 0.0087937 | 0.0283019 | 0.0080171 | 0.0103359 | 0.0007534 | 0.0271345 | 0.0076263 |     0.1040184 |     0.0096092 |     875.0 |
| gertrude | thou    |       4 |     8 | 0.0239521 | 0.0000000 | 0.0219195 | 0.0054799 | 0.0117647 | 0.0000000 | 0.0000000 | 0.0020326 | 0.0184722 | 0.0121874 |     0.0727235 |     0.0237111 |     730.0 |
| gertrude | hast    |       2 |     3 | 0.0089820 | 0.6931472 | 0.0018868 | 0.0004717 | 0.0018868 | 0.0045883 | 0.0062259 | 0.0070952 | 0.0085103 | 0.0070952 |     0.0698872 |     0.0254277 |     885.5 |
| gertrude | ophelia |       2 |     3 | 0.0089820 | 0.6931472 | 0.0018868 | 0.0004717 | 0.0018868 | 0.0045883 | 0.0062259 | 0.0070952 | 0.0085103 | 0.0070952 |     0.0698872 |     0.0254277 |     885.5 |
| gertrude | thy     |       3 |     6 | 0.0179641 | 0.2876821 | 0.0135679 | 0.0033920 | 0.0113208 | 0.0040086 | 0.0051679 | 0.0043961 | 0.0145721 | 0.0066433 |     0.0653355 |     0.0100518 |     883.0 |
| gertrude | this    |       2 |     3 | 0.0089820 | 0.6931472 | 0.0022472 | 0.0005618 | 0.0022472 | 0.0045883 | 0.0062259 | 0.0067348 | 0.0084202 | 0.0067348 |     0.0638903 |     0.0211089 |     884.0 |
| gertrude | alack   |       1 |     2 | 0.0059880 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0054868 | 0.0083012 | 0.0059880 | 0.0059880 | 0.0059880 |     0.0576034 |     0.0576034 |     881.0 |
| gertrude | forgot  |       1 |     2 | 0.0059880 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0054868 | 0.0083012 | 0.0059880 | 0.0059880 | 0.0059880 |     0.0576034 |     0.0576034 |     881.0 |
| gertrude | noise   |       1 |     2 | 0.0059880 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0054868 | 0.0083012 | 0.0059880 | 0.0059880 | 0.0059880 |     0.0576034 |     0.0576034 |     881.0 |

``` r
get_doc_metrics(scores, "hamlet") %>% 
  arrange(desc(REL_TF_NRTF)) %>% 
  head(10) %>% 
  kable()
```

| Doc    | Word     | In Docs | Count |        TF |       IRF |       RTF |      NRTF |      MRTF |   TF\_IDF |   TF\_IRF |   TF\_RTF |  TF\_NRTF |  TF\_MRTF | REL\_TF\_NRTF | REL\_TF\_MRTF | RANK\_ENS |
| :----- | :------- | ------: | ----: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | --------: | ------------: | ------------: | --------: |
| hamlet | hold     |       1 |     4 | 0.0117647 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0107799 | 0.0163093 | 0.0117647 | 0.0117647 | 0.0117647 |     0.2215225 |     0.2215225 |       887 |
| hamlet | horatio  |       2 |     5 | 0.0147059 | 0.6931472 | 0.0018868 | 0.0004717 | 0.0018868 | 0.0075121 | 0.0101933 | 0.0128191 | 0.0142342 | 0.0128191 |     0.1909742 |     0.0751466 |       886 |
| hamlet | horrible |       1 |     3 | 0.0088235 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0080849 | 0.0122320 | 0.0088235 | 0.0088235 | 0.0088235 |     0.1246064 |     0.1246064 |       885 |
| hamlet | boy      |       1 |     2 | 0.0058824 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0053899 | 0.0081547 | 0.0058824 | 0.0058824 | 0.0058824 |     0.0553806 |     0.0553806 |       882 |
| hamlet | earth    |       1 |     2 | 0.0058824 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0053899 | 0.0081547 | 0.0058824 | 0.0058824 | 0.0058824 |     0.0553806 |     0.0553806 |       882 |
| hamlet | fellow   |       1 |     2 | 0.0058824 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0053899 | 0.0081547 | 0.0058824 | 0.0058824 | 0.0058824 |     0.0553806 |     0.0553806 |       882 |
| hamlet | hell     |       1 |     2 | 0.0058824 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0053899 | 0.0081547 | 0.0058824 | 0.0058824 | 0.0058824 |     0.0553806 |     0.0553806 |       882 |
| hamlet | thrift   |       1 |     2 | 0.0058824 | 1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0053899 | 0.0081547 | 0.0058824 | 0.0058824 | 0.0058824 |     0.0553806 |     0.0553806 |       882 |
| hamlet | make     |       2 |     3 | 0.0088235 | 0.6931472 | 0.0034364 | 0.0008591 | 0.0034364 | 0.0045073 | 0.0061160 | 0.0053871 | 0.0079644 | 0.0053871 |     0.0473864 |     0.0117273 |       878 |
| hamlet | sword    |       2 |     3 | 0.0088235 | 0.6931472 | 0.0034364 | 0.0008591 | 0.0034364 | 0.0045073 | 0.0061160 | 0.0053871 | 0.0079644 | 0.0053871 |     0.0473864 |     0.0117273 |       878 |

``` r
get_doc_metrics(scores, "horatio") %>% 
  arrange(desc(REL_TF_NRTF)) %>% 
  head(10) %>% 
  kable()
```

| Doc     | Word     | In Docs | Count |        TF |         IRF |       RTF |      NRTF |      MRTF |     TF\_IDF |     TF\_IRF |   TF\_RTF |  TF\_NRTF |  TF\_MRTF | REL\_TF\_NRTF | REL\_TF\_MRTF | RANK\_ENS |
| :------ | :------- | ------: | ----: | --------: | ----------: | --------: | --------: | --------: | ----------: | ----------: | --------: | --------: | --------: | ------------: | ------------: | --------: |
| horatio | lord     |       5 |    37 | 0.0831461 | \-0.2231436 | 0.1203392 | 0.0300848 | 0.1065292 | \-0.0151593 | \-0.0185535 | 0.0000000 | 0.0530613 | 0.0000000 |     0.1456518 |     0.0000000 |       629 |
| horatio | might    |       1 |     4 | 0.0089888 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0082363 |   0.0124611 | 0.0089888 | 0.0089888 | 0.0089888 |     0.1208332 |     0.1208332 |       887 |
| horatio | heard    |       2 |     3 | 0.0067416 |   0.6931472 | 0.0018868 | 0.0004717 | 0.0018868 |   0.0034438 |   0.0046729 | 0.0048548 | 0.0062699 | 0.0048548 |     0.0370797 |     0.0128226 |       886 |
| horatio | aught    |       1 |     2 | 0.0044944 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0041182 |   0.0062305 | 0.0044944 | 0.0044944 | 0.0044944 |     0.0302083 |     0.0302083 |       879 |
| horatio | bernardo |       1 |     2 | 0.0044944 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0041182 |   0.0062305 | 0.0044944 | 0.0044944 | 0.0044944 |     0.0302083 |     0.0302083 |       879 |
| horatio | consider |       1 |     2 | 0.0044944 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0041182 |   0.0062305 | 0.0044944 | 0.0044944 | 0.0044944 |     0.0302083 |     0.0302083 |       879 |
| horatio | custom   |       1 |     2 | 0.0044944 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0041182 |   0.0062305 | 0.0044944 | 0.0044944 | 0.0044944 |     0.0302083 |     0.0302083 |       879 |
| horatio | een      |       1 |     2 | 0.0044944 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0041182 |   0.0062305 | 0.0044944 | 0.0044944 | 0.0044944 |     0.0302083 |     0.0302083 |       879 |
| horatio | issue    |       1 |     2 | 0.0044944 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0041182 |   0.0062305 | 0.0044944 | 0.0044944 | 0.0044944 |     0.0302083 |     0.0302083 |       879 |
| horatio | most     |       1 |     2 | 0.0044944 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0041182 |   0.0062305 | 0.0044944 | 0.0044944 | 0.0044944 |     0.0302083 |     0.0302083 |       879 |

``` r
get_doc_metrics(scores, "ophelia") %>% 
  arrange(desc(REL_TF_NRTF)) %>% 
  head(10) %>% 
  kable()
```

| Doc     | Word   | In Docs | Count |        TF |         IRF |       RTF |      NRTF |      MRTF |     TF\_IDF |     TF\_IRF |   TF\_RTF |  TF\_NRTF |  TF\_MRTF | REL\_TF\_NRTF | REL\_TF\_MRTF | RANK\_ENS |
| :------ | :----- | ------: | ----: | --------: | ----------: | --------: | --------: | --------: | ----------: | ----------: | --------: | --------: | --------: | ------------: | ------------: | --------: |
| ophelia | lord   |       5 |    31 | 0.1065292 | \-0.2231436 | 0.0969561 | 0.0242390 | 0.0831461 | \-0.0194226 | \-0.0237713 | 0.0095731 | 0.0822902 | 0.0233831 |     0.3571989 |     0.0309710 |       742 |
| ophelia | mark   |       1 |     3 | 0.0103093 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0094463 |   0.0142917 | 0.0103093 | 0.0103093 | 0.0103093 |     0.1753109 |     0.1753109 |       887 |
| ophelia | know   |       4 |     6 | 0.0206186 |   0.0000000 | 0.0146223 | 0.0036556 | 0.0094340 |   0.0000000 |   0.0000000 | 0.0059962 | 0.0169630 | 0.0111846 |     0.0822374 |     0.0230834 |       762 |
| ophelia | better |       1 |     2 | 0.0068729 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0062975 |   0.0095278 | 0.0068729 | 0.0068729 | 0.0068729 |     0.0779159 |     0.0779159 |       883 |
| ophelia | keen   |       1 |     2 | 0.0068729 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0062975 |   0.0095278 | 0.0068729 | 0.0068729 | 0.0068729 |     0.0779159 |     0.0779159 |       883 |
| ophelia | keep   |       1 |     2 | 0.0068729 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0062975 |   0.0095278 | 0.0068729 | 0.0068729 | 0.0068729 |     0.0779159 |     0.0779159 |       883 |
| ophelia | many   |       1 |     2 | 0.0068729 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0062975 |   0.0095278 | 0.0068729 | 0.0068729 | 0.0068729 |     0.0779159 |     0.0779159 |       883 |
| ophelia | naught |       1 |     2 | 0.0068729 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0062975 |   0.0095278 | 0.0068729 | 0.0068729 | 0.0068729 |     0.0779159 |     0.0779159 |       883 |
| ophelia | show   |       1 |     2 | 0.0068729 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0062975 |   0.0095278 | 0.0068729 | 0.0068729 | 0.0068729 |     0.0779159 |     0.0779159 |       883 |
| ophelia | sings  |       1 |     2 | 0.0068729 |   1.3862944 | 0.0000000 | 0.0000000 | 0.0000000 |   0.0062975 |   0.0095278 | 0.0068729 | 0.0068729 | 0.0068729 |     0.0779159 |     0.0779159 |       883 |

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
