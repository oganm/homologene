context('utilities testing')


test_that('Updating gene ',{
    
    testIds = c(102978083,102976710,102975981)
    
    gene_history = getGeneHistory('testfiles/gene_history_trimmed.tsv',justRead = TRUE)
    
    # earlierst_date = gene_history %>%
    #     dplyr::filter(Discontinued_GeneID %in% testIds) %$%
    #     Discontinue_Date %>% 
    #     {suppressWarnings(min(.))}
    # 
    # gene_history %<>%
    #     dplyr::filter(Discontinue_Date >= earlierst_date
    #     )
    # 
    # readr::write_tsv(gene_history,'testfiles/gene_history_trimmed.tsv')
    
    updatedGenes = updateIDs(testIds,gene_history)
    
    testthat::expect_is(updatedGenes,'character')
    testthat::expect_length(updatedGenes,3)
    
})


test_that('automatic matching',{
    inGenes = c('Eno2','Mog','Gzme','Gzmg','Gzmf')
    targetGenes = c('ENO2','MOG','GZMH')
    autoTransList = autoTranslate(inGenes,targetGenes,returnAllPossible = TRUE)
    expect_true(is.list(autoTransList))
    expect_warning(autoTranslate(inGenes,targetGenes,returnAllPossible = FALSE),regexp = 'There are other pairings')
    
    autoTrans = autoTranslate(inGenes,targetGenes,
                              possibleOrigins = c('human','mouse'),possibleTargets = c('human','mouse'),
                              returnAllPossible = FALSE)
    
    expect_true(is.data.frame(autoTrans))
    expect_true(all(colnames(autoTrans)[1:2] == c('10090','9606')))
    
    autoTrans2 = autoTranslate(inGenes,targetGenes,
                               possibleOrigins = c('10090','9606'),possibleTargets = c('10090','9606'),
                               returnAllPossible = TRUE)
    
    expect_true(length(autoTrans2) == 1)
    
    expect_identical(autoTrans,autoTrans2[[1]])
    
    selfMatch = suppressWarnings(autoTranslate(inGenes,inGenes,returnAllPossible = FALSE))
    
    expect_true(all(names(selfMatch) == c("10090", "10090", "10090_ID", "10090_ID")))
    
    # check to see if it works for gene IDs too
    expect_true(is.data.frame(autoTranslate(genes = autoTrans$`10090_ID`,targetGenes = autoTrans$`9606_ID`)))
    expect_true(length(autoTranslate(genes = autoTrans$`10090_ID`,targetGenes = autoTrans$`9606_ID`,returnAllPossible = TRUE)) == 1)
    
})

