#' Update homologene database
#' 
#' Creates an updated version of the homologene database. This is done by downloading
#' the latest gene annotation information and tracing changes in gene symbols and 
#' identifiers over history. \code{\link{homologeneData2}} was created using 
#' this function over the original \code{\link{homologeneData}}. This function 
#' requires downloading large amounts of data from the NCBI ftp servers.
#'
#' @param destfile Optional. Path of the output file.
#' @param baseline The baseline homologene file to be used. By default uses the
#' \code{\link{homologeneData2} that is included in this package. The more ids 
#' to update, the more time is needed for the update which is why the default option
#' uses an already updated version of the original database.
#'
#' @return 
#' @export
#'
#' @examples
updateHomologene = function(destfile = NULL,
                            baseline = homologene::homologeneData2,
                            gene_history = NULL,
                            gene_info = NULL){

    if(is.null(gene_history)){
        message('acquiring gene history data')
        gene_history = getGeneHistory()
    }
    # identify discontinued ids
    discontinued_ids = baseline %>% 
        dplyr::filter(Gene.ID %in% gene_history$Discontinued_GeneID)
    
    unchanged_ids = baseline %>%  
        dplyr::filter(!Gene.ID %in% gene_history$Discontinued_GeneID)
    
    # we do not filter for taxonomy information as some genes use alternative
    # tax ids in non homologene sources
    # we do filter for earliest date found to run this a little faster
    
    message('Tracing discontinued IDs. This might take a while.')
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
    
    new_homo_frame %<>% mutate(
        Gene.ID = as.integer(Gene.ID)
    )
    
    
    if(is.null(gene_info)){
        message('Downloading gene symbol information')
        gene_info = getGeneInfo()
    }
    
    message('Updating gene symbols')
    matchToHomologene = match(new_homo_frame$Gene.ID,gene_info$GeneID)
    
    # tax information isn't really needed here. just added for testing purposes
    modern_frame = data.frame(modern_ids = new_homo_frame$Gene.ID,
                          modern_symbols = gene_info$Symbol[matchToHomologene],
                          modern_tax = gene_info$tax_id[matchToHomologene],stringsAsFactors = FALSE)
    
    new_homo_frame %<>% 
        mutate(Gene.Symbol = modern_frame$modern_symbols)
    
    if(!is.null(destfile)){
        write.table(new_homo_frame,destfile,
                    sep='\t', row.names=FALSE,quote = FALSE)
        
    }
    
    return(new_homo_frame)
}