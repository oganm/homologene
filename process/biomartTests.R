library(biomaRt)
library(dplyr)
library(magrittr)
devtools::load_all()

martdb = useMart('ENSEMBL_MART_ENSEMBL')
biomaRt::listDatasets(martdb) %>% dplyr::filter(grepl(dataset,))
allDBs = biomaRt::listDatasets(martdb) 

inDatabase = taxData$name_txt %>% gsub(' ','_',.) %>% lapply(function(x){
    allDBs %>% dplyr::filter(grepl(dataset,x,ignore.case = TRUE))
})



biomaRt::listDatasets(hede) %>% dplyr::filter(grepl('gene_ensembl',dataset))


biomartDBs = data.frame(
    tax_id  = taxData$tax_id,
    name_txt = taxData$name_txt,
    inDBs = c('mmusculus_gene_ensembl',
              'rnorvegicus_gene_ensembl',
              'celegans_gene_ensembl',
              'dmelanogaster_gene_ensembl',
              'drerio_gene_ensembl',
              'mmulatta_gene_ensembl',
              'hsapiens_gene_ensembl'),
    outDBs = c('mmusculus_homolog_ensembl_gene',
               'rnorvegicus_homolog_ensembl_gene',
               'celegans_homolog_ensembl_gene',
               'dmelanogaster_homolog_ensembl_gene',
               'drerio_homolog_ensembl_gene',
               'mmulatta_homolog_ensembl_gene',
               'hsapiens_homolog_ensembl_gene')
)

biomartName = data.frame(
    tax_id  = taxData$tax_id,
    name_txt = taxData$name_txt,
    biomartName = c('mmusculus',
                    'rnorvegicus',
                    'celegans',
                    'dmelanogaster',
                    'drerio',
                    'mmulatta',
                    'hsapiens'),stringsAsFactors = FALSE
)



# look for the gene symbol column for each species.
validSymbolFilters = lapply(seq_len(nrow(biomartName)), function(i){
    name = biomartName[i,'biomartName']
    targetGenes = homologeneData %>% filter(Taxonomy %in% biomartName[i,'tax_id']) %$% Gene.Symbol
    mart = biomaRt::useMart('ENSEMBL_MART_ENSEMBL',paste0(name,'_gene_ensembl'))
    
    filters = listFilters(mart)
    sapply(seq_len(nrow(filters)), function(t){
        print(paste(name, filters[t,'name']))
        tryCatch({
            getBM(c('ensembl_gene_id'),filters = filters[t,'name'],value = targetGenes[sample(length(targetGenes),20)], mart = mart) %>% nrow
        },
        error = function(e){
            return(0)
        })
    }) -> filterRowCounts
    names(filterRowCounts) = filters[,'name']
    return(filterRowCounts)
})

names(validSymbolFilters) = biomartName$biomartName
validSymbolFilters %<>% purrr::map(function(x){x[x>0]})


validIDFilters = lapply(seq_len(nrow(biomartName)), function(i){
    name = biomartName[i,'biomartName']
    targetIDs = homologeneData %>% filter(Taxonomy %in% biomartName[i,'tax_id']) %$% Gene.ID
    mart = biomaRt::useMart('ENSEMBL_MART_ENSEMBL',paste0(name,'_gene_ensembl'))
    
    filters = listFilters(mart)
    sapply(seq_len(nrow(filters)), function(t){
        print(paste(name, filters[t,'name']))
        tryCatch({
            getBM(c('ensembl_gene_id'),filters = filters[t,'name'],value = targetIDs[sample(length(targetIDs),20)], mart = mart) %>% nrow
        },
        error = function(e){
            return(0)
        })
    }) -> filterRowCounts
    names(filterRowCounts) = filters[,'name']
    return(filterRowCounts)
})

names(validIDFilters) = biomartName$biomartName
validIDFilters %<>% purrr::map(function(x){x[x>0]})


genes = c('Eno2','Mog')
inTax = 10090 
outTax = 9606


ensemblHomologs = function(genes, inTax, outTax,confidenceTreshold = 0){
    
    inName = biomartName$biomartName[biomartName$tax_id == inTax]
    outName = biomartName$biomartName[biomartName$tax_id == outTax]
    
    mart = biomaRt::useMart('ENSEMBL_MART_ENSEMBL',paste0(inName,'_gene_ensembl'))
    
    entrezIDs = getBM(c('ensembl_gene_id','hgnc_symbol','mgi_symbol'),filters = 'mgi_symbol',value = genes, mart = mart)
    
    
    getBM(c(
            paste0(outName,'_homolog_ensembl_gene')),
          filters = 'mgi_symbol',
          values =genes,
          mart = mart) ->out
    )
    
}

mouseMart = useMart('ENSEMBL_MART_ENSEMBL','mmusculus_gene_ensembl')
elegansMart = useMart('ENSEMBL_MART_ENSEMBL','celegans_gene_ensembl')

humanMart = useMart('ENSEMBL_MART_ENSEMBL','hsapiens_gene_ensembl')
ratMart = useMart('ENSEMBL_MART_ENSEMBL','rnorvegicus_gene_ensembl')

getBM()


outDBs = 