
library(dplyr)

wantedTax = read.table('data-raw/tax_report.txt',header=T, sep='|')


directory = 'data-raw/homologene.tsv'
homoloGeneTarget <<- directory
download.file(url = "ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data", destfile = 'data-raw/homologene.data')
homologene = read.table('data-raw/homologene.data',sep ='\t',quote='',stringsAsFactors = FALSE)
names(homologene) = c('HID','Taxonomy','Gene.ID','Gene.Symbol','Protein.GI','Protein.Accession')

homologeneData = homologene %>% filter(Taxonomy %in% wantedTax$taxid) %>% select(HID,Gene.Symbol,Taxonomy) %>% unique %>% arrange(Taxonomy)

use_data(homologeneData, overwrite= TRUE)
