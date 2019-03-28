
# homologene

[![Build
Status](https://travis-ci.org/oganm/homologene.svg?branch=master)](https://travis-ci.org/oganm/homologene)
[![codecov](https://codecov.io/gh/oganm/homologene/branch/master/graph/badge.svg)](https://codecov.io/gh/oganm/homologene)
[![](https://www.r-pkg.org/badges/version/homologene?color=#32BD36)](https://cran.r-project.org/package=homologene)
[![](https://img.shields.io/badge/devel%20version-1.4.68.19.3.26-blue.svg)](https://github.com/oganm/homologene)

An r package that works as a wrapper to homologene

Available species are

``` r
homologene::taxData
```

    ##    tax_id                      name_txt
    ## 1   10090                  Mus musculus
    ## 2   10116             Rattus norvegicus
    ## 3   28985          Kluyveromyces lactis
    ## 4  318829            Magnaporthe oryzae
    ## 5   33169         Eremothecium gossypii
    ## 6    3702          Arabidopsis thaliana
    ## 7    4530                  Oryza sativa
    ## 8    4896     Schizosaccharomyces pombe
    ## 9    4932      Saccharomyces cerevisiae
    ## 10   5141             Neurospora crassa
    ## 11   6239        Caenorhabditis elegans
    ## 12   7165             Anopheles gambiae
    ## 13   7227       Drosophila melanogaster
    ## 14   7955                   Danio rerio
    ## 15   8364 Xenopus (Silurana) tropicalis
    ## 16   9031                 Gallus gallus
    ## 17   9544                Macaca mulatta
    ## 18   9598               Pan troglodytes
    ## 19   9606                  Homo sapiens
    ## 20   9615        Canis lupus familiaris
    ## 21   9913                    Bos taurus

# Installation

``` r
install.packages('homologene')
```

or

``` r
devtools::install_github('oganm/homologene')
```

# Usage

Basic homologene function requires a list of gene symbols or NCBI ids,
and an `inTax` and an `outTax`. In this example, `inTax` is the taxon id
of *mus musculus* while `outTax` is for humans.

``` r
homologene(c('Eno2','Mog'), inTax = 10090, outTax = 9606)
```

    ##   10090 9606 10090_ID 9606_ID
    ## 1  Eno2 ENO2    13807    2026
    ## 2   Mog  MOG    17441    4340

``` r
homologene(c('Eno2','17441'), inTax = 10090, outTax = 9606)
```

    ##   10090 9606 10090_ID 9606_ID
    ## 1  Eno2 ENO2    13807    2026
    ## 2   Mog  MOG    17441    4340

For mouse and humans two convenience functions exist that removes the
need to provide taxonomic identifiers. Note that the column names are
not the same as the `homologene` output.

``` r
mouse2human(c('Eno2','Mog'))
```

    ##   mouseGene humanGene mouseID humanID
    ## 1      Eno2      ENO2   13807    2026
    ## 2       Mog       MOG   17441    4340

``` r
human2mouse(c('ENO2','MOG','GZMH'))
```

    ##   humanGene mouseGene humanID mouseID
    ## 1      ENO2      Eno2    2026   13807
    ## 2       MOG       Mog    4340   17441
    ## 3      GZMH      Gzmd    2999   14941
    ## 4      GZMH      Gzme    2999   14942
    ## 5      GZMH      Gzmg    2999   14944
    ## 6      GZMH      Gzmf    2999   14943

# homologeneData2

Original homologene database has not been updated since 2014. This
package also includes an updated version of the homologene database that
replaces gene symbols and identifiers with the their latest version. For
the procedure followed for updating, see [this blog
post](https://oganm.com/homologene-update/) and/or see the [processing
code](R/updateHomologene.R).

Using the updated version can help you match genes that cannot matched
due to out of date annotations.

``` r
mouse2human(c('Mesd',
              'Trp53rka',
              'Cstdc4',
              'Ifit3b'))
```

    ## [1] mouseGene humanGene mouseID   humanID  
    ## <0 rows> (or 0-length row.names)

``` r
mouse2human(c('Mesd',
              'Trp53rka',
              'Cstdc4',
              'Ifit3b'),
            db = homologeneData2)
```

    ##   mouseGene humanGene mouseID humanID
    ## 1      Mesd      MESD   67943   23184
    ## 2  Trp53rka    TP53RK  381406  112858
    ## 3    Cstdc4      CSTA  433016    1475
    ## 4    Ifit3b     IFIT3  667370    3437

The `homologeneData2` object that comes with the GitHub version of this
package is updated weekly but if you are using the CRAN version and want
the latest annotations, or if you want to keep a frozen version
homologene, you can use the `updateHomologene`
function.

``` r
homologeneDataVeryNew = updateHomologene() # update the homologene database with the latest identifiers

mouse2human(c('Mesd',
              'Trp53rka',
              'Cstdc4',
              'Ifit3b'),
            db = homologeneDataVeryNew)
```

# Gene ID syncronization

The package also includes functions that were used to create the
`homologeneData2`, for updating outdated gene symbols and identifiers.

``` r
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following object is masked from 'package:testthat':
    ## 
    ##     matches

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
gene_history = getGeneHistory()
oldIds = c(4340964, 4349034, 4332470, 4334151, 4323831)
newIds = updateIDs(oldIds,gene_history)
print(newIds)
```

    ## [1] "9267698" "4349033" "4332468" "4334150" "4324017"

``` r
# get the latest gene symbols for the ids

gene_info = getGeneInfo()

gene_info %>%
    dplyr::filter(GeneID %in% as.integer(newIds)) # faster to match integers
```

    ## # A tibble: 5 x 3
    ##   tax_id  GeneID Symbol    
    ##    <int>   <int> <chr>     
    ## 1  39947 4324017 LOC4324017
    ## 2  39947 4332468 LOC4332468
    ## 3  39947 4334150 LOC4334150
    ## 4  39947 4349033 LOC4349033
    ## 5  39947 9267698 LOC9267698

# Mishaps

As of version version 1.1.68, the output now includes NCBI ids. Since it
doesn’t change any of the existing column names or their order, this
shouldn’t cause problems in most use cases.

If a you can’t find a gene you are looking for it may have synonyms. See
[geneSynonym](https://github.com/oganm/geneSynonym.git) package to find
them. If you have other problems open an issue or send a mail.
