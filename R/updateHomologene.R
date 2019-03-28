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
#' \code{\link{homologeneData2}} that is included in this package. The more ids 
#' to update, the more time is needed for the update which is why the default option
#' uses an already updated version of the original database.
#' @param gene_history A gene history data frame, possibly returned by \code{\link{getGeneHistory}}
#' function. Use this if you want to have a static gene_history file to update up to a specific date.
#' An up to date gene_history object can be set to update to a specific date by trimming
#' rows that have recent dates. Note that the same is not possible for the gene_info 
#' If not provided, the latest file will be downloaded.
#' @param gene_info A gene info data frame that contatins ID-symbol matches,
#' possibly returned by \code{\link{getGeneInfo}}. Use this if you
#' want a static version. Should be in sync with the gene_history file. Note that there is 
#' no easy way to track changes in gene symbols back in time so if you want to update it up
#' to a specific date, make sure you don't lose that file.
#'
#' @return Homologene database in a data frame with updated gene IDs and symbols
#' @export
#'
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
    
    new_homo_frame %<>% dplyr::mutate(
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
        dplyr::mutate(Gene.Symbol = modern_frame$modern_symbols)
    # remove convergent gene ids with same HIDs
    new_homo_frame %<>% unique()
    if(!is.null(destfile)){
        utils::write.table(new_homo_frame,destfile,
                           sep='\t', row.names=FALSE,quote = FALSE)
        
    }
    
    return(new_homo_frame)
}