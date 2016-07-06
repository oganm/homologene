#' Get homologues of given genes
#' @description Given a list of genes and a taxid, returns a data frame inlcuding the genes and their corresponding homologues
#' @param genes A list of genes
#' @param inTax taxid of the species that the input genes are coming from
#' @param outTax taxid of the species that you are seeking homology
#' @export
homologene = function(genes, inTax, outTax){
    genes <- unique(genes) #remove duplicates
    out = homologeneData %>% 
        filter(Taxonomy %in% inTax & Gene.Symbol %in% genes) %>%
        dplyr::select(HID,Gene.Symbol)
    names(out)[2] = inTax
    
    out2 = homologeneData %>%  filter(Taxonomy %in% outTax & HID %in% out$HID) %>%
      dplyr::select(HID,Gene.Symbol)
    names(out2)[2] = outTax
    
    output = merge(out,out2) %>% dplyr::select(2:3)

    # preserve order with temporary column
    output$sortBy <- factor(output[,1], levels = genes)
    output <- arrange(output, sortBy)
    output$sortBy <- NULL
    
    return(output)
}

#' Mouse/human wraper for homologene
#' @export
mouse2human = function(genes){
    out = homologene(genes,10090,9606)
    names(out) = c('mouseGene', 'humanGene')
    return(out)
}


#' Human/mouse wraper for homologene
#' @export
human2mouse = function(genes){
    out = homologene(genes,9606,10090)
    names(out) = c('humanGene','mouseGene')
    return(out)
}


