homologeneData2$Gene.ID[[1]]

session = rvest::html_session('https://www.flyrnai.org/cgi-bin/DRSC_orthologs.pl')
form = rvest::html_form(session)[[1]]
dioptSpecies = taxData %>% filter(tax_id %in% form$fields$input_species$options)



homologeneData2 %>% filter(Taxonomy == 10090) -> speciesGenes


dioptOut = diopt(speciesGenes$Gene.ID[1:100],inTax = 10090, outTax = '0',delay = 1)

out = diopt(c('GZMH'),inTax = 9606, outTax = 10090)
