
prepHomologene = function(){
    library(dplyr)
    
    wantedTax = read.table('data/tax_report.txt',header=T, sep='|')
    
    
    directory = 'data/homologene.tsv'
    homoloGeneTarget <<- directory
    download.file(url = "ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data", destfile = 'homologene.data')
    homologene = read.table('homologene.data',sep ='\t',quote='',stringsAsFactors = FALSE)
    names(homologene) = c('HID','Taxonomy','Gene.ID','Gene.Symbol','Protein.GI','Protein.Accession')
    
    homologeneData = homologene %>% filter(Taxonomy %in% wantedTax$taxid) %>% select(HID,Gene.Symbol,Taxonomy) %>% unique %>% arrange(Taxonomy)
    
    save(homologeneData,file = 'data/homologeneData.rda')
    
    file.remove('homologene.data')
}