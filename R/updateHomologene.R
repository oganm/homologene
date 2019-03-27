updateHomologene = function(destfile,
                            baseline = homologene::homologeneData2){
    history_file = tempfile()
    
    message('acquiring gene history data')
    gene_history = getGeneHistory()
    
    # identify discontinued ids
    discontinued_ids = baseline %>% 
        dplyr::filter(Gene.ID %in% gene_history$Discontinued_GeneID)
    
    unchanged_ids = baseline %>%  
        dplyr::filter(!Gene.ID %in% gene_history$Discontinued_GeneID)
    
    # we do not filter for taxonomy information as some genes use alternative
    # tax ids in non homologene sources
    # we do filter for earliest date found to run this a little faster
    
    message('Tracing discontinued IDs')
    discontinued_ids$Gene.ID %>% updateIDs(gene_history) ->
        new_ids
    
    # create a frame with new ids
    discontinued_fix = data.frame(HID = discontinued_ids$HID,
                                  Gene.Symbol = discontinued_ids$Gene.Symbol,
                                  Taxonomy = discontinued_ids$Taxonomy,
                                  Gene.ID = new_ids,
                                  stringsAsFactors = FALSE)
    
    discontinued_fix %<>% dplyr::filter(Gene.ID != '-')
    
    new_homo_frame = 
        rbind(discontinued_fix,unchanged_ids) %>% 
        dplyr::arrange(HID)
    
    
    
    message('Downloading gene symbol information')
    
    tmp = tempfile()
    
    download.file('ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz',
                  tmp)
    callBack = function(x,pos){
        x[,c(1,2,3)]
    }
    
    geneInfo = readr::read_tsv_chunked('data-raw/gene_info',
                                readr::DataFrameCallback$new(callBack),
                                col_names = c('tax_id','GeneID','Symbol'),
                                chunk_size = 1000000,skip = 1)
    
    matchToHomologene = match(new_homo_frame$Gene.ID,as.integer(geneInfo$GeneID))
    
}