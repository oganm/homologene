devtools::install_github('oganm/geneSynonym')
library(readr)
library(magrittr)
library(dplyr)
library(geneSynonym)
library(purrr)
library(glue)
library(git2r)

devtools::load_all()

download.file(url = "ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_history.gz", 
              destfile = 'data-raw/gene_history.gz')

gene_history = read_tsv('data-raw/gene_history.gz',
                        col_names = c('tax_id', 
                                      'GeneID',
                                      'Discontinued_GeneID',
                                      'Discontinued_Symbol',
                                      'Discontinue_Date'))

modern_IDs  = list(syno10090,
                   syno10116,
                   syno6239,
                   syno7227,
                   syno7955,
                   syno9544,
                   syno9606) %>%
    lapply(names) %>%
    do.call(c,.)


if(!exists("homologeneData2")){
    homologeneData2 = homologeneData
}


discontinued_ids = homologeneData2 %>% 
    filter(Gene.ID %in% gene_history$Discontinued_GeneID)


unchanged_ids = homologeneData2 %>%  
    filter(!Gene.ID %in% gene_history$Discontinued_GeneID)


earlierst_date = gene_history %>%
    filter(Discontinued_GeneID %in% homologeneData2$Gene.ID) %$%
    Discontinue_Date %>% 
    min



relevant_gene_history = gene_history %>%
    filter(Discontinue_Date >= earlierst_date & 
               tax_id %in% homologene::taxData$tax_id)



traceID = function(id){
    event = relevant_gene_history %>% filter(Discontinued_GeneID == id)
    if(nrow(event)>1){
        # just in case. if the same ID is discontinued twice, there is a problem...
        return("multiple events")
    }
    while(TRUE){
        # see if the new ID is discontinued as well
        next_event = relevant_gene_history %>%
            filter(Discontinued_GeneID == event$GeneID)
        if(nrow(next_event)==0){
            # if not, previous ID is the right one
            return(event$GeneID)
        } else if(nrow(next_event)>1){
            # just in case, if the same ID is discontinued twice, there is a problem...
            return("multiple events")
        } else if(nrow(next_event) == 1){
            # if the new IDs is discontinued, continue the loop and check if it has a parent
            event = next_event
        }
    }
}


discontinued_ids$Gene.ID %>%
    sapply(traceID) ->
    new_ids


# create a frame with new ids
discontinued_fix = data.frame(HID = discontinued_ids$HID,
                              Gene.Symbol = discontinued_ids$Gene.Symbol,
                              Taxonomy = discontinued_ids$Taxonomy,
                              Gene.ID = new_ids,
                              stringsAsFactors = FALSE)

# remove symbols that are discontinued
discontinued_fix %<>% filter(Gene.ID != '-')

homologeneData2 = 
    rbind(discontinued_fix,unchanged_ids) %>% 
    arrange(HID)

# change the names with the new names
modern_symbols = list(syno10090,
                      syno10116,
                      syno6239,
                      syno7227,
                      syno7955,
                      syno9544,
                      syno9606) %>% 
    lapply(function(x){
        strsplit(x,split = "\\|") %>% map_chr(1)
    }) %>% do.call(c,.)


modern_frame = tibble(modern_IDs,
                      modern_symbols)


new_symbols = 
    modern_frame$modern_symbols[match(homologeneData2$Gene.ID, modern_frame$modern_IDs)]



homologeneData2 %<>% 
    mutate(Gene.Symbol = modern_frame$modern_symbols[match(Gene.ID,modern_frame$modern_IDs)])


write.table(homologeneData2,'data-raw/homologene2.tsv',sep='\t', row.names=FALSE,quote = FALSE)

devtools::use_data(homologeneData2,overwrite = TRUE)


glue('
#\' homologeneData2
#\'
#\' A modified copy of the homologene database where the gene IDs and symbols are updated when necesary. 
#\' Last update: {date()}
"homologeneData2"
') %>% 
    writeLines(con = 'R/homologeneData2.R')

devtools::document()


repo = repository('.')
add(repo,'R/homologeneData2.R')
add(repo,'data/homologeneData2.rda')
add(repo,'man/homologeneData2.Rd')
add(repo,'data-raw/homologene2.tsv')

version = getVersion()
version %<>% strsplit('\\.') %>% {.[[1]]}
dateTail = format(Sys.Date(),'%y.%m.%d') %>% 
    gsub(pattern = '\\.0','.',x=.) %>% strsplit('\\.') %>% {.[[1]]}

version[4:6] = dateTail

setVersion(paste(version,collapse = '.'))

add(repo,'DESCRIPTION')

git2r::commit(repo,message = 'homologeneData2 automatic update')


token = readLines('data-raw/auth')
Sys.setenv(GITHUB_PAT = token)
cred = git2r::cred_token()
git2r::push(repo,credentials = cred)
