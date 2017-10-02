
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

Basic homologene function requires a list of genes, and an `inTax` and an `outTax`. In this example, `inTax` is the taxon id of *mus musculus* while `outTax` is for humans.

``` r
homologene(c('Eno2','Mog'), inTax = 10090, outTax = 9606)
```

    ##   10090 9606
    ## 1  Eno2 ENO2
    ## 2   Mog  MOG

For mouse and humans two convenience functions exist that removes the need to provide taxonomic identifiers. Note that the column names are not the same as the `homologene` output.

``` r
mouse2human(c('Eno2','Mog'))
```

    ##   mouseGene humanGene
    ## 1      Eno2      ENO2
    ## 2       Mog       MOG

``` r
human2mouse(c('ENO2','MOG','GZMH'))
```

    ##   humanGene mouseGene
    ## 1      ENO2      Eno2
    ## 2       MOG       Mog
    ## 3      GZMH      Gzmd
    ## 4      GZMH      Gzme
    ## 5      GZMH      Gzmg
    ## 6      GZMH      Gzmf

Mishaps
=======

If a you can't find a gene you are looking for it may have synonyms. See [geneSynonym](https://github.com/oganm/geneSynonym.git) package to find them. If you have other problems open an issue or send a mail.
