#' Attempt to automatically translate a gene list
#' 
#' @description Given a list of query gene list and a target gene list, the function
#' tries find the homology pairing that matches the query list to the target list. The query list
#' is a short list of genes while the target list is supposed to represent a large number of genes from the target
#' species. The default output will be the largest possible list. If \code{returnAllPossible = TRUE} then
#' all possible pairings with any matches are returned. It is possible to limit the
#' search by setting \code{possibleOrigins} and \code{possibleTargets}. Note that gene symbols of some species
#' are more similar to each other than others. Using this with small gene lists and without providing any
#' \code{possibleOrigins} or \code{possibleTargets} might return multiple hits, or if \code{returnAllPossible = TRUE}
#' a wrong match can be returned.
#' 
#' @param genes A list of genes to match the target. Symbols or NCBI ids
#' @param targetGenes The target list. This list is supposed to represent a large number of genes
#' from the target species.
#' @param possibleOrigins Taxonomic identifiers of possible origin species
#' @param possibleTargets Taxonomic identifiers of possible target species
#' @param returnAllPossible if TRUE returns all possible pairings with non zero gene matches. If FALSE (default) returns the best match
#' @return A data frame if \code{returnAllPossibe = FALSE} and a list of data frames if \code{TRUE}
#' @param db Homologene database to use. 
#' @export
autoTranslate = function(genes,
                         targetGenes,
                         possibleOrigins= NULL,
                         possibleTargets = NULL,
                         returnAllPossible = FALSE,
                         db = homologene::homologeneData){
    pairwise = db$Taxonomy %>%
        unique %>% utils::combn(2)  %>%
        {cbind(.,.[c(2,1),],
               rbind(db$Taxonomy %>%
                         unique,db$Taxonomy %>%
                         unique))}

    if(!is.null(possibleOrigins)){
        possibleOrigins[possibleOrigins == 'human'] = 9606
        possibleOrigins[possibleOrigins == 'mouse'] = 10090
        
        pairwise = pairwise[,pairwise[1,] %in% possibleOrigins, drop = FALSE]
    } else{
        possibleOrigins = db$Taxonomy %>% unique
    }
    if(!is.null(possibleTargets)){
        possibleTargets[possibleTargets == 'human'] = 9606
        possibleTargets[possibleTargets == 'mouse'] = 10090
        pairwise = pairwise[,pairwise[2,] %in% possibleTargets,drop = FALSE]
    } else{
        possibleTargets = db$Taxonomy %>% unique
    }
    
    
    possibleOriginData = db %>%
        dplyr::filter(Taxonomy %in% possibleOrigins & (Gene.Symbol %in% genes | Gene.ID %in% genes)) %>%
        dplyr::group_by(Taxonomy)
    possibleOriginCounts = possibleOriginData %>% dplyr::summarise(n = dplyr::n())
    
    possibleTargetData = db %>%
        dplyr::filter(Taxonomy %in% possibleTargets & (Gene.Symbol %in% targetGenes | Gene.ID %in% targetGenes)) %>%
        dplyr::group_by(Taxonomy)
    possibleTargetCounts = possibleTargetData%>% dplyr::summarise(n = dplyr::n())
    
    
    pairwise = pairwise[,pairwise[1,] %in% possibleOriginCounts$Taxonomy,drop= FALSE]
    pairwise = pairwise[,pairwise[2,] %in% possibleTargetCounts$Taxonomy, drop = FALSE]
    
    
    pairwise %>% apply(2,function(taxes){
        homologene(genes,inTax = taxes[1],outTax = taxes[2])
    }) %>% {.[purrr::map_int(.,nrow)>0]} -> possibleTranslations
    
    possibleTranslations %>% sapply(function(trans){
        sum(c(trans[,2],trans[,4]) %in% targetGenes)
    }) -> translationCounts 
    
    if(!returnAllPossible){
        translationCounts %>% which.max %>% {possibleTranslations[[.]]} -> possibleTranslations
        if(sum(translationCounts>0)>1){
            bestMatch = translationCounts %>% which.max
            nextBest = max(translationCounts[-bestMatch])
            warning('There are other pairings, best of which has ',nextBest, ' matching genes')
        }
    } else{
        possibleTranslations = possibleTranslations[translationCounts!=0]
    }
    return(possibleTranslations)
}
