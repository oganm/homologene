devtools::install_github('oganm/geneSynonym')
library(readr)
library(magrittr)
library(dplyr)
library(geneSynonym)
library(purrr)
library(glue)
library(git2r)
library(ogbox)
library(data.table)

devtools::load_all()

download.file(url = "ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_history.gz", 
              destfile = 'data-raw/gene_history.gz')

gene_history = read_tsv('data-raw/gene_history.gz',
                        col_names = c('tax_id', 
                                      'GeneID',
                                      'Discontinued_GeneID',
                                      'Discontinued_Symbol',
                                      'Discontinue_Date'))


modern_IDs = homologene::taxData$tax_id %>% lapply(function(x){
    teval(paste0('syno',x))
}) %>% 
    # {validTax <<- homologene::taxData$tax_id[sapply(.,length)>300];.[sapply(.,length)>300]} %>%
    lapply(names) %>% do.call(c,.)


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
    filter(Discontinue_Date >= earlierst_date # & 
               # tax_id %in% homologene::taxData$tax_id
           )



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

download.file('ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz',
              'data-raw/gene_info.gz')

R.utils::gunzip('data-raw/gene_info.gz', overwrite = TRUE)

# I can't do a taxonomy matching here as taxonomies don't always
# match. some genes are listed under alternative names
callBack = function(x,pos){
    x[,c(1,2,3)]
}

geneInfo = read_tsv_chunked('data-raw/gene_info',
                            DataFrameCallback$new(callBack),
                            col_names = c('tax_id','GeneID','Symbol'),
                            chunk_size = 1000000,skip = 1)

# names(geneInfo) = c('tax_id','GeneID','Symbol')

matchToHomologene = match(homologeneData2$Gene.ID,as.integer(geneInfo$GeneID))

modern_frame = tibble(modern_ids = homologeneData2$Gene.ID,
                      modern_symbols = geneInfo$Symbol[matchToHomologene],
                      modern_tax = geneInfo$tax_id[matchToHomologene])

homologeneData2 %<>% 
    mutate(Gene.Symbol = modern_frame$modern_symbols)


write.table(homologeneData2,'data-raw/homologene2.tsv',sep='\t', row.names=FALSE,quote = FALSE)

devtools::use_data(homologeneData2,overwrite = TRUE)


glue('
#\' homologeneData2
#\'
#\' A modified copy of the homologene database. Homologene was updated at 2014 and many of its gene IDs and
#\' symbols are out of date. Here the IDs and symbols are replaced with their most current version
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
