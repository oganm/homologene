
# homologene

[![Build
Status](https://travis-ci.org/oganm/homologene.svg?branch=master)](https://travis-ci.org/oganm/homologene)
[![codecov](https://codecov.io/gh/oganm/homologene/branch/master/graph/badge.svg)](https://codecov.io/gh/oganm/homologene)
[![](https://www.r-pkg.org/badges/version/homologene?color=#32BD36)](https://cran.r-project.org/package=homologene)
[![](https://img.shields.io/badge/devel%20version-1.7.68.23.10.31-blue.svg)](https://github.com/oganm/homologene)

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
homologene, you can use the `updateHomologene` function.

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

    ## # A tibble: 5 × 3
    ##   tax_id  GeneID Symbol    
    ##    <int>   <int> <chr>     
    ## 1  39947 4324017 LOC4324017
    ## 2  39947 4332468 SPO11-3   
    ## 3  39947 4334150 LOC4334150
    ## 4  39947 4349033 LOC4349033
    ## 5  39947 9267698 LOC9267698

# Querying DIOPT

Instead of using just homologene, one can also make queries into the
[DIOPT database](https://www.flyrnai.org/cgi-bin/DRSC_orthologs.pl).
Diopt uses multiple databases to find gene homolog/orthologues. Note
that this function has a `delay` parameter that is set to 10 seconds by
default. This was done to obey the `robots.txt` of their website.

``` r
diopt(c('GZMH'),inTax = 9606, outTax = 10090) %>% 
    knitr::kable()
```

| Input Order | Search Term | Human GeneID | HGNCID | Human Symbol | Species 2 | Mouse GeneID | Mouse Species Gene ID | Mouse Symbol | Ensmbl ID (link HPA) | DIOPT Score | Weighted Score | Rank     | Best Score | Best Score Reverse | Prediction Derived From                                | Alignment & Scores | Feedback | Gene Details                             |
|------------:|:------------|-------------:|-------:|:-------------|:----------|-------------:|----------------------:|:-------------|:---------------------|------------:|---------------:|:---------|:-----------|:-------------------|:-------------------------------------------------------|:-------------------|:---------|:-----------------------------------------|
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        14944 |                109253 | Gzmg         | NA                   |           6 |           5.87 | high     | Yes        | Yes                | eggNOG, Homologene, Isobase, OrthoDB, Panther, Phylome | NA                 | Add      | G2F details (Gzmg) DRscDB Data: (Gzmg)   |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        14939 |                109267 | Gzmb         | NA                   |           6 |           5.85 | moderate | Yes        | No                 | eggNOG, OrthoDB, orthoMCL, Panther, Phylome, RoundUp   | NA                 | Add      | G2F details (Gzmb) DRscDB Data: (Gzmb)   |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |       245839 |               2675494 | Gzmn         | NA                   |           5 |           4.93 | moderate | No         | No                 | eggNOG, OMA, OrthoDB, Panther, Phylome                 | NA                 | Add      | G2F details (Gzmn) DRscDB Data: (Gzmn)   |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        14940 |                109256 | Gzmc         | NA                   |           5 |           4.93 | moderate | No         | No                 | eggNOG, OMA, OrthoDB, Panther, Phylome                 | NA                 | Add      | G2F details (Gzmc) DRscDB Data: (Gzmc)   |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        14941 |                109255 | Gzmd         | NA                   |           5 |           4.92 | moderate | No         | No                 | eggNOG, Homologene, OrthoDB, Panther, Phylome          | NA                 | Add      | G2F details (Gzmd) DRscDB Data: (Gzmd)   |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        14943 |                109254 | Gzmf         | NA                   |           5 |           4.92 | moderate | No         | No                 | eggNOG, Homologene, OrthoDB, Panther, Phylome          | NA                 | Add      | G2F details (Gzmf) DRscDB Data: (Gzmf)   |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        14942 |                109265 | Gzme         | NA                   |           5 |           4.92 | moderate | No         | No                 | eggNOG, Homologene, OrthoDB, Panther, Phylome          | NA                 | Add      | G2F details (Gzme) DRscDB Data: (Gzme)   |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        17231 |               1261780 | Mcpt8        | NA                   |           4 |           3.97 | moderate | No         | No                 | eggNOG, OrthoDB, Panther, TreeFam                      | NA                 | Add      | G2F details (Mcpt8) DRscDB Data: (Mcpt8) |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        13035 |                 88563 | Ctsg         | NA                   |           2 |           1.91 | low      | No         | No                 | eggNOG, OrthoDB                                        | NA                 | Add      | G2F details (Ctsg) DRscDB Data: (Ctsg)   |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        17228 |                 96941 | Cma1         | NA                   |           2 |           1.91 | low      | No         | No                 | eggNOG, OrthoDB                                        | NA                 | Add      | G2F details (Cma1) DRscDB Data: (Cma1)   |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        14938 |                109266 | Gzma         | NA                   |           1 |           1.03 | low      | No         | No                 | RoundUp                                                | NA                 | Add      | G2F details (Gzma) DRscDB Data: (Gzma)   |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        17232 |               1194491 | Mcpt9        | NA                   |           1 |           1.01 | low      | No         | Yes                | OrthoDB                                                | NA                 | Add      | G2F details (Mcpt9) DRscDB Data: (Mcpt9) |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        17225 |                 96938 | Mcpt2        | NA                   |           1 |           1.01 | low      | No         | Yes                | OrthoDB                                                | NA                 | Add      | G2F details (Mcpt2) DRscDB Data: (Mcpt2) |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |        17224 |                 96937 | Mcpt1        | NA                   |           1 |           1.01 | low      | No         | Yes                | OrthoDB                                                | NA                 | Add      | G2F details (Mcpt1) DRscDB Data: (Mcpt1) |
|           1 | GZMH        |         2999 |   4710 | GZMH         | Mouse     |       545055 |                 88426 | Cma2         | NA                   |           1 |           1.01 | low      | No         | Yes                | OrthoDB                                                | NA                 | Add      | G2F details (Cma2) DRscDB Data: (Cma2)   |

``` r
diopt(c('Eno2','Mog'),inTax = 10090, outTax =9606) %>%
    knitr::kable()
```

|               Input Order | Search Term | Mouse GeneID | MGIID | Mouse Symbol | Species 2 | Human GeneID | Human Species Gene ID | Human Symbol | Ensmbl ID (link HPA) | DIOPT Score | Weighted Score | Rank     | Best Score | Best Score Reverse | Prediction Derived From                                                                                                                           | Alignment & Scores | Feedback | Gene Details                           |
|--------------------------:|:------------|-------------:|------:|:-------------|:----------|-------------:|----------------------:|:-------------|:---------------------|------------:|---------------:|:---------|:-----------|:-------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------|:---------|:---------------------------------------|
|                         1 | Eno2        |        13807 | 95394 | Eno2         | Human     |         2026 |                  3353 | ENO2         | ENSG00000111674      |          14 |          14.29 | high     | Yes        | Yes                | Compara, eggNOG, HGNC, Hieranoid, Homologene, Inparanoid, OMA, OrthoFinder, OrthoInspector, orthoMCL, Panther, Phylome, RoundUp, TreeFam          | NA                 | Add      | G2F details (ENO2) DRscDB Data: (ENO2) |
| Human Protein Atlas (HPA) |             |              |       |              |           |              |                       |              |                      |             |                |          |            |                    |                                                                                                                                                   |                    |          |                                        |
|                         1 | Eno2        |        13807 | 95394 | Eno2         | Human     |         2023 |                  3350 | ENO1         | ENSG00000074800      |           5 |           4.84 | moderate | No         | No                 | eggNOG, OrthoDB, OrthoFinder, orthoMCL, RoundUp                                                                                                   | NA                 | Add      | G2F details (ENO1) DRscDB Data: (ENO1) |
| Human Protein Atlas (HPA) |             |              |       |              |           |              |                       |              |                      |             |                |          |            |                    |                                                                                                                                                   |                    |          |                                        |
|                         1 | Eno2        |        13807 | 95394 | Eno2         | Human     |         2027 |                  3354 | ENO3         | ENSG00000108515      |           4 |           3.83 | moderate | No         | No                 | eggNOG, OrthoFinder, orthoMCL, RoundUp                                                                                                            | NA                 | Add      | G2F details (ENO3) DRscDB Data: (ENO3) |
| Human Protein Atlas (HPA) |             |              |       |              |           |              |                       |              |                      |             |                |          |            |                    |                                                                                                                                                   |                    |          |                                        |
|                         1 | Eno2        |        13807 | 95394 | Eno2         | Human     |         2580 |                  4113 | GAK          | ENSG00000178950      |           1 |           1.01 | low      | No         | No                 | OrthoDB                                                                                                                                           | NA                 | Add      | G2F details (GAK) DRscDB Data: (GAK)   |
| Human Protein Atlas (HPA) |             |              |       |              |           |              |                       |              |                      |             |                |          |            |                    |                                                                                                                                                   |                    |          |                                        |
|                         1 | Eno2        |        13807 | 95394 | Eno2         | Human     |         2534 |                  4037 | FYN          | ENSG00000010810      |           1 |           1.01 | low      | No         | No                 | OrthoDB                                                                                                                                           | NA                 | Add      | G2F details (FYN) DRscDB Data: (FYN)   |
| Human Protein Atlas (HPA) |             |              |       |              |           |              |                       |              |                      |             |                |          |            |                    |                                                                                                                                                   |                    |          |                                        |
|                         1 | Eno2        |        13807 | 95394 | Eno2         | Human     |       387712 |                 31670 | ENO4         | ENSG00000188316      |           1 |           0.90 | low      | No         | No                 | eggNOG                                                                                                                                            | NA                 | Add      | G2F details (ENO4) DRscDB Data: (ENO4) |
| Human Protein Atlas (HPA) |             |              |       |              |           |              |                       |              |                      |             |                |          |            |                    |                                                                                                                                                   |                    |          |                                        |
|                         2 | Mog         |        17441 | 97435 | Mog          | Human     |         4340 |                  7197 | MOG          | ENSG00000204655      |          15 |          15.30 | high     | Yes        | Yes                | Compara, eggNOG, HGNC, Hieranoid, Homologene, Inparanoid, OMA, OrthoDB, OrthoFinder, OrthoInspector, orthoMCL, Panther, Phylome, RoundUp, TreeFam | NA                 | Add      | G2F details (MOG) DRscDB Data: (MOG)   |
| Human Protein Atlas (HPA) |             |              |       |              |           |              |                       |              |                      |             |                |          |            |                    |                                                                                                                                                   |                    |          |                                        |

# Mishaps

As of version version 1.1.68, the output now includes NCBI ids. Since it
doesn’t change any of the existing column names or their order, this
shouldn’t cause problems in most use cases.

If a you can’t find a gene you are looking for it may have synonyms. See
[geneSynonym](https://github.com/oganm/geneSynonym.git) package to find
them. If you have other problems open an issue or send a mail.
