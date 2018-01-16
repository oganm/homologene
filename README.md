
homologene
==========

[![Build Status](https://travis-ci.org/oganm/homologene.svg?branch=master)](https://travis-ci.org/oganm/homologene)[![codecov](https://codecov.io/gh/oganm/homologene/branch/master/graph/badge.svg)](https://codecov.io/gh/oganm/homologene)

An r package that works as a wrapper to homologene

Available species are

-   Homo sapiens
-   Mus musculus
-   Rattus norvegicus
-   Danio rerio
-   Caenorhabditis elegans
-   Drosophila melanogaster
-   Rhesus macaque

More species can be added on request

Installation
============

``` r
library(devtools)
install_github('oganm/homologene')
```

Usage
=====

Basic homologene function requires a list of gene symbols or NCBI ids, and an `inTax` and an `outTax`. In this example, `inTax` is the taxon id of *mus musculus* while `outTax` is for humans.

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

For mouse and humans two convenience functions exist that removes the need to provide taxonomic identifiers. Note that the column names are not the same as the `homologene` output.

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

Mishaps
=======

As of version version 1.1.68, the output now includes NCBI ids. Since it doesn't change any of the existing column names or their order, this shouldn't cause problems in most use cases. If this is an issue for you plase notify me.

If a you can't find a gene you are looking for it may have synonyms. See [geneSynonym](https://github.com/oganm/geneSynonym.git) package to find them. If you have other problems open an issue or send a mail.
