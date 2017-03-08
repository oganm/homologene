library(magrittr)
library(dplyr)
library(data.table)
library(git2r)
devtools::use_data_raw()
# taxes = read.table('ftp://ftp.ncbi.nlm.nih.gov/mmdb/pdbeast/tax.table',sep = '')

# download taxonomy data if it's not already there
if(!file.exists('data-raw/taxdump/names.dmp')){
    download.file(url ='ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz', destfile = "data-raw/taxtump.tar.gz")
    dir.create('data-raw/taxdump', showWarnings = FALSE)
    untar('data-raw/taxtump.tar.gz',exdir = 'data-raw/taxdump/')
}



homologeneVersion = readLines('ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/RELEASE_NUMBER') %>% as.integer

# if the release is new, update
if(homologeneVersion!=readLines('data-raw/release')){
    taxData = fread('data-raw/taxdump/names.dmp',data.table=FALSE)
    taxData = taxData[c(1,3,5,7)]
    names(taxData) = c('tax_id','name_txt','unique_name','name_class')
    taxData %<>% filter(name_txt %in% c('Homo sapiens',
                                        'Mus musculus',
                                        'Rattus norvegicus',
                                        'Danio rerio',
                                        'Caenorhabditis elegans',
                                        'Drosophila melanogaster',
                                        'Rhesus macaque'))
    
    
    
    download.file(url = "ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data", destfile = 'data-raw/homologene.data')
    homologene = fread('data-raw/homologene.data',sep ='\t',quote='',stringsAsFactors = FALSE,data.table = FALSE)
    names(homologene) = c('HID','Taxonomy','Gene.ID','Gene.Symbol','Protein.GI','Protein.Accession')
    homologeneData = homologene %>% filter(Taxonomy %in% taxData$tax_id) %>% select(HID,Gene.Symbol,Taxonomy) %>% unique %>% arrange(Taxonomy)
    write.table(homologeneData,file = 'data-raw/homologeneData.tsv',sep='\t', row.names=FALSE)
    devtools::use_data(homologeneData, overwrite= TRUE)
    devtools::use_data(homologeneVersion, overwrite= TRUE)
    writeLines(releaseNo,con = 'data-raw/release')
    
    repo = repository('.')
    git2r::add(repo,'data/homologeneData.rda')
    git2r::add(repo,'data/homologeneVersion.rda')
    git2r::add(repo,'data-raw/homologeneData.tsv')
    git2r::add(repo,'man/homologeneData.Rd')
    git2r::add(repo,'data-raw/release')
    git2r::commit(repo,message = paste('Automatic update to version',homologeneVersion))
    
    pass = readLines('data-raw/auth')
    cred = git2r::cred_user_pass('OganM',pass)
    git2r::push(repo,credentials = cred)
}



