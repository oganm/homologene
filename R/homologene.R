#' Get homologues of given genes
#' @description Given a list of genes and a taxid, returns a data frame inlcuding the genes and their corresponding homologues
#' @param genes A vector of gene symbols or NCBI ids
#' @param inTax taxid of the species that the input genes are coming from
#' @param outTax taxid of the species that you are seeking homology
#' @param db Homologene database to use. 
#' @export
#' @examples
#' homologene(c('Eno2','17441'), inTax = 10090, outTax = 9606)
homologene = function(genes, inTax, outTax, db = homologene::homologeneData){
    genes <- unique(genes) #remove duplicates
    out = db %>% 
        dplyr::filter(Taxonomy %in% inTax & (Gene.Symbol %in% genes | Gene.ID %in% genes)) %>%
        dplyr::select(HID,Gene.Symbol,Gene.ID)
    names(out)[2] = inTax
    names(out)[3] = paste0(inTax,'_ID')
    
    out2 = db %>%  dplyr::filter(Taxonomy %in% outTax & HID %in% out$HID) %>%
      dplyr::select(HID,Gene.Symbol,Gene.ID)
    names(out2)[2] = outTax
    names(out2)[3] = paste0(outTax,'_ID')
    
    # merge from HID to support translate from self
    output = merge(out,out2,'HID') %>% 
        dplyr::select(2,4,3,5)

    # preserve order with temporary column
    output$sortBy <- factor(output[,1], levels = genes)
    output <- dplyr::arrange(output, sortBy)
    output$sortBy <- NULL
    output %<>% {colnames(.)= gsub('\\.(x|y)','',colnames(.));.}
    
    return(output)
}

#' Mouse/human wraper for homologene
#' @param genes A vector of gene symbols or NCBI ids
#' @param db Homologene database to use. 
#' @export
#' @examples
#' mouse2human(c('Eno2','17441'))
mouse2human = function(genes, db = homologene::homologeneData){
    out = homologene(genes,10090,9606, db)
    names(out) = c('mouseGene', 'humanGene','mouseID','humanID')
    return(out)
}


#' Human/mouse wraper for homologene
#' @param genes A vector of gene symbols or NCBI ids
#' @param db Homologene database to use. 
#' @export
#' @examples
#' human2mouse(c('ENO2','4340'))
human2mouse = function(genes, db = homologene::homologeneData){
    out = homologene(genes,9606,10090, db)
    names(out) = c('humanGene','mouseGene','humanID','mouseID')
    return(out)
}


#' homologeneData
#' 
#' List of gene homologues used by homologene functions
"homologeneData"


#' Version of homologene used
"homologeneVersion"

#' Names and ids of included species
"taxData"