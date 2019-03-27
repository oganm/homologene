#' Download gene history file
#'
#' Downloads and reads the gene history file from NCBI website. This file is needed for
#' other functions
#'
#' @param destfile Path of the output file. If NULL a temp file will be used
#' @param justRead If TRUE and destfile exists, it reads the file instead of 
#' downloading the latest one from NCBI
#'
#' @return A data frame with latest gene history information
#' @export
#'
getGeneHistory = function(destfile = NULL, justRead = FALSE){
    if(is.null(destfile)){
        destfile = tempfile()
    }
    
    if(!(!is.null(destfile) && file.exists(destfile) && justRead)){
        download.file(url = "ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_history.gz", 
                      destfile = paste0(destfile,'.gz'))
        
        
        R.utils::gunzip(paste0(destfile,'.gz'), overwrite = TRUE)
    }
   
    gene_history = readr::read_tsv(destfile,
                            col_names = c('tax_id', 
                                          'GeneID',
                                          'Discontinued_GeneID',
                                          'Discontinued_Symbol',
                                          'Discontinue_Date'),skip = 1,
                            col_types = 'icici') %>%
        mutate(Discontinued_GeneID = as.integer(Discontinued_GeneID),
               tax_id = as.integer(tax_id),
               Discontinue_Date= as.integer(Discontinue_Date))
    return(gene_history)
}


#' Update gene IDs
#'
#' Given a list of gene ids and gene history information, traces changes in the 
#' gene's name to get the latest valid ID
#'
#' @param ids Gene ids
#' @param gene_history Gene history information, probably returned by  \code{\link{getGeneHistory}}
#' @param cores If greater than 1, \code{\link[parallel]{mc.lapply}} will be used to parallize
#' the operation. This doesn't work on windows. The older the gene ids are the slower
#' this operation is.
#'
#' @return A character vector. New ids for genes that changed ids, or "-" for discontinued genes.
#' the input itself.
#' @export
#'
#' @examples
#' \dontrun{
#' gene_history = getGeneHistory()
#' updateIDs(c("4340964", "4349034", "4332470", "4334151", "4323831"),gene_history)
#' }
#' 
updateIDs = function(ids, gene_history){
    # we do not filter for taxonomy information as some genes use alternative
    # tax ids in non homologene sources
    # we do filter for earliest date found to run this a little faster
    earlierst_date = gene_history %>%
        dplyr::filter(Discontinued_GeneID %in% as.integer(ids)) %$%
        Discontinue_Date %>% 
        {suppressWarnings(min(.))}
    
    relevant_gene_history = gene_history %>%
        dplyr::filter(Discontinue_Date >= earlierst_date
        )
    
    return(ids %>% sapply(traceID,relevant_gene_history))

}



traceID = function(id,gene_history){
    event = gene_history %>% dplyr::filter(Discontinued_GeneID == as.integer(id))
    if(nrow(event)>1){
        # just in case. if the same ID is discontinued twice, there is a problem...
        return("multiple events")
    } else if(nrow(event) == 0){
        return(id)
    }
    
    while(TRUE){
        if(event$GeneID == '-'){
            # if this condition wasn't there, this function would have worked just fine but 
            # looking for '-'s take much longer than looking for IDs 
            return('-')
        }
        # see if the new ID is discontinued as well
        # the check for the "-"s above allows us to do an integer matching here
        # which is faster
        next_event = gene_history %>%
            dplyr::filter(Discontinued_GeneID == as.integer(event$GeneID))
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



