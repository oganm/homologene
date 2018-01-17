library(magrittr)
library(dplyr)
library(data.table)
library(git2r)
library(ogbox)
library(stringr)
devtools::use_data_raw()

homologeneVersion = readLines('ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/RELEASE_NUMBER') %>% as.integer

# if the release is new, update
if(homologeneVersion!=readLines('data-raw/release')){
    taxData = read.table('ftp://ftp.ncbi.nih.gov/pub/HomoloGene/build68/build_inputs/taxid_taxname',
                         sep = '\t',
                         stringsAsFactors = FALSE)
    colnames(taxData) = c('tax_id','name_txt')

    speciesToAdd = c('Homo sapiens',
                     'Mus musculus',
                     'Rattus norvegicus',
                     'Danio rerio',
                     'Caenorhabditis elegans',
                     'Drosophila melanogaster',
                     'Macaca mulatta')
    
    taxData %<>% filter(name_txt %in% speciesToAdd)
    
    stopifnot(all(speciesToAdd %in% taxData$name_txt))
    
    taxData %<>% select('tax_id','name_txt')
    
    write.table(taxData,'data-raw/taxData.tsv',,sep='\t', row.names=FALSE,quote = FALSE)
    devtools::use_data(taxData,overwrite = TRUE)
    
    
    download.file(url = "ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data", destfile = 'data-raw/homologene.data')
    homologene = fread('data-raw/homologene.data',sep ='\t',quote='',stringsAsFactors = FALSE,data.table = FALSE)
    names(homologene) = c('HID','Taxonomy','Gene.ID','Gene.Symbol','Protein.GI','Protein.Accession')
    homologeneData = homologene %>% filter(Taxonomy %in% taxData$tax_id) %>% select(HID,Gene.Symbol,Taxonomy) %>% unique %>% arrange(Taxonomy)
    write.table(homologeneData,file = 'data-raw/homologeneData.tsv',sep='\t', row.names=FALSE)
    devtools::use_data(homologeneData, overwrite= TRUE)
    devtools::use_data(homologeneVersion, overwrite= TRUE)
    writeLines(as.character(homologeneVersion),con = 'data-raw/release')
    
    repo = repository('.')
    
    version = getVersion()
    version %<>% strsplit('\\.') %>% {.[[1]]}
    setVersion(paste(version[1],version[2],homologeneVersion,sep='.'))
    
    description = readLines('DESCRIPTION')
    description[grepl('build[0-9]',description)] = str_replace(description[grepl('build[0-9]',description)],
                                                               'build[0-9]*?(?=/)',
                                                               paste0('build',homologeneVersion))
    writeLines(text = description,con = 'DESCRIPTION')
    
    git2r::add(repo,path ='DESCRIPTION')
    
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



