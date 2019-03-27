library(magrittr)
library(dplyr)
library(data.table)
library(git2r)
library(ogbox)
library(stringr)
devtools::load_all()
usethis::use_data_raw()

homologeneVersion = readLines('ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/RELEASE_NUMBER') %>% as.integer

# if the release is new, update
if(homologeneVersion==readLines('data-raw/release')){
    
    homologeneData = getHomologene()
    
    taxData = read.table('ftp://ftp.ncbi.nih.gov/pub/HomoloGene/build68/build_inputs/taxid_taxname',
                         sep = '\t',
                         stringsAsFactors = FALSE)
    colnames(taxData) = c('tax_id','name_txt')

    speciesToAdd = homologeneData$Taxonomy %>% unique
    
    taxData %<>% filter(tax_id %in% speciesToAdd)
    
    stopifnot(all(speciesToAdd %in% taxData$tax_id))
    
    write.table(taxData,'data-raw/taxData.tsv',sep='\t', row.names=FALSE,quote = FALSE)
    usethis::use_data(taxData,overwrite = TRUE)
    
    write.table(homologeneData,file = 'data-raw/homologeneData.tsv',sep='\t', row.names=FALSE)
    usethis::use_data(homologeneData, overwrite= TRUE)
    usethis::use_data(homologeneVersion, overwrite= TRUE)
    writeLines(as.character(homologeneVersion),con = 'data-raw/release')
    
    repo = repository('.')
    
    version = getVersion()
    version %<>% strsplit('\\.') %>% {.[[1]]}
    version[3] = homologeneVersion
    setVersion(paste(version,collapse = '.'))
    
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
    
    token = readLines('data-raw/auth')
    Sys.setenv(GITHUB_PAT = token)
    cred = git2r::cred_token()
    git2r::push(repo,credentials = cred)
}



