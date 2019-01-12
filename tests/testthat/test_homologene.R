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
    
})


test_that('Detached behaviour',{
    detach("package:homologene", unload=TRUE)
    expect_that(homologene::mouse2human(c('Eno2','Mog'))$humanGene,equals(c('ENO2','MOG')))
    expect_that(dim(homologene::human2mouse(c('lolwut'))), equals(c(0,4)))
})


