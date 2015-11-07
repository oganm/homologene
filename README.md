# homologene
An r package that works as a wrapper to homologene

Available species are
* Homo sapiens
* Mus musculus
* Rattus norvegicus
* Danio rerio
* Escherichia coli
* Caenorhabditis elegans
* Drosophila melanogaster
* Rhesus macaque

More species can be added on request

Installation
============
```r
library(devtools)
install_github('oganm/homologene')
```

Usage
===========
```r
homologene(c('Eno2','Mog'), inTax = 10090, outTax = 9606)

mouse2human(c('Eno2','Mog'))

human2mouse(c('ENO2',MOG'))
```
