homologeneData2$Gene.ID[[1]]

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
        filter(Taxonomy == taxID) -> 
        speciesGenes
    
    speciesGenes$Gene.ID %>% 
        aliquot(15) %>%
        {.[]} %>% 
        lapply(function(x){
            diopt(x,inTax = 10090,outTax ='0',delay = 10)
        }) -> aliquotDiopt
    
    dioptOut = aliquotDiopt %>% do.call(rbind,.)
    readr::write_tsv(dioptOut,path = glue::glue('data-raw/diopt/{taxID}'))
    
})
