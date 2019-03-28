#' Download gene symbol information
#' 
#' This function downloads the gene_info file from NCBI website and returns the
#' gene symbols for current IDs.
#'
#' @param destfile Path of the output file. If NULL a temp file will be used
#' @param justRead If TRUE and destfile exists, it reads the file instead of 
#' downloading the latest one from NCBI 
#' @param chunk_size Chunk size to be used with \code{link[readr]{read_tsv_chunked}}.
#' The gene_info file is big enough to make its intake difficult. If you don't
#' have large amounts of free memory you may have to reduce this number to read
#' the file in smaller chunks
#'
#' @return A data frame with gene symbols for each current gene id
#' @export
#'
getGeneInfo = function(destfile = NULL, justRead = FALSE,chunk_size = 1000000){
    if(is.null(destfile)){
        destfile = tempfile()
    }
    if(!(!is.null(destfile) && file.exists(destfile) && justRead)){
        utils::download.file('ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz',
                             paste0(destfile,'.gz'))
        
        R.utils::gunzip(paste0(destfile,'.gz'), overwrite = TRUE)
    }
    
    callBack = function(x,pos){
        x[,c(1,2,3)]
    }
    geneInfo = readr::read_tsv_chunked(destfile,
                                       readr::DataFrameCallback$new(callBack),
                                       col_names = c('tax_id','GeneID','Symbol'),
                                       chunk_size = chunk_size, skip = 1,
                                       col_types = 'iic')
    
}


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
        utils::download.file(url = "ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_history.gz", 
                             destfile = paste0(destfile,'.gz'))
        
        
        R.utils::gunzip(paste0(destfile,'.gz'), overwrite = TRUE)
    }
   
    gene_history = readr::read_tsv(destfile,
                            col_names = c('tax_id', 
                                          'GeneID',
                                          'Discontinued_GeneID',
                                          'Discontinued_Symbol',
                                          'Discontinue_Date'),skip = 1,
                            col_types = 'icici')
    return(gene_history)
}


#' Update gene IDs
#'
#' Given a list of gene ids and gene history information, traces changes in the 
#' gene's name to get the latest valid ID
#'
#' @param ids Gene ids
#' @param gene_history Gene history information, probably returned by  \code{\link{getGeneHistory}}
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
    
    # just speed things along if the input id list includes ids that
    # are not discontinued
    idsToProcess = ids %in% relevant_gene_history$Discontinued_GeneID
    if(sum(idsToProcess)>0){
        ids[idsToProcess] = ids[idsToProcess] %>%  sapply(traceID,relevant_gene_history)
    }
    return(ids)

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



#' Get the latest homologene file
#' 
#' This function downloads the latest homologene file from NCBI. Note that Homologene
#' has not been updated since 2014 so the output will be identical to \code{\link{homologeneData}}
#' included in this package. This function is here for futureproofing purposes.
#'
#' @param destfile Path of the output file. If NULL a temp file will be used
#' @param justRead If TRUE and destfile exists, it reads the file instead of 
#' downloading the latest one from NCBI 
#'
#' @return A data frame with homology groups, gene ids and gene symbols
#' @export
#'
getHomologene = function(destfile = NULL, justRead = FALSE){
    if(is.null(destfile)){
        destfile = tempfile()
    }
    if(!(!is.null(destfile) && file.exists(destfile) && justRead)){
        utils::download.file('ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data',
                             destfile)
    }
    
    homologene = readr::read_tsv('data-raw/homologene.data',
                                 col_names = c('HID','Taxonomy','Gene.ID','Gene.Symbol','Protein.GI','Protein.Accession'),
                                 col_types = 'iiicic')
    
    homologeneData = homologene %>% 
        dplyr::select(HID,Gene.ID,Gene.Symbol,Taxonomy) %>%
        unique %>% 
        dplyr::arrange(HID)
    
    homologeneData %<>% as.data.frame
}
