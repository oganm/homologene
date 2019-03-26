context('homologene testing')

test_that('Multiple orthologues',{
    humanOrthos = human2mouse(c("GZMH"))
    expect_that(humanOrthos$mouseGene,equals(c('Gzmd','Gzme','Gzmg','Gzmf')))
})

test_that('Regular functionality',{
    expect_that(mouse2human(c('Eno2','Mog'))$humanGene,equals(c('ENO2','MOG')))
    expect_that(dim(mouse2human(c('lolwut'))), equals(c(0,4)))
})

test_that('Other species',{
    homoSubsets = homologene::taxData$tax_id %>% sapply(function(x){
        homologene::homologeneData %>% subset(Taxonomy==x) %>% dim
    })
    expect_true(all(homoSubsets[1,]>100))
    
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


test_that('homologene2',{
    mouse2human(c('Mesd',
                  'Trp53rka',
                  'Cstdc4',
                  'Ifit3b'),
                db = homologeneData2) -> 
        genes
    
    expect_true(all(genes$humanGene == c("MESD", "TP53RK", "CSTA", "IFIT3")))
    
    mouse2human(c('Mesd',
                  'Trp53rka',
                  'Cstdc4',
                  'Ifit3b'),
                db = homologeneData) -> 
        genes
    
    expect_true(nrow(genes)==0)
})



test_that('Detached behaviour',{
    detach("package:homologene", unload=TRUE)
    expect_that(homologene::mouse2human(c('Eno2','Mog'))$humanGene,equals(c('ENO2','MOG')))
    expect_that(dim(homologene::human2mouse(c('lolwut'))), equals(c(0,4)))
})


