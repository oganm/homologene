devtools::install_github('oganm/geneSynonym')
library(geneSynonym)
library(dplyr)
library(magrittr)
session = rvest::html_session('https://www.flyrnai.org/cgi-bin/DRSC_orthologs.pl')
form = rvest::html_form(session)[[1]]
dioptSpecies = taxData %>% filter(tax_id %in% form$fields$input_species$options)

dioptSpecies$common_name = form$fields$input_species$options %>%
    {.[match(dioptSpecies$tax_id,.)]} %>%
    names %>% stringr::str_extract('(?<=\\().*?(?=\\))')

aliquot = function(vector, alisize){
    vector %>% 
        split(.,rep_len(1:(floor(length(.)/alisize)),length(.)))
}


dir.create('data-raw/diopt')
dioptSpecies$tax_id %>% lapply(function(taxID){
    homologeneData2 %>% 
        filter(Taxonomy == taxID) %$%
        Gene.ID -> 
        speciesGenes
    
    gene_infoDB = ogbox::teval(glue::glue('syno{taxID}'))
    
    speciesGenes %<>%  c(., names(gene_infoDB)) %>% unique
    
    speciesGenes %>% 
        aliquot(15) %>%
        {.[]} %>% 
        lapply(function(x){
            out = NULL
            times = 0
            while(is.null(out) && times<3){
                Sys.sleep(10)
                out = tryCatch(diopt(x,inTax = taxID,outTax ='0',delay = 10),
                               error = function(e){
                                   NULL
                               })
                times = times + 1
            }
            if(is.null(out)){
                cat(paste0(paste0(x,collapse = '\n'),'\n'),
                    file = paste0('data-raw/diopt/',taxID,'_failures'),append = TRUE)
            }
            return(out)
            
        }) -> aliquotDiopt
    
    aliquotDiopt = aliquotDiopt[!aliquotDiopt %>% sapply(is.null)]
    
    dioptOut = aliquotDiopt %>% do.call(rbind,.)
    readr::write_tsv(dioptOut,path = glue::glue('data-raw/diopt/{taxID}'))
    NULL
})

files = list.files('data-raw/diopt',full.names = TRUE)
failures = files[grepl('failures',files)]

failures[2] %>% sapply(function(x){
    tax = stringr::str_extract(x,'[0-9]*?(?=_)')
    failedIDs = readLines(x)
    failedIDs %>% sapply(function(y){
        tryCatch(diopt(y,inTax = tax,outTax ='0',delay = 10),
                 error = function(e){NULL})
    }) %>% do.call(rbind,.) -> failureFix
    
    readr::write_tsv(failureFix,path = glue::glue('data-raw/diopt/{tax}'),append = TRUE,
                     col_names = FALSE)
})

dioptFiles = files[!files %in% failures]

allDiopt = dioptFiles %>% lapply(function(x){
    readr::read_tsv(x)
})


